import 'package:flutter/material.dart';

import '../git/commands.dart';
import '../git/worktrees.dart';
import '../l10n/app_localizations.dart';
import '../repo/repo_controller.dart';
import '../theme/app_theme.dart';
import 'repo_actions.dart';
import 'repo_scope.dart';
import 'widgets.dart';

/// worktree 동작 (PLAN.md 3.4a): 열기 · 브랜치 풀기 · 지우기, 그리고 다른
/// worktree가 쥔 브랜치의 전환·삭제. 지우기는 커밋하지 않은 변경을 지키고,
/// Claude Code가 만든 폴더에는 세션 경고를 붙인다.
abstract final class WorktreeActions {
  /// 그 폴더를 저장소로 연다. 열 수 없는 곳(RepoScope 밖)이면 false.
  static bool open(BuildContext context, Worktree w) {
    final open = RepoScope.openRepoOf(context);
    if (open == null) return false;
    open(w.path);
    return true;
  }

  static bool canOpen(BuildContext context) => RepoScope.openRepoOf(context) != null;

  /// 그 worktree의 브랜치를 푼다 (`git -C <폴더> switch --detach`).
  static Future<bool> detach(BuildContext context, RepoController repo, Worktree w) async {
    final l10n = AppLocalizations.of(context);
    final command = GitCommands.worktreeDetach(w.path);
    final ok = await confirmDanger(
      context,
      title: l10n.worktreeDetachTitle(w.name),
      message: _withClaude(l10n, w, l10n.worktreeDetachMessage(w.path, w.branch ?? '')),
      confirm: l10n.worktreeDetach,
      commands: [command],
    );
    if (!ok || !context.mounted) return false;
    return RepoActions.report(context, repo.execute(command), done: l10n.doneWorktreeDetached(w.name));
  }

  /// 다른 worktree가 쥔 브랜치로 전환하려 할 때: 이유와 함께 "그 폴더 열기" 또는
  /// "풀고 여기로 전환"을 고르게 한다.
  static Future<void> switchToHeld(BuildContext context, RepoController repo, String branch, Worktree w) async {
    final l10n = AppLocalizations.of(context);
    final detach = GitCommands.worktreeDetach(w.path);
    final switchTo = GitCommands.switchTo(branch);
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        // 좁은 창에서 긴 경로와 명령이 넘치지 않게.
        scrollable: true,
        title: Text(l10n.worktreeHeldTitle(branch)),
        content: SizedBox(
          width: 360,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_withClaude(l10n, w, l10n.worktreeHeldMessage(w.path))),
            const SizedBox(height: AppSpacing.md),
            CommandPreview(commands: [detach, switchTo]),
          ]),
        ),
        actions: [
          TextButton(autofocus: true, onPressed: () => Navigator.pop(context), child: Text(l10n.commonCancel)),
          if (canOpen(context))
            TextButton(onPressed: () => Navigator.pop(context, 'open'), child: Text(l10n.openWorktreeFolder)),
          FilledButton(onPressed: () => Navigator.pop(context, 'detach'), child: Text(l10n.worktreeDetachAndSwitch)),
        ],
      ),
    );
    if (!context.mounted) return;
    switch (choice) {
      case 'open':
        open(context, w);
      case 'detach':
        final r = await repo.execute(detach);
        if (!context.mounted) return;
        if (!r.ok) {
          showCommandError(context, r);
          return;
        }
        await RepoActions.withStashRetry(context, repo, () => repo.execute(switchTo), done: l10n.doneSwitch(branch));
    }
  }

  /// worktree를 지운다. 잠겼으면 이유만 알리고, 커밋하지 않은 변경이 있으면
  /// 폴더 이름을 입력해야 `--force`로 지운다.
  static Future<bool> remove(BuildContext context, RepoController repo, Worktree w) async {
    final l10n = AppLocalizations.of(context);
    if (w.locked) {
      await _blocked(context, w, l10n.worktreeLockedMessage(w.path));
      return false;
    }
    final changes = await _changes(repo, w);
    if (!context.mounted) return false;
    final force = changes > 0;
    final command = GitCommands.worktreeRemove(w.path, force: force);
    final ok = force
        ? await confirmTyped(
            context,
            title: l10n.worktreeRemoveForceTitle,
            message: _withClaude(l10n, w, l10n.worktreeRemoveForceMessage(w.path, changes)),
            expected: w.name,
            confirm: l10n.worktreeRemove,
            commands: [command],
          )
        : await confirmDanger(
            context,
            title: l10n.worktreeRemoveTitle(w.name),
            message: _withClaude(l10n, w, l10n.worktreeRemoveMessage(w.path)),
            confirm: l10n.worktreeRemove,
            commands: [command],
          );
    if (!ok || !context.mounted) return false;
    final done = await RepoActions.report(context, repo.execute(command), done: l10n.doneWorktreeRemoved(w.name));
    await repo.loadWorktreeChanges();
    return done;
  }

  /// 다른 worktree가 쥔 브랜치를 지우기 전에 그 worktree부터 지운다. 변경이
  /// 있거나 잠겼으면 지우지 않고 이유를 알린다. 지웠으면 true — 이어서 브랜치를 지운다.
  static Future<bool> removeHolder(BuildContext context, RepoController repo, String branch, Worktree w) async {
    final l10n = AppLocalizations.of(context);
    final changes = await _changes(repo, w);
    if (!context.mounted) return false;
    if (w.locked) {
      await _blocked(context, w, l10n.worktreeLockedMessage(w.path));
      return false;
    }
    if (changes > 0) {
      await _blocked(context, w, l10n.worktreeDeleteBranchDirty(branch, w.path, changes));
      return false;
    }
    final command = GitCommands.worktreeRemove(w.path);
    final ok = await confirmDanger(
      context,
      title: l10n.worktreeDeleteBranchTitle,
      message: _withClaude(l10n, w, l10n.worktreeDeleteBranchMessage(branch, w.path)),
      confirm: l10n.branchesDelete,
      commands: [command, GitCommands.deleteBranch(branch)],
    );
    if (!ok || !context.mounted) return false;
    final r = await repo.execute(command);
    if (!context.mounted) return false;
    if (!r.ok) showCommandError(context, r);
    return r.ok;
  }

  static Future<void> prune(BuildContext context, RepoController repo) {
    final l10n = AppLocalizations.of(context);
    return RepoActions.report(context, repo.execute(GitCommands.worktreePrune), done: l10n.doneWorktreePruned);
  }

  static Future<int> _changes(RepoController repo, Worktree w) async {
    await repo.loadWorktreeChanges();
    return repo.worktreeChanges[w.path] ?? 0;
  }

  /// 지울 수 없는 이유를 알리고, 가능하면 그 폴더를 열어 정리하게 한다.
  static Future<void> _blocked(BuildContext context, Worktree w, String message) async {
    final l10n = AppLocalizations.of(context);
    final openIt = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        // 좁은 창에서 긴 경로와 명령이 넘치지 않게.
        scrollable: true,
        content: SizedBox(width: 360, child: Text(message)),
        actions: [
          TextButton(autofocus: true, onPressed: () => Navigator.pop(context, false), child: Text(l10n.commonCancel)),
          if (canOpen(context) && !w.prunable)
            FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.openWorktreeFolder)),
        ],
      ),
    );
    if (openIt == true && context.mounted) open(context, w);
  }

  static String _withClaude(AppLocalizations l10n, Worktree w, String message) =>
      w.byClaude ? '$message\n\n${l10n.worktreeClaudeWarning}' : message;
}
