import 'package:flutter/material.dart';

import '../core/command_log.dart';
import '../git/commands.dart';
import '../l10n/app_localizations.dart';
import '../repo/next_action.dart';
import '../repo/repo_controller.dart';
import '../theme/app_theme.dart';
import 'action_sheet.dart';
import 'help/concepts.dart';
import 'repo_actions.dart';
import 'repo_scope.dart';
import 'services.dart';
import 'widgets.dart';

/// 상태 헤더 (UI_UX.md §3 B): 브랜치 → 추적 브랜치, 상태 pill, Fetch/Pull/Push.
class StatusHeader extends StatelessWidget {
  const StatusHeader({super.key, required this.onBranchTap});

  /// 브랜치 칩을 누르면 브랜치 탭으로.
  final VoidCallback onBranchTap;

  @override
  Widget build(BuildContext context) {
    final repo = RepoScope.of(context);
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final s = repo.status;

    final branchLabel = s.detached ? l10n.headerDetached : (s.head ?? '');
    final pills = <Widget>[
      if (repo.operation != RepoOperation.none)
        StatusPill(
          tone: Tone.danger,
          icon: Icons.warning_amber_rounded,
          label: repo.operation == RepoOperation.merging
              ? l10n.headerMerging(s.conflicts.length)
              : l10n.headerRebasing(s.conflicts.length),
        ),
      if (s.ahead > 0)
        StatusPill(tone: Tone.primary, label: '↑${s.ahead}', tooltip: l10n.headerAheadTooltip(s.ahead)),
      if (s.behind > 0)
        StatusPill(tone: Tone.warning, label: '↓${s.behind}', tooltip: l10n.headerBehindTooltip(s.behind)),
      if (!s.clean)
        StatusPill(label: l10n.headerChanges(s.changedCount), icon: Icons.circle, tone: Tone.neutral)
      else if (s.ahead == 0 && s.behind == 0 && s.hasUpstream)
        StatusPill(tone: Tone.success, icon: Icons.check_rounded, label: l10n.headerUpToDate),
      if (s.unborn) StatusPill(label: l10n.headerNoCommits),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Flexible(
            child: ActionChip(
              avatar: Icon(s.detached ? Icons.sell_outlined : Icons.call_split_rounded, size: 16),
              label: Text(branchLabel, overflow: TextOverflow.ellipsis, style: AppFonts.userContent),
              tooltip: l10n.headerBranchTooltip,
              onPressed: onBranchTap,
              shape: const StadiumBorder(),
            ),
          ),
          const SizedBox(width: 6),
          Icon(Icons.arrow_forward_rounded, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          if (s.hasUpstream)
            Flexible(
              child: Text(s.upstream!,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.merge(AppFonts.userContent)),
            )
          else
            StatusPill(label: l10n.headerNoUpstream, tooltip: l10n.headerNoUpstreamTooltip),
          const HelpButton(concept: Concept.upstream),
        ]),
        if (pills.isNotEmpty) ...[
          const SizedBox(height: 6),
          Wrap(spacing: 6, runSpacing: 6, children: pills),
        ],
        const SizedBox(height: AppSpacing.sm),
        if (repo.operation != RepoOperation.none) const _OperationButtons() else const _SyncButtons(),
      ]),
    );
  }
}

class _SyncButtons extends StatelessWidget {
  const _SyncButtons();

  @override
  Widget build(BuildContext context) {
    final repo = RepoScope.of(context);
    final l10n = AppLocalizations.of(context);
    final prefs = ServicesScope.of(context).prefs;
    final s = repo.status;
    final hasRemote = repo.remotes.isNotEmpty;
    final idle = !repo.busy;

    final canPull = idle && s.hasUpstream && !s.detached;
    final publish = repo.needsPublish && !s.unborn;
    final canPush = idle && hasRemote && !s.detached && !s.unborn && (publish || s.ahead > 0);
    final pullStyle = s.behind > 0;
    final mode = prefs.pullMode(repo.root);

    Widget tip(String command, Widget child) => Tooltip(message: command, child: child);

    return Row(children: [
      Expanded(
        child: tip(
          formatCommandLine(GitCommands.fetch()),
          OutlinedButton.icon(
            onPressed: idle && hasRemote ? () => RepoActions.fetch(context, repo) : null,
            icon: const Icon(Icons.sync_rounded, size: 16),
            label: Text(l10n.headerFetch),
          ),
        ),
      ),
      const SizedBox(width: AppSpacing.sm),
      Expanded(
        child: tip(
          formatCommandLine(GitCommands.pull(mode)),
          Row(children: [
            Expanded(
              child: pullStyle
                  ? FilledButton.icon(
                      onPressed: canPull ? () => RepoActions.pull(context, repo) : null,
                      icon: const Icon(Icons.south_rounded, size: 16),
                      label: Text(s.behind > 0 ? '${l10n.headerPull} ↓${s.behind}' : l10n.headerPull),
                    )
                  : OutlinedButton.icon(
                      onPressed: canPull ? () => RepoActions.pull(context, repo) : null,
                      icon: const Icon(Icons.south_rounded, size: 16),
                      label: Text(l10n.headerPull),
                    ),
            ),
            SizedBox(
              width: 24,
              child: IconButton(
                padding: EdgeInsets.zero,
                tooltip: l10n.pullModeTooltip,
                iconSize: 18,
                icon: const Icon(Icons.arrow_drop_down_rounded),
                onPressed: () => showPullModeSheet(context, repo),
              ),
            ),
          ]),
        ),
      ),
      const SizedBox(width: AppSpacing.sm),
      Expanded(
        child: tip(
          formatCommandLine(repo.pushCommand),
          FilledButton.icon(
            onPressed: canPush ? () => RepoActions.push(context, repo) : null,
            icon: Icon(publish ? Icons.cloud_upload_rounded : Icons.north_rounded, size: 16),
            label: Text(
              publish ? l10n.headerPublish : (s.ahead > 0 ? '${l10n.headerPush} ↑${s.ahead}' : l10n.headerPush),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    ]);
  }
}

class _OperationButtons extends StatelessWidget {
  const _OperationButtons();

  @override
  Widget build(BuildContext context) {
    final repo = RepoScope.of(context);
    final l10n = AppLocalizations.of(context);
    final conflicts = repo.status.conflicts.length;
    final rebasing = repo.operation == RepoOperation.rebasing;
    return Row(children: [
      Expanded(
        child: OutlinedButton(
          onPressed: repo.busy
              ? null
              : () async {
                  final ok = await confirmDanger(
                    context,
                    title: l10n.operationAbortTitle,
                    message: rebasing ? l10n.operationAbortRebaseMessage : l10n.operationAbortMergeMessage,
                    confirm: l10n.operationAbort,
                    commands: [rebasing ? GitCommands.rebaseAbort : GitCommands.mergeAbort],
                  );
                  if (ok && context.mounted) {
                    await RepoActions.report(context, repo.abortOperation(), done: l10n.doneAbort);
                  }
                },
          child: Text(l10n.operationAbort),
        ),
      ),
      const SizedBox(width: AppSpacing.sm),
      Expanded(
        child: Tooltip(
          message: conflicts > 0 ? l10n.operationContinueBlocked : '',
          child: FilledButton(
            onPressed: repo.busy || conflicts > 0
                ? null
                : () => RepoActions.report(context, repo.continueOperation(), done: l10n.doneContinue),
            child: Text(l10n.operationContinue),
          ),
        ),
      ),
    ]);
  }
}

/// Pull 방식 비교 (UI_UX.md §6.1 비교 화면의 축소판). 고르면 저장소별로 기억한다.
Future<void> showPullModeSheet(BuildContext context, RepoController repo) {
  final prefs = ServicesScope.of(context).prefs;
  return showActionSheet<void>(context, (context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final current = prefs.pullMode(repo.root);
    Widget tile(PullMode mode, String title, String when, Concept concept) => ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          leading: Icon(mode == current ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: mode == current ? theme.colorScheme.primary : null),
          title: Text(title),
          subtitle: Text(when),
          trailing: HelpButton(concept: concept),
          onTap: () async {
            await prefs.setPullMode(repo.root, mode);
            repo.refresh();
            if (context.mounted) Navigator.pop(context);
          },
        );
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Row(children: [
              Text(l10n.pullModeTitle, style: theme.textTheme.titleLarge),
              const HelpButton(concept: Concept.fetchVsPull),
            ]),
          ),
          const SizedBox(height: AppSpacing.sm),
          tile(PullMode.merge, l10n.pullModeMerge, l10n.pullModeMergeWhen, Concept.mergeCommit),
          tile(PullMode.rebase, l10n.pullModeRebase, l10n.pullModeRebaseWhen, Concept.rebase),
          tile(PullMode.fastForwardOnly, l10n.pullModeFastForward, l10n.pullModeFastForwardWhen, Concept.fastForward),
        ]),
      ),
    );
  });
}

/// 추천 행동 배너 (UI_UX.md §3 C). 닫으면 상태가 바뀔 때까지 숨긴다.
class NextActionBanner extends StatelessWidget {
  const NextActionBanner({
    super.key,
    required this.action,
    required this.onDismiss,
    required this.onShowChanges,
    required this.onShowRemotes,
  });

  final NextAction action;
  final VoidCallback onDismiss;
  final VoidCallback onShowChanges;
  final VoidCallback onShowRemotes;

  @override
  Widget build(BuildContext context) {
    final repo = RepoScope.of(context);
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final (String text, String button, VoidCallback onPressed) = switch (action.kind) {
      NextActionKind.resolveConflicts => (l10n.bannerConflicts(action.count), l10n.bannerShow, onShowChanges),
      NextActionKind.pull => (l10n.bannerPull(action.count), l10n.headerPull, () => RepoActions.pull(context, repo)),
      NextActionKind.publish => (l10n.bannerPublish, l10n.headerPublish, () => RepoActions.push(context, repo)),
      NextActionKind.push => (l10n.bannerPush(action.count), l10n.headerPush, () => RepoActions.push(context, repo)),
      NextActionKind.publishToGitHub => (l10n.bannerNoRemote, l10n.bannerShow, onShowRemotes),
    };
    return Container(
      margin: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 6, 4, 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Icon(Icons.lightbulb_outline_rounded, size: 16, color: theme.colorScheme.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        TextButton(onPressed: repo.busy ? null : onPressed, child: Text(button)),
        IconButton(
          tooltip: l10n.commonClose,
          visualDensity: VisualDensity.compact,
          iconSize: 16,
          icon: const Icon(Icons.close_rounded),
          onPressed: onDismiss,
        ),
      ]),
    );
  }
}
