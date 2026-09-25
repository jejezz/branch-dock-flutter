import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../git/commands.dart';
import '../../git/diff.dart';
import '../../git/history.dart';
import '../../l10n/app_localizations.dart';
import '../../repo/repo_controller.dart';
import '../../theme/app_theme.dart';
import '../action_sheet.dart';
import '../diff_view.dart';
import '../help/concepts.dart';
import '../repo_actions.dart';
import '../repo_scope.dart';
import '../widgets.dart';
import 'branches_tab.dart';
import 'tags_tab.dart';

/// 기록 탭 (PLAN.md 3.11): 현재 브랜치의 커밋 목록. 브랜치·태그 표시, 아직
/// 올리지 않은 커밋 강조. 커밋 메뉴에서 여기서 브랜치 만들기·태그 달기.
class HistoryTab extends StatefulWidget {
  const HistoryTab({super.key});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  List<LogEntry>? _entries;
  Set<String> _unpushed = const {};
  String? _loadedFor;
  bool _loading = false;

  /// 볼 브랜치. null이면 현재 브랜치 (다른 브랜치에서 cherry-pick할 커밋 고르기).
  String? _ref;

  Future<void> _load(RepoController repo) async {
    if (_loading) return;
    _loading = true;
    final key = '${repo.status.head}@${repo.status.oid}@$_ref';
    final results = await Future.wait([
      repo.read(GitCommands.history(ref: _ref)),
      if (repo.status.hasUpstream && _ref == null) repo.read(GitCommands.unpushed),
    ]);
    _loading = false;
    if (!mounted) return;
    setState(() {
      _entries = results[0].ok ? LogEntry.parse(results[0].stdout) : const [];
      _unpushed = results.length > 1 && results[1].ok
          ? results[1].stdout.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toSet()
          : const {};
      _loadedFor = key;
    });
  }

  @override
  Widget build(BuildContext context) {
    final repo = RepoScope.of(context);
    final l10n = AppLocalizations.of(context);
    final key = '${repo.status.head}@${repo.status.oid}@$_ref';
    // 커밋·전환·pull로 HEAD가 바뀌거나 볼 브랜치를 바꾸면 다시 읽는다.
    if (key != _loadedFor && !_loading && !repo.status.unborn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _load(repo);
      });
    }
    if (repo.status.unborn) {
      return EmptyState(icon: Icons.history_rounded, title: l10n.branchesUnbornTitle);
    }
    final entries = _entries;
    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      children: [
        SectionHeader(
          title: l10n.historyTitle,
          trailing: Text(
            _unpushed.isEmpty ? '' : l10n.historyUnpushed(_unpushed.length),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(color: toneColor(context, Tone.primary)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
          child: DropdownButtonFormField<String?>(
            initialValue: _ref,
            isExpanded: true,
            decoration: InputDecoration(isDense: true, labelText: l10n.historyBranchLabel),
            items: [
              DropdownMenuItem(value: null, child: Text(l10n.branchBaseCurrent(repo.status.head ?? 'HEAD'))),
              for (final b in repo.branches.where((b) => !b.current))
                DropdownMenuItem(value: b.name, child: Text(b.name, style: AppFonts.userContent)),
            ],
            onChanged: (v) => setState(() {
              _ref = v;
              _entries = null;
            }),
          ),
        ),
        if (_ref != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.md, AppSpacing.sm),
            child: Text(l10n.historyOtherBranchHint(repo.status.head ?? 'HEAD'), style: Theme.of(context).textTheme.bodySmall),
          ),
        if (entries == null)
          const Padding(padding: EdgeInsets.all(AppSpacing.xl), child: Center(child: CircularProgressIndicator()))
        else
          for (final e in entries)
            _CommitRow(entry: e, unpushed: _unpushed.contains(e.hash), repo: repo, otherBranch: _ref != null),
      ],
    );
  }
}

enum _CommitMenu { changes, revert, cherryPick, copy, branch, tag, github }

class _CommitRow extends StatelessWidget {
  const _CommitRow({required this.entry, required this.unpushed, required this.repo, this.otherBranch = false});

  final LogEntry entry;
  final bool unpushed;
  final RepoController repo;

  /// 현재 브랜치가 아닌 브랜치의 기록 — cherry-pick을 보여 주고 revert는 숨긴다.
  final bool otherBranch;

  Future<void> _onMenu(BuildContext context, _CommitMenu m) async {
    final l10n = AppLocalizations.of(context);
    switch (m) {
      case _CommitMenu.changes:
        await showCommitChangesSheet(context, repo, entry);
      case _CommitMenu.revert:
        final command = GitCommands.revert(entry.hash, merge: entry.isMerge);
        final ok = await _confirm(
          context,
          title: l10n.historyRevertTitle(entry.shortHash),
          message: unpushed ? l10n.historyRevertUnpushed : l10n.historyRevertMessage,
          confirm: l10n.historyRevert,
          command: command,
          help: Concept.revert,
        );
        if (ok && context.mounted) {
          await RepoActions.withStashRetry(context, repo, () => repo.execute(command), done: l10n.doneRevert(entry.shortHash));
        }
      case _CommitMenu.cherryPick:
        final command = GitCommands.cherryPick(entry.hash, merge: entry.isMerge);
        final ok = await _confirm(
          context,
          title: l10n.historyCherryPickTitle(entry.shortHash, repo.status.head ?? 'HEAD'),
          message: l10n.historyCherryPickMessage,
          confirm: l10n.historyCherryPick,
          command: command,
          help: Concept.cherryPick,
        );
        if (ok && context.mounted) {
          await RepoActions.withStashRetry(context, repo, () => repo.execute(command),
              done: l10n.doneCherryPick(entry.shortHash));
        }
      case _CommitMenu.copy:
        await Clipboard.setData(ClipboardData(text: entry.hash));
        if (context.mounted) showDone(context, l10n.commonCopied);
      case _CommitMenu.branch:
        await showCreateBranchSheet(context, repo, base: entry.shortHash);
      case _CommitMenu.tag:
        await showCreateTagSheet(context, repo, target: entry.shortHash);
      case _CommitMenu.github:
        final loc = repo.githubRemote?.location;
        if (loc != null) await launchUrl(Uri.parse('${loc.webUrl}/commit/${entry.hash}'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final e = entry;
    final primary = toneColor(context, Tone.primary);
    return Container(
      decoration: BoxDecoration(
        // 아직 올리지 않은 커밋은 왼쪽 줄로 강조한다.
        border: Border(left: BorderSide(color: unpushed ? primary : Colors.transparent, width: 3)),
      ),
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 5, 0, 5),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(e.shortHash,
              style: AppFonts.mono.copyWith(fontSize: 11.5, color: unpushed ? primary : theme.colorScheme.onSurfaceVariant)),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(e.subject, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppFonts.userContent.copyWith(fontSize: 13)),
            if (e.branches.isNotEmpty || e.tags.isNotEmpty || e.isHead) ...[
              const SizedBox(height: 3),
              Wrap(spacing: 4, runSpacing: 4, children: [
                if (e.isHead && e.branches.isEmpty) StatusPill(label: 'HEAD', tone: Tone.warning),
                for (final b in e.branches)
                  StatusPill(label: b, tone: b.contains('/') ? Tone.neutral : Tone.primary, icon: Icons.call_split_rounded),
                for (final t in e.tags) StatusPill(label: t, tone: Tone.success, icon: Icons.sell_outlined),
              ]),
            ],
            const SizedBox(height: 2),
            Text('${e.author} · ${relativeTime(l10n, e.date)}${unpushed ? ' · ${l10n.historyNotPushed}' : ''}',
                style: theme.textTheme.labelSmall),
          ]),
        ),
        PopupMenuButton<_CommitMenu>(
          tooltip: l10n.commonMore,
          icon: const Icon(Icons.more_horiz_rounded, size: 18),
          enabled: !repo.busy,
          onSelected: (m) => _onMenu(context, m),
          itemBuilder: (context) => [
            PopupMenuItem(value: _CommitMenu.changes, child: Text(l10n.historyViewChanges)),
            if (!otherBranch && !repo.status.detached)
              PopupMenuItem(value: _CommitMenu.revert, child: Text(l10n.historyRevert)),
            if (otherBranch && !repo.status.detached)
              PopupMenuItem(value: _CommitMenu.cherryPick, child: Text(l10n.historyCherryPickMenu(repo.status.head ?? ''))),
            const PopupMenuDivider(),
            PopupMenuItem(value: _CommitMenu.copy, child: Text(l10n.historyCopyHash)),
            PopupMenuItem(value: _CommitMenu.branch, child: Text(l10n.historyBranchHere)),
            PopupMenuItem(value: _CommitMenu.tag, child: Text(l10n.historyTagHere)),
            if (repo.githubRemote != null) PopupMenuItem(value: _CommitMenu.github, child: Text(l10n.prOpenOnGitHub)),
          ],
        ),
      ]),
    );
  }
}


/// revert·cherry-pick 확인: 무엇이 일어나는지 + 실행될 명령 + 개념 도움말.
Future<bool> _confirm(
  BuildContext context, {
  required String title,
  required String message,
  required String confirm,
  required List<String> command,
  required Concept help,
}) async {
  final l10n = AppLocalizations.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 360,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Text(message)),
            HelpButton(concept: help),
          ]),
          const SizedBox(height: AppSpacing.md),
          CommandPreview(commands: [command]),
        ]),
      ),
      actions: [
        TextButton(autofocus: true, onPressed: () => Navigator.pop(context, false), child: Text(l10n.commonCancel)),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(confirm)),
      ],
    ),
  );
  return ok ?? false;
}

/// 커밋이 바꾼 파일 목록 → 파일을 누르면 그 파일의 diff (PLAN.md 3.2 P2).
/// 병합 커밋은 첫 부모와 비교한다 (병합으로 들어온 변경).
Future<void> showCommitChangesSheet(BuildContext context, RepoController repo, LogEntry entry) async {
  final parent = entry.parents.firstOrNull;
  final r = await repo.read(GitCommands.commitFiles(entry.hash, parent: parent));
  if (!context.mounted) return;
  final files = r.ok ? ChangedFile.parse(r.stdout) : const <ChangedFile>[];
  await showCommitChangesSheetWith(context, repo, entry, files);
}

Future<void> showCommitChangesSheetWith(BuildContext context, RepoController repo, LogEntry entry, List<ChangedFile> files) {
  final parent = entry.parents.firstOrNull;
  return showActionSheet<void>(context, (context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(entry.subject, style: theme.textTheme.titleMedium?.merge(AppFonts.userContent)),
          Text(
            '${entry.shortHash} · ${entry.author} · ${relativeTime(l10n, entry.date)}'
            '${entry.isMerge ? ' · ${l10n.historyMergeNote}' : ''}',
            style: theme.textTheme.labelSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(l10n.historyFilesChanged(files.length), style: theme.textTheme.labelMedium),
          for (final f in files)
            InkWell(
              onTap: () async {
                final command = GitCommands.commitFileDiff(entry.hash, f.path, parent: parent);
                final d = await repo.read(command);
                if (context.mounted) await showDiffSheet(context, title: f.path, command: command, result: d);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(children: [
                  SizedBox(
                    width: 20,
                    child: Text(f.status,
                        style: AppFonts.mono.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: toneColor(
                            context,
                            switch (f.status) {
                              'A' => Tone.success,
                              'D' => Tone.danger,
                              _ => Tone.primary,
                            },
                          ),
                        )),
                  ),
                  Expanded(
                    child: Text(f.oldPath == null ? f.path : '${f.oldPath} → ${f.path}',
                        style: AppFonts.userContent.copyWith(fontSize: 13)),
                  ),
                  const Icon(Icons.chevron_right_rounded, size: 16),
                ]),
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          CommandPreview(commands: [GitCommands.commitFiles(entry.hash, parent: parent)]),
        ]),
      ),
    );
  });
}
