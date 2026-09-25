import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/command_runner.dart';
import '../../git/commands.dart';
import '../../git/commits.dart';
import '../../github/models.dart';
import '../../l10n/app_localizations.dart';
import '../../repo/repo_controller.dart';
import '../../theme/app_theme.dart';
import '../action_sheet.dart';
import '../help/concepts.dart';
import '../repo_actions.dart';
import '../repo_scope.dart';
import '../widgets.dart';
import 'remotes_tab.dart';

/// PR 탭 (UI_UX.md §4.6): 현재 브랜치의 PR 카드, 없으면 PR 만들기.
class PrTab extends StatefulWidget {
  const PrTab({super.key});

  @override
  State<PrTab> createState() => _PrTabState();
}

class _PrTabState extends State<PrTab> {
  PullRequest? _pr;
  String? _loadedFor;
  bool _loading = false;

  Future<void> _load(RepoController repo) async {
    final head = repo.status.head;
    if (head == null) return;
    setState(() => _loading = true);
    final r = await repo.read(GhCommands.prView(head, PullRequest.jsonFields));
    if (!mounted) return;
    setState(() {
      _pr = r.ok ? PullRequest.parse(r.stdout) : null;
      _loadedFor = head;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final repo = RepoScope.of(context);
    final env = RepoScope.environmentOf(context);
    final l10n = AppLocalizations.of(context);
    final head = repo.status.head;

    if (repo.githubRemote == null || !env.ghReady) {
      return EmptyState(
        icon: Icons.link_off_rounded,
        title: repo.githubRemote == null ? l10n.prNotGitHubTitle : l10n.prGhRequiredTitle,
        message: repo.githubRemote == null ? l10n.prNotGitHubMessage : ghUnavailableText(l10n, env),
      );
    }
    if (head != _loadedFor && !_loading) WidgetsBinding.instance.addPostFrameCallback((_) => _load(repo));

    final onDefault = head == repo.defaultBranch;
    final pr = _pr;
    return RefreshIndicator(
      onRefresh: () => _load(repo),
      child: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        children: [
          SectionHeader(
            title: l10n.prTitle,
            trailing: IconButton(
              tooltip: l10n.appBarRefresh,
              iconSize: 18,
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _loading ? null : () => _load(repo),
            ),
          ),
          if (_loading && pr == null)
            const Padding(padding: EdgeInsets.all(AppSpacing.xl), child: Center(child: CircularProgressIndicator()))
          else if (head == null)
            EmptyState(icon: Icons.merge_rounded, title: l10n.prDetached)
          else if (pr != null && pr.headRef == head && (pr.open || pr.merged))
            PrCard(
              pr: pr,
              repo: repo,
              onChanged: () => _load(repo),
            )
          else if (onDefault)
            EmptyState(icon: Icons.merge_rounded, title: l10n.prOnDefaultTitle, message: l10n.prOnDefaultMessage)
          else
            EmptyState(
              icon: Icons.merge_rounded,
              title: l10n.prNoneTitle(head),
              message: l10n.prNoneMessage(repo.defaultBranch ?? 'main'),
              action: FilledButton.icon(
                onPressed: repo.busy ? null : () => showCreatePrSheet(context, repo, onCreated: () => _load(repo)),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: Text(l10n.prCreate),
              ),
            ),
        ],
      ),
    );
  }
}

/// PR 한 개의 상태와 병합 (릴리스 마법사 ④와 같은 카드, UI_UX.md §4.6).
class PrCard extends StatefulWidget {
  const PrCard({super.key, required this.pr, required this.repo, required this.onChanged, this.showMerge = true});

  final PullRequest pr;
  final RepoController repo;
  final VoidCallback onChanged;
  final bool showMerge;

  @override
  State<PrCard> createState() => _PrCardState();
}

class _PrCardState extends State<PrCard> {
  PrMergeMethod _method = PrMergeMethod.merge;
  bool _deleteBranch = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final pr = widget.pr;
    final c = pr.checks;
    final repo = widget.repo;

    final (String stateLabel, Tone stateTone) = switch (pr.state) {
      PrState.merged => (l10n.prStateMerged, Tone.primary),
      PrState.closed => (l10n.prStateClosed, Tone.neutral),
      PrState.open => pr.draft ? (l10n.prStateDraft, Tone.neutral) : (l10n.prStateOpen, Tone.success),
    };

    final blocker = !pr.open
        ? null
        : pr.draft
            ? l10n.prBlockedDraft
            : pr.conflicting
                ? l10n.prBlockedConflict
                : c.failed > 0
                    ? l10n.prBlockedChecks(c.failedNames.join(', '))
                    : c.pending > 0
                        ? l10n.prBlockedPending(c.pending)
                        : pr.reviewRequired
                            ? l10n.prBlockedReview
                            : null;

    final mergeCommands = [
      GhCommands.prMerge(pr.number, _method, deleteBranch: _deleteBranch),
      GitCommands.switchTo(pr.baseRef),
      GitCommands.pullFastForward,
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.tile),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          StatusPill(label: stateLabel, tone: stateTone),
          const SizedBox(width: AppSpacing.sm),
          Text('#${pr.number}', style: theme.textTheme.labelMedium),
          const Spacer(),
          TextButton.icon(
            onPressed: () => launchUrl(Uri.parse(pr.url)),
            icon: const Icon(Icons.open_in_new_rounded, size: 14),
            label: Text(l10n.prOpenOnGitHub),
          ),
        ]),
        const SizedBox(height: 4),
        Text(pr.title, style: theme.textTheme.titleSmall?.merge(AppFonts.userContent)),
        const SizedBox(height: 2),
        Text('${pr.headRef} → ${pr.baseRef}',
            style: theme.textTheme.bodySmall?.merge(AppFonts.mono).copyWith(fontSize: 11.5)),
        const SizedBox(height: AppSpacing.sm),
        Wrap(spacing: 6, runSpacing: 6, children: [
          if (c.total == 0)
            StatusPill(label: l10n.prNoChecks)
          else ...[
            if (c.passed > 0) StatusPill(label: l10n.prChecksPassed(c.passed), tone: Tone.success, icon: Icons.check_rounded),
            if (c.failed > 0) StatusPill(label: l10n.prChecksFailed(c.failed), tone: Tone.danger, icon: Icons.close_rounded),
            if (c.pending > 0) StatusPill(label: l10n.prChecksPending(c.pending), tone: Tone.warning, icon: Icons.schedule_rounded),
          ],
          if (pr.reviewDecision == 'APPROVED') StatusPill(label: l10n.prApproved, tone: Tone.success),
          if (pr.reviewRequired) StatusPill(label: l10n.prReviewRequired, tone: Tone.warning),
        ]),
        if (pr.open && widget.showMerge) ...[
          const SizedBox(height: AppSpacing.md),
          if (blocker != null)
            Text(blocker, style: theme.textTheme.bodySmall?.copyWith(color: toneColor(context, Tone.warning))),
          Row(children: [
            Expanded(
              child: DropdownButton<PrMergeMethod>(
                value: _method,
                isExpanded: true,
                underline: const SizedBox.shrink(),
                items: [
                  DropdownMenuItem(value: PrMergeMethod.merge, child: Text(l10n.prMethodMerge)),
                  DropdownMenuItem(value: PrMergeMethod.squash, child: Text(l10n.prMethodSquash)),
                  DropdownMenuItem(value: PrMergeMethod.rebase, child: Text(l10n.prMethodRebase)),
                ],
                onChanged: (v) => setState(() => _method = v ?? PrMergeMethod.merge),
              ),
            ),
            HelpButton(
                concept: switch (_method) {
              PrMergeMethod.merge => Concept.mergeCommit,
              PrMergeMethod.squash => Concept.squash,
              PrMergeMethod.rebase => Concept.rebase,
            }),
          ]),
          CheckboxListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _deleteBranch,
            onChanged: (v) => setState(() => _deleteBranch = v ?? true),
            title: Text(l10n.prDeleteBranch),
          ),
          CommandPreview(commands: mergeCommands),
          const SizedBox(height: AppSpacing.sm),
          FilledButton.icon(
            onPressed: repo.busy || pr.draft || pr.conflicting
                ? null
                : () async {
                    final ok = await RepoActions.report(
                      context,
                      repo.executeAll(mergeCommands),
                      done: l10n.donePrMerged(pr.number),
                    );
                    if (ok) widget.onChanged();
                  },
            icon: const Icon(Icons.merge_rounded, size: 16),
            label: Text(l10n.prMerge),
          ),
        ],
      ]),
    );
  }
}

/// PR 만들기 (PLAN.md 3.9): 기준 브랜치, 제목(마지막 커밋), 본문, 초안.
Future<void> showCreatePrSheet(BuildContext context, RepoController repo, {VoidCallback? onCreated}) async {
  final base = repo.defaultBranch ?? 'main';
  final head = repo.status.head!;
  final log = await repo.read(GitCommands.incoming(head, base: '${repo.defaultRemote ?? 'origin'}/$base'));
  if (!context.mounted) return;
  final commits = log.ok ? Commit.parse(log.stdout) : const <Commit>[];
  await showActionSheet<void>(
    context,
    (context) => _CreatePrSheet(repo: repo, base: base, head: head, commits: commits, onCreated: onCreated),
  );
}

class _CreatePrSheet extends StatefulWidget {
  const _CreatePrSheet({required this.repo, required this.base, required this.head, required this.commits, this.onCreated});

  final RepoController repo;
  final String base;
  final String head;
  final List<Commit> commits;
  final VoidCallback? onCreated;

  @override
  State<_CreatePrSheet> createState() => _CreatePrSheetState();
}

class _CreatePrSheetState extends State<_CreatePrSheet> {
  late final _title = TextEditingController(text: widget.commits.isEmpty ? widget.head : widget.commits.first.subject);
  late final _body = TextEditingController(
      text: widget.commits.length > 1 ? widget.commits.map((c) => '- ${c.subject}').join('\n') : '');
  bool _draft = false;

  @override
  void initState() {
    super.initState();
    _title.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final repo = widget.repo;
    final title = _title.text.trim();
    final publish = repo.needsPublish;
    final commands = [
      if (publish) repo.pushCommand,
      GhCommands.prCreate(base: widget.base, head: widget.head, title: title.isEmpty ? '<title>' : title, draft: _draft),
    ];

    Future<void> submit() async {
      if (title.isEmpty) return;
      Navigator.pop(context);
      await RepoActions.report(
        context,
        () async {
          CommandResult r = const CommandResult(0, '', '');
          if (publish) r = await repo.push();
          if (!r.ok) return r;
          return repo.execute(
            GhCommands.prCreate(base: widget.base, head: widget.head, title: title, draft: _draft),
            stdin: _body.text,
          );
        }(),
        done: l10n.donePrCreated,
      );
      widget.onCreated?.call();
    }

    return ActionSheetBody(
      title: l10n.prCreate,
      commands: commands,
      confirmLabel: publish ? l10n.prPublishAndCreate : l10n.prCreate,
      onConfirm: title.isEmpty ? null : submit,
      children: [
        Text('${widget.head} → ${widget.base}', style: AppFonts.mono.copyWith(fontSize: 12)),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _title,
          autofocus: true,
          style: AppFonts.userContent.copyWith(fontSize: 13),
          decoration: InputDecoration(labelText: l10n.prTitleLabel),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _body,
          minLines: 3,
          maxLines: 8,
          style: AppFonts.userContent.copyWith(fontSize: 13),
          decoration: InputDecoration(labelText: l10n.prBodyLabel),
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: _draft,
          onChanged: (v) => setState(() => _draft = v ?? false),
          title: Text(l10n.prDraft),
        ),
      ],
    );
  }
}
