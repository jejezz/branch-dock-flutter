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
        title: repo.githubRemote == null
            ? l10n.prNotGitHubTitle
            : l10n.prGhRequiredTitle,
        message: repo.githubRemote == null
            ? l10n.prNotGitHubMessage
            : ghUnavailableText(l10n, env),
      );
    }
    if (head != _loadedFor && !_loading) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _load(repo));
    }

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
            const Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (head == null)
            EmptyState(icon: Icons.merge_rounded, title: l10n.prDetached)
          else if (pr != null && pr.headRef == head && (pr.open || pr.merged))
            PrCard(pr: pr, repo: repo, onChanged: () => _load(repo))
          else if (onDefault)
            EmptyState(
              icon: Icons.merge_rounded,
              title: l10n.prOnDefaultTitle,
              message: l10n.prOnDefaultMessage,
            )
          else
            EmptyState(
              icon: Icons.merge_rounded,
              title: l10n.prNoneTitle(head),
              message: l10n.prNoneMessage(repo.defaultBranch ?? 'main'),
              action: FilledButton.icon(
                onPressed: repo.busy
                    ? null
                    : () => showCreatePrSheet(
                        context,
                        repo,
                        onCreated: () => _load(repo),
                      ),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: Text(l10n.prCreate),
              ),
            ),
          const Divider(height: AppSpacing.xl),
          PrList(repo: repo),
        ],
      ),
    );
  }
}

/// PR 한 개의 상태와 병합 (릴리스 마법사 ④와 같은 카드, UI_UX.md §4.6).
class PrCard extends StatefulWidget {
  const PrCard({
    super.key,
    required this.pr,
    required this.repo,
    required this.onChanged,
    this.showMerge = true,
  });

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
      PrState.open =>
        pr.draft
            ? (l10n.prStateDraft, Tone.neutral)
            : (l10n.prStateOpen, Tone.success),
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

    // 안의 CheckboxListTile이 잉크를 그릴 수 있게 Material로 감싼다.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Material(
        color: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.tile),
          side: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  StatusPill(label: stateLabel, tone: stateTone),
                  const SizedBox(width: AppSpacing.sm),
                  Text('#${pr.number}', style: theme.textTheme.labelMedium),
                  const Spacer(),
                  IconButton(
                    tooltip: l10n.prOpenOnGitHub,
                    visualDensity: VisualDensity.compact,
                    iconSize: 16,
                    icon: const Icon(Icons.open_in_new_rounded),
                    onPressed: () => launchUrl(Uri.parse(pr.url)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                pr.title,
                style: theme.textTheme.titleSmall?.merge(AppFonts.userContent),
              ),
              const SizedBox(height: 2),
              Text(
                '${pr.headRef} → ${pr.baseRef}',
                style: theme.textTheme.bodySmall
                    ?.merge(AppFonts.mono)
                    .copyWith(fontSize: 11.5),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (c.total == 0)
                    StatusPill(label: l10n.prNoChecks)
                  else ...[
                    if (c.passed > 0)
                      StatusPill(
                        label: l10n.prChecksPassed(c.passed),
                        tone: Tone.success,
                        icon: Icons.check_rounded,
                      ),
                    if (c.failed > 0)
                      StatusPill(
                        label: l10n.prChecksFailed(c.failed),
                        tone: Tone.danger,
                        icon: Icons.close_rounded,
                      ),
                    if (c.pending > 0)
                      StatusPill(
                        label: l10n.prChecksPending(c.pending),
                        tone: Tone.warning,
                        icon: Icons.schedule_rounded,
                      ),
                  ],
                  if (pr.reviewDecision == 'APPROVED')
                    StatusPill(label: l10n.prApproved, tone: Tone.success),
                  if (pr.reviewRequired)
                    StatusPill(
                      label: l10n.prReviewRequired,
                      tone: Tone.warning,
                    ),
                ],
              ),
              if (pr.open && widget.showMerge) ...[
                const SizedBox(height: AppSpacing.md),
                if (blocker != null)
                  Text(
                    blocker,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: toneColor(context, Tone.warning),
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButton<PrMergeMethod>(
                        value: _method,
                        isExpanded: true,
                        underline: const SizedBox.shrink(),
                        items: [
                          DropdownMenuItem(
                            value: PrMergeMethod.merge,
                            child: Text(l10n.prMethodMerge),
                          ),
                          DropdownMenuItem(
                            value: PrMergeMethod.squash,
                            child: Text(l10n.prMethodSquash),
                          ),
                          DropdownMenuItem(
                            value: PrMergeMethod.rebase,
                            child: Text(l10n.prMethodRebase),
                          ),
                        ],
                        onChanged: (v) =>
                            setState(() => _method = v ?? PrMergeMethod.merge),
                      ),
                    ),
                    HelpButton(
                      concept: switch (_method) {
                        PrMergeMethod.merge => Concept.mergeCommit,
                        PrMergeMethod.squash => Concept.squash,
                        PrMergeMethod.rebase => Concept.rebase,
                      },
                    ),
                  ],
                ),
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
            ],
          ),
        ),
      ),
    );
  }
}

/// PR 만들기 (PLAN.md 3.9): 기준 브랜치 선택, 제목(마지막 커밋), 본문, 초안.
/// [head]를 주지 않으면 현재 브랜치 — 브랜치 메뉴에서는 그 브랜치를 준다.
Future<void> showCreatePrSheet(
  BuildContext context,
  RepoController repo, {
  String? head,
  VoidCallback? onCreated,
}) async {
  final branch = head ?? repo.status.head!;
  final remote = repo.githubRemote?.name ?? repo.defaultRemote ?? 'origin';
  final base = repo.defaultBranch ?? 'main';
  final commits = await loadPrCommits(repo, branch, base, remote);
  if (!context.mounted) return;
  await showCreatePrSheetWith(context, repo, head: branch, commits: commits, onCreated: onCreated);
}

/// 커밋을 이미 읽었을 때 시트만 연다 (테스트에서도 쓴다).
Future<void> showCreatePrSheetWith(
  BuildContext context,
  RepoController repo, {
  required String head,
  required List<Commit> commits,
  VoidCallback? onCreated,
}) {
  final remote = repo.githubRemote?.name ?? repo.defaultRemote ?? 'origin';
  final base = repo.defaultBranch ?? 'main';
  final branch = head;
  return showActionSheet<void>(
    context,
    (context) => _CreatePrSheet(
      repo: repo,
      remote: remote,
      base: base,
      head: branch,
      commits: commits,
      onCreated: onCreated,
    ),
  );
}

/// [base]에 없는 [head]의 커밋 — 제목·본문 기본값에 쓴다.
Future<List<Commit>> loadPrCommits(RepoController repo, String head, String base, String remote) async {
  final log = await repo.read(GitCommands.incoming(head, base: '$remote/$base'));
  return log.ok ? Commit.parse(log.stdout) : const <Commit>[];
}

class _CreatePrSheet extends StatefulWidget {
  const _CreatePrSheet({
    required this.repo,
    required this.remote,
    required this.base,
    required this.head,
    required this.commits,
    this.onCreated,
  });

  final RepoController repo;
  final String remote;
  final String base;
  final String head;
  final List<Commit> commits;
  final VoidCallback? onCreated;

  @override
  State<_CreatePrSheet> createState() => _CreatePrSheetState();
}

class _CreatePrSheetState extends State<_CreatePrSheet> {
  late final _title = TextEditingController(
    text: widget.commits.isEmpty ? widget.head : widget.commits.first.subject,
  );
  late final _body = TextEditingController(
    text: widget.commits.length > 1
        ? widget.commits.map((c) => '- ${c.subject}').join('\n')
        : '',
  );
  late String _base = widget.base;
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

  /// 기준으로 고를 수 있는 브랜치: GitHub 원격의 브랜치 (head 제외, 기본 브랜치 먼저).
  List<String> get _bases {
    final names = widget.repo.remoteBranches
        .where((b) => b.remoteName == widget.remote && b.shortName != widget.head)
        .map((b) => b.shortName)
        .toList();
    if (!names.contains(widget.base)) names.insert(0, widget.base);
    names.sort((a, b) => a == widget.base ? -1 : (b == widget.base ? 1 : a.compareTo(b)));
    return names;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final repo = widget.repo;
    final title = _title.text.trim();
    // 이 브랜치가 원격에 없으면 먼저 게시한다 (현재 브랜치가 아니어도).
    final branch = repo.localBranches.where((b) => b.name == widget.head).firstOrNull;
    final publish = branch != null && (branch.upstream == null || branch.upstreamGone);
    final publishCommand = GitCommands.publish(widget.remote, widget.head);
    List<String> create(String t) => GhCommands.prCreate(base: _base, head: widget.head, title: t, draft: _draft);
    final commands = [if (publish) publishCommand, create(title.isEmpty ? '<title>' : title)];

    Future<void> submit() async {
      if (title.isEmpty) return;
      Navigator.pop(context);
      final ok = await RepoActions.report(context, () async {
        CommandResult r = const CommandResult(0, '', '');
        if (publish) r = await repo.execute(publishCommand);
        if (!r.ok) return r;
        return repo.execute(create(title), stdin: _body.text);
      }(), done: l10n.donePrCreated);
      if (ok) await repo.loadHeadPr(force: true);
      widget.onCreated?.call();
    }

    return ActionSheetBody(
      title: l10n.prCreate,
      commands: commands,
      confirmLabel: publish ? l10n.prPublishAndCreate : l10n.prCreate,
      onConfirm: title.isEmpty ? null : submit,
      children: [
        Row(children: [
          Flexible(
            child: Text(
              widget.head,
              overflow: TextOverflow.ellipsis,
              style: AppFonts.mono.copyWith(fontSize: 12),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Icon(Icons.arrow_forward_rounded, size: 14),
          ),
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: _base,
              isExpanded: true,
              decoration: InputDecoration(isDense: true, labelText: l10n.prBaseLabel),
              items: [
                for (final b in _bases)
                  DropdownMenuItem(value: b, child: Text(b, style: AppFonts.mono.copyWith(fontSize: 12))),
              ],
              onChanged: (v) => setState(() => _base = v ?? widget.base),
            ),
          ),
        ]),
        if (_base != widget.base) ...[
          const SizedBox(height: 4),
          Text(l10n.prBaseNotDefault(widget.base), style: Theme.of(context).textTheme.bodySmall),
        ],
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

/// 열린 PR 목록 (PLAN.md 3.9 P1): 내가 만든 것 / 리뷰 요청받은 것 / 전체.
class PrList extends StatefulWidget {
  const PrList({super.key, required this.repo});

  final RepoController repo;

  @override
  State<PrList> createState() => _PrListState();
}

class _PrListState extends State<PrList> {
  PrFilter _filter = PrFilter.mine;
  List<PullRequest>? _items;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _items = null);
    final r = await widget.repo.read(GhCommands.prList(_filter, PullRequest.listFields));
    if (!mounted) return;
    setState(() => _items = r.ok ? PullRequest.parseList(r.stdout) : const []);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final items = _items;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.sm, AppSpacing.sm),
        child: Row(children: [
          Expanded(
            child: SegmentedButton<PrFilter>(
              showSelectedIcon: false,
              style: const ButtonStyle(visualDensity: VisualDensity.compact),
              segments: [
                ButtonSegment(value: PrFilter.mine, label: Text(l10n.prFilterMine)),
                ButtonSegment(value: PrFilter.reviewRequested, label: Text(l10n.prFilterReview)),
                ButtonSegment(value: PrFilter.open, label: Text(l10n.prFilterOpen)),
              ],
              selected: {_filter},
              onSelectionChanged: (s) {
                _filter = s.first;
                _load();
              },
            ),
          ),
          IconButton(tooltip: l10n.appBarRefresh, iconSize: 16, icon: const Icon(Icons.refresh_rounded), onPressed: _load),
        ]),
      ),
      if (items == null)
        const Padding(padding: EdgeInsets.all(AppSpacing.lg), child: Center(child: CircularProgressIndicator()))
      else if (items.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Text(l10n.prListEmpty, style: theme.textTheme.bodySmall),
        )
      else
        for (final pr in items) _PrRow(pr: pr, repo: widget.repo, onChanged: _load),
    ]);
  }
}

class _PrRow extends StatelessWidget {
  const _PrRow({required this.pr, required this.repo, required this.onChanged});

  final PullRequest pr;
  final RepoController repo;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final c = pr.checks;
    final current = repo.status.head == pr.headRef;
    return InkWell(
      onTap: () => showPrSheet(context, repo, pr.number, onChanged: onChanged),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 6, 4, 6),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text.rich(
                TextSpan(children: [
                  TextSpan(text: '#${pr.number}  ', style: theme.textTheme.labelMedium),
                  TextSpan(text: pr.title),
                ]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.merge(AppFonts.userContent),
              ),
              const SizedBox(height: 2),
              Wrap(spacing: 4, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
                Text('${pr.headRef} → ${pr.baseRef}',
                    style: AppFonts.mono.copyWith(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
                if (pr.draft) StatusPill(label: l10n.prStateDraft),
                if (c.failed > 0) StatusPill(label: l10n.prChecksFailed(c.failed), tone: Tone.danger),
                if (c.pending > 0) StatusPill(label: l10n.prChecksPending(c.pending), tone: Tone.warning),
                if (c.total > 0 && c.failed == 0 && c.pending == 0)
                  StatusPill(label: l10n.prChecksPassed(c.passed), tone: Tone.success),
                if (pr.reviewDecision == 'APPROVED') StatusPill(label: l10n.prApproved, tone: Tone.success),
                if (current) StatusPill(label: l10n.prCurrentBranch, tone: Tone.primary),
              ]),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(pr.author, style: theme.textTheme.labelSmall),
            Text(relativeTime(l10n, pr.updated), style: theme.textTheme.labelSmall),
          ]),
          const SizedBox(width: 4),
        ]),
      ),
    );
  }
}

/// PR 하나: 카드 + 체크아웃 (`gh pr checkout`) + 병합.
Future<void> showPrSheet(BuildContext context, RepoController repo, int number, {VoidCallback? onChanged}) async {
  final r = await repo.read(GhCommands.prView('$number', PullRequest.jsonFields));
  if (!context.mounted) return;
  final pr = r.ok ? PullRequest.parse(r.stdout) : null;
  if (pr == null) {
    showCommandError(context, r);
    return;
  }
  await showPrSheetWith(context, repo, pr, onChanged: onChanged);
}

Future<void> showPrSheetWith(BuildContext context, RepoController repo, PullRequest pr, {VoidCallback? onChanged}) {
  return showActionSheet<void>(context, (context) {
    final l10n = AppLocalizations.of(context);
    final current = repo.status.head == pr.headRef;
    final checkout = GhCommands.prCheckout(pr.number);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          PrCard(
            pr: pr,
            repo: repo,
            onChanged: () {
              Navigator.pop(context);
              onChanged?.call();
            },
          ),
          if (!current && pr.open) ...[
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text(l10n.prCheckoutWhy, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: AppSpacing.sm),
                CommandPreview(commands: [checkout]),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: repo.busy
                      ? null
                      : () async {
                          Navigator.pop(context);
                          final ok = await RepoActions.report(
                            context,
                            repo.execute(checkout),
                            done: l10n.donePrCheckout(pr.number, pr.headRef),
                          );
                          if (ok) onChanged?.call();
                        },
                  icon: const Icon(Icons.download_rounded, size: 16),
                  label: Text(l10n.prCheckout),
                ),
              ]),
            ),
          ],
        ]),
      ),
    );
  });
}
