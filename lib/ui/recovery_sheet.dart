import 'package:flutter/material.dart';

import '../git/commands.dart';
import '../git/reflog.dart';
import '../l10n/app_localizations.dart';
import '../repo/repo_controller.dart';
import '../theme/app_theme.dart';
import 'action_sheet.dart';
import 'help/concepts.dart';
import 'repo_actions.dart';
import 'tabs/changes_tab.dart' show showStashSheet;
import 'widgets.dart';

/// 실수 복구 (PLAN.md 3.15): "마지막 커밋 취소", "변경 잠시 치우기", 그리고 HEAD가 지나온 자리(reflog)로
/// 돌아가기·거기서 새 브랜치 만들기를 한 곳에 모은다. 고르는 순간 실행될 `git` 명령을 보여 준다.
///
/// 시트를 닫은 뒤에도 결과 안내와 재시도를 보여 줘야 해서, 부른 쪽의 [context]를 계속 쓴다.
Future<void> showRecoverySheet(BuildContext context, RepoController repo) async {
  final results = await Future.wait([
    repo.read(GitCommands.reflog()),
    repo.read(GitCommands.hasParent),
    repo.read(GitCommands.headSubject),
  ]);
  if (!context.mounted) return;
  final data = _RecoveryData(
    entries: results[0].ok ? ReflogEntry.parse(results[0].stdout) : const [],
    hasParent: results[1].ok,
    headSubject: results[2].ok ? results[2].stdout.trim() : '',
  );
  await showActionSheet<void>(context, (_) => _RecoverySheet(repo: repo, host: context, data: data));
}

class _RecoveryData {
  const _RecoveryData({required this.entries, required this.hasParent, required this.headSubject});

  final List<ReflogEntry> entries;
  final bool hasParent;
  final String headSubject;
}

class _RecoverySheet extends StatelessWidget {
  const _RecoverySheet({required this.repo, required this.host, required this.data});

  final RepoController repo;

  /// 시트를 연 화면. 시트가 닫힌 뒤의 안내·확인 창은 여기에 띄운다.
  final BuildContext host;
  final _RecoveryData data;

  /// 추적 브랜치가 있고 앞선 커밋이 없으면 HEAD 커밋은 이미 원격에 있다.
  bool get _pushed => repo.status.hasUpstream && repo.status.ahead == 0;

  Future<void> _undoCommit(BuildContext sheet) async {
    final l10n = AppLocalizations.of(host);
    final subject = data.headSubject.isEmpty ? 'HEAD' : data.headSubject;
    Navigator.pop(sheet);
    final ok = await confirmDanger(
      host,
      title: l10n.recoveryUndoCommit,
      message: _pushed ? l10n.recoveryUndoCommitPushed : l10n.recoveryUndoCommitMessage(subject),
      confirm: l10n.recoveryUndoCommitConfirm,
      commands: const [GitCommands.undoLastCommit],
    );
    if (!ok || !host.mounted) return;
    await RepoActions.report(host, repo.execute(GitCommands.undoLastCommit), done: l10n.doneUndoCommit);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final canUndo = data.hasParent && !repo.status.unborn && repo.operation == RepoOperation.none;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.lg),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(child: Text(l10n.recoveryTitle, style: theme.textTheme.titleLarge)),
            const HelpButton(concept: Concept.reflog),
          ]),
          const SizedBox(height: AppSpacing.sm),
          Text(l10n.recoveryIntro, style: theme.textTheme.bodySmall),
          const SizedBox(height: AppSpacing.md),
          _ActionTile(
            icon: Icons.undo_rounded,
            title: l10n.recoveryUndoCommit,
            subtitle: canUndo
                ? (data.headSubject.isEmpty ? '' : l10n.recoveryUndoCommitWhy(data.headSubject))
                : l10n.recoveryNoParent,
            help: Concept.reset,
            onTap: canUndo ? () => _undoCommit(context) : null,
          ),
          _ActionTile(
            icon: Icons.inventory_2_outlined,
            title: l10n.recoveryStash,
            subtitle: l10n.recoveryStashWhy,
            help: Concept.stash,
            onTap: repo.status.clean
                ? null
                : () {
                    Navigator.pop(context);
                    showStashSheet(host, repo);
                  },
          ),
          const Divider(height: AppSpacing.xl),
          Text(l10n.recoveryHistory, style: theme.textTheme.titleMedium),
          const SizedBox(height: 2),
          Text(l10n.recoveryHistoryHint, style: theme.textTheme.bodySmall),
          const SizedBox(height: AppSpacing.sm),
          if (data.entries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Text(l10n.recoveryEmpty, style: theme.textTheme.bodySmall),
            )
          else
            for (final (i, e) in data.entries.indexed)
              _ReflogRow(
                entry: e,
                isNow: i == 0,
                repo: repo,
                host: host,
                sheet: context,
              ),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.commonClose)),
          ),
        ]),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.icon, required this.title, required this.subtitle, required this.onTap, this.help});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Concept? help;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      enabled: onTap != null,
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle.isEmpty ? null : Text(subtitle),
      trailing: help == null ? null : HelpButton(concept: help!),
      onTap: onTap,
    );
  }
}

enum _RowAction { goBack, rescue }

class _ReflogRow extends StatelessWidget {
  const _ReflogRow({
    required this.entry,
    required this.isNow,
    required this.repo,
    required this.host,
    required this.sheet,
  });

  final ReflogEntry entry;
  final bool isNow;
  final RepoController repo;
  final BuildContext host;
  final BuildContext sheet;

  String _kindLabel(AppLocalizations l10n) => switch (entry.kind) {
        ReflogKind.commit => l10n.recoveryKindCommit,
        ReflogKind.amend => l10n.recoveryKindAmend,
        ReflogKind.checkout => l10n.recoveryKindCheckout,
        ReflogKind.reset => l10n.recoveryKindReset,
        ReflogKind.merge => l10n.recoveryKindMerge,
        ReflogKind.pull => l10n.recoveryKindPull,
        ReflogKind.rebase => l10n.recoveryKindRebase,
        ReflogKind.cherryPick => l10n.recoveryKindCherryPick,
        ReflogKind.revert => l10n.recoveryKindRevert,
        ReflogKind.other => l10n.recoveryKindOther,
      };

  Future<void> _run(_RowAction action) async {
    final l10n = AppLocalizations.of(host);
    Navigator.pop(sheet);
    switch (action) {
      case _RowAction.goBack:
        final command = GitCommands.resetKeep(entry.hash);
        final ok = await confirmDanger(
          host,
          title: l10n.recoveryGoBack,
          message: l10n.recoveryGoBackMessage(repo.status.head ?? 'HEAD', entry.shortHash),
          confirm: l10n.recoveryGoBackConfirm,
          commands: [command],
        );
        if (!ok || !host.mounted) return;
        await RepoActions.withStashRetry(host, repo, () => repo.execute(command), done: l10n.doneGoBack(entry.shortHash));
      case _RowAction.rescue:
        final name = 'rescue/${entry.shortHash}';
        await RepoActions.report(host, repo.execute(GitCommands.rescueBranch(name, entry.hash)), done: l10n.doneRescue(name));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    // 지금 HEAD와 같은 자리로는 되돌릴 필요가 없다.
    final atHead = entry.hash == repo.status.oid;
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Container(
        constraints: const BoxConstraints(minWidth: 52),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: toneColor(context, isNow ? Tone.primary : Tone.neutral).withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(AppRadius.iconChip),
        ),
        child: Text(
          isNow ? l10n.recoveryNow : _kindLabel(l10n),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall,
        ),
      ),
      title: Text(
        entry.detail.isEmpty ? entry.message : entry.detail,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: AppFonts.userContent.copyWith(fontSize: 13),
      ),
      subtitle: Text('${entry.shortHash} · ${_kindLabel(l10n)} · ${relativeTime(l10n, entry.date)}'),
      trailing: PopupMenuButton<_RowAction>(
        tooltip: l10n.commonMore,
        icon: const Icon(Icons.more_horiz_rounded, size: 18),
        onSelected: _run,
        itemBuilder: (_) => [
          if (!atHead) PopupMenuItem(value: _RowAction.goBack, child: Text(l10n.recoveryGoBack)),
          PopupMenuItem(value: _RowAction.rescue, child: Text(l10n.recoveryRescue)),
        ],
      ),
    );
  }
}
