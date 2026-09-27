import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/command_runner.dart';
import '../core/vscode.dart';
import '../git/commands.dart';
import '../git/error_hints.dart';
import '../git/status.dart';
import '../l10n/app_localizations.dart';
import '../repo/repo_controller.dart';
import 'repo_scope.dart';
import 'services.dart';
import 'widgets.dart';

/// 화면 여러 곳에서 쓰는 동작: 실행 → 완료/오류 알림. 오류에는 해결 버튼을
/// 붙일 수 있으면 붙인다 (UI_UX.md §3 F).
abstract final class RepoActions {
  static Future<bool> report(
    BuildContext context,
    Future<CommandResult> run, {
    required String done,
    String? fixLabel,
    VoidCallback? onFix,
  }) async {
    final result = await run;
    if (!context.mounted) return result.ok;
    if (result.ok) {
      showDone(context, done);
    } else {
      showCommandError(context, result, action: fixLabel, onAction: onFix);
    }
    return result.ok;
  }

  static Future<void> fetch(BuildContext context, RepoController repo) {
    final l10n = AppLocalizations.of(context);
    return report(context, repo.fetch(), done: l10n.doneFetch);
  }

  static Future<void> pull(BuildContext context, RepoController repo) async {
    final l10n = AppLocalizations.of(context);
    final mode = ServicesScope.of(context).prefs.pullMode(repo.root);
    await withStashRetry(context, repo, () => repo.pull(mode), done: l10n.donePull);
  }

  /// 커밋하지 않은 변경 때문에 막히면 "임시 저장하고 다시"를 제안한다
  /// (PLAN.md 3.2 P1: 브랜치 전환이나 pull이 변경 때문에 막힐 때).
  /// 브랜치가 다른 worktree에 체크아웃되어 막히면 그 폴더를 열어 준다.
  /// [openRepo]를 주지 않으면 [RepoScope]에서 찾는다.
  static Future<bool> withStashRetry(
    BuildContext context,
    RepoController repo,
    Future<CommandResult> Function() run, {
    required String done,
    ValueChanged<String>? openRepo,
  }) async {
    final l10n = AppLocalizations.of(context);
    final result = await run();
    if (!context.mounted) return result.ok;
    if (result.ok) {
      showDone(context, done);
      return true;
    }
    final hint = classifyError(result.combined, exitCode: result.exitCode);
    if (hint == GitErrorKind.branchInOtherWorktree) {
      final path = worktreePathFromError(result.combined);
      final open = openRepo ?? RepoScope.openRepoOf(context);
      showCommandError(
        context,
        result,
        action: path != null && open != null ? l10n.openWorktreeFolder : null,
        onAction: path != null && open != null ? () => open(path) : null,
      );
      return false;
    }
    final blocked = hint == GitErrorKind.localChangesWouldBeOverwritten;
    showCommandError(
      context,
      result,
      action: blocked ? l10n.stashAndRetry : null,
      onAction: blocked
          ? () async {
              final stash = await repo.execute(GitCommands.stashPush(l10n.stashAutoMessage));
              if (!context.mounted) return;
              if (!stash.ok) {
                showCommandError(context, stash);
                return;
              }
              final again = await run();
              if (!context.mounted) return;
              if (again.ok) {
                showDone(context, l10n.doneStashAndRetry);
              } else {
                showCommandError(context, again);
              }
            }
          : null,
    );
    return false;
  }

  static Future<void> push(BuildContext context, RepoController repo) async {
    final l10n = AppLocalizations.of(context);
    final publishing = repo.needsPublish;
    final result = await repo.push(followTags: ServicesScope.of(context).prefs.followTags(repo.root));
    if (!context.mounted) return;
    if (result.ok) {
      showDone(context, publishing ? l10n.donePublish(repo.status.head ?? '') : l10n.donePush);
      return;
    }
    // 원격이 앞서 있으면 먼저 Pull 하도록 버튼을 붙인다.
    final hint = classifyError(result.combined, exitCode: result.exitCode);
    showCommandError(
      context,
      result,
      action: hint == GitErrorKind.pushRejected ? l10n.headerPull : null,
      onAction: hint == GitErrorKind.pushRejected ? () => pull(context, repo) : null,
    );
  }

  /// 파일을 편집기로 연다. 설정한 편집기 명령이 있으면 그것을, 없으면 OS 기본 앱.
  static Future<void> openInEditor(BuildContext context, RepoController repo, FileChange file) async {
    final services = ServicesScope.of(context);
    final path = '${repo.root}${Platform.pathSeparator}${file.path.replaceAll('/', Platform.pathSeparator)}';
    final editor = services.prefs.editorCommand;
    if (editor.isNotEmpty) {
      final parts = editor.split(RegExp(r'\s+'));
      final result = await services.runner.run([...parts, path], workingDirectory: repo.root);
      if (!result.ok && context.mounted) showCommandError(context, result);
      return;
    }
    await launchUrl(Uri.file(path));
  }

  /// 저장소 폴더(worktree면 그 폴더)를 여는 명령. 설정한 편집기 명령이 있으면
  /// 그것을, 없으면 VS Code. VS Code도 없으면 null.
  static Future<List<String>?> folderEditorCommand(AppServices services, String root) async {
    final editor = services.prefs.editorCommand;
    if (editor.isNotEmpty) return [...editor.split(RegExp(r'\s+')), root];
    return vscodeOpenCommand(root, path: services.runner.effectivePath);
  }

  /// 저장소 폴더를 편집기로 연다. 편집기를 찾지 못하면 설치 링크를 보여 준다.
  static Future<void> openFolderInEditor(BuildContext context, RepoController repo) async {
    final services = ServicesScope.of(context);
    final command = await folderEditorCommand(services, repo.root);
    if (!context.mounted) return;
    if (command == null) {
      await _showVscodeMissing(context);
      return;
    }
    final result = await services.runner.run(command, workingDirectory: repo.root);
    if (!result.ok && context.mounted) showCommandError(context, result);
  }

  static Future<void> _showVscodeMissing(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: Text(l10n.vscodeMissingTitle),
        content: SizedBox(width: 360, child: Text(l10n.vscodeMissingMessage)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.commonClose)),
          FilledButton.icon(
            autofocus: true,
            icon: const Icon(Icons.open_in_new_rounded, size: 16),
            label: Text(l10n.vscodeDownload),
            onPressed: () {
              Navigator.pop(context);
              launchUrl(vscodeDownloadUrl);
            },
          ),
        ],
      ),
    );
  }
}
