import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/command_runner.dart';
import '../../git/commands.dart';
import '../../git/tags.dart';
import '../../github/models.dart';
import '../../l10n/app_localizations.dart';
import '../../release/release_flow.dart';
import '../../release/repo_release_info.dart';
import '../../release/version_files.dart';
import '../../theme/app_theme.dart';
import '../repo_actions.dart';
import '../repo_scope.dart';
import '../shortcut_label.dart';
import '../widgets.dart';
import '../markdown_editor.dart';
import 'pr_tab.dart';
import 'release_list.dart';
import 'remotes_tab.dart';

/// 릴리스 탭과 마법사 (UI_UX.md §4.5, PLAN.md 3.8). PR 경유가 기본.
class ReleaseTab extends StatefulWidget {
  const ReleaseTab({super.key, required this.flow, required this.onShowChanges});

  final ReleaseFlow flow;
  final VoidCallback onShowChanges;

  @override
  State<ReleaseTab> createState() => _ReleaseTabState();
}

class _ReleaseTabState extends State<ReleaseTab> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final flow = widget.flow;
    flow.draftNotesBuilder = () => draftReleaseNotes(
          flow.commits,
          featuresTitle: l10n.notesFeatures,
          fixesTitle: l10n.notesFixes,
          otherTitle: l10n.notesOther,
        );
    return ListenableBuilder(
      listenable: flow,
      builder: (context, _) => flow.step == ReleaseStep.check && flow.checks.isEmpty && !flow.loading
          ? _Overview(flow: flow)
          : _Wizard(flow: flow, onShowChanges: widget.onShowChanges),
    );
  }
}

/// 새 릴리스를 시작하기 전: 마지막 태그와 시작 버튼.
class _Overview extends StatelessWidget {
  const _Overview({required this.flow});

  final ReleaseFlow flow;

  @override
  Widget build(BuildContext context) {
    final repo = RepoScope.of(context);
    final env = RepoScope.environmentOf(context);
    final l10n = AppLocalizations.of(context);
    final latest = repo.tags.where((t) => t.version != null).firstOrNull;
    final github = repo.githubRemote != null;
    final reason = !github ? l10n.releaseNeedsGitHub : (!env.ghReady ? ghUnavailableText(l10n, env) : null);

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      children: [
        SectionHeader(title: l10n.releaseTitle),
        EmptyState(
          icon: Icons.rocket_launch_outlined,
          title: latest == null ? l10n.releaseNoTags : l10n.releaseLatest(latest.name),
          message: reason ?? l10n.releaseIntro,
          action: FilledButton.icon(
            onPressed: reason != null || repo.busy
                ? null
                : () {
                    flow.ghReady = env.ghReady;
                    flow.runChecks();
                  },
            icon: const Icon(Icons.rocket_launch_rounded, size: 16),
            label: Text('${l10n.releaseStart}  ${shortcutLabel('R', shift: true)}'),
          ),
        ),
        // 릴리스 관리 (PLAN.md 3.8.6)
        if (reason == null) ReleaseList(repo: repo),
      ],
    );
  }
}

class _Wizard extends StatelessWidget {
  const _Wizard({required this.flow, required this.onShowChanges});

  final ReleaseFlow flow;
  final VoidCallback onShowChanges;

  static const _steps = [
    ReleaseStep.check,
    ReleaseStep.version,
    ReleaseStep.pr,
    ReleaseStep.merge,
    ReleaseStep.tag,
    ReleaseStep.notes,
    ReleaseStep.ci,
  ];

  String _title(AppLocalizations l10n, ReleaseStep s) => switch (s) {
        ReleaseStep.check => l10n.stepCheck,
        ReleaseStep.version => l10n.stepVersion,
        ReleaseStep.pr => l10n.stepPr,
        ReleaseStep.merge => l10n.stepMerge,
        ReleaseStep.tag => l10n.stepTag,
        ReleaseStep.notes => flow.ciMode ? l10n.stepNotesCi : l10n.stepNotes,
        ReleaseStep.ci => l10n.stepCi,
        ReleaseStep.done => '',
      };

  String _summary(AppLocalizations l10n, ReleaseStep s) => switch (s) {
        ReleaseStep.check => flow.buildRun == null
            ? l10n.stepCheckDone
            : '${l10n.stepCheckDone} · ${l10n.manualBuildShort(runStateLabel(l10n, flow.buildRun!.state))}',
        ReleaseStep.version => '${flow.current} → ${flow.next} · ${flow.releaseBranch}',
        ReleaseStep.pr => flow.pr == null ? '' : '#${flow.pr!.number} ${flow.pr!.title}',
        ReleaseStep.merge => l10n.stepMergeDone(flow.pr?.number ?? 0),
        ReleaseStep.tag => flow.tag ?? '',
        ReleaseStep.notes => flow.ciMode ? l10n.stepNotesCiSummary : (flow.release?.url ?? ''),
        ReleaseStep.ci => flow.run == null ? '' : runStateLabel(l10n, flow.run!.state),
        ReleaseStep.done => '',
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final current = flow.step;
    final index = current == ReleaseStep.done ? _steps.length : _steps.indexOf(current);

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.sm, AppSpacing.sm),
          child: Row(children: [
            Expanded(
              child: Text(flow.next == null ? l10n.releaseNew : l10n.releaseNewVersion(flow.next!.tag),
                  style: theme.textTheme.titleLarge),
            ),
            IconButton(
              tooltip: l10n.releaseCancel,
              icon: const Icon(Icons.close_rounded, size: 18),
              onPressed: () async {
                if (index >= 1 && current != ReleaseStep.done) {
                  final ok = await confirmDanger(
                    context,
                    title: l10n.releaseCancelTitle,
                    message: index >= 5 ? l10n.releaseCancelAfterTag : l10n.releaseCancelMessage(flow.releaseBranch),
                    confirm: l10n.releaseCancel,
                  );
                  if (!ok) return;
                }
                flow.checks.clear();
                await flow.cancel();
              },
            ),
          ]),
        ),
        for (var i = 0; i < _steps.length; i++)
          _StepTile(
            number: i + 1,
            title: _title(l10n, _steps[i]),
            state: i < index ? _StepState.done : (i == index ? _StepState.active : _StepState.pending),
            summary: i < index ? _summary(l10n, _steps[i]) : null,
            // CI가 릴리스를 만드는 저장소는 노트 단계를 CI 뒤로 미룬다.
            skipped: _steps[i] == ReleaseStep.notes && flow.ciMode && i < index,
            child: i == index ? _content(context, _steps[i]) : null,
          ),
        if (current == ReleaseStep.done) _Done(flow: flow),
      ],
    );
  }

  Widget _content(BuildContext context, ReleaseStep s) => switch (s) {
        ReleaseStep.check => _CheckStep(flow: flow, onShowChanges: onShowChanges),
        ReleaseStep.version => _VersionStep(flow: flow),
        ReleaseStep.pr => _PrStep(flow: flow),
        ReleaseStep.merge => _MergeStep(flow: flow),
        ReleaseStep.tag => _TagStep(flow: flow),
        ReleaseStep.notes => _NotesStep(flow: flow),
        ReleaseStep.ci => _CiStep(flow: flow),
        ReleaseStep.done => const SizedBox.shrink(),
      };
}

enum _StepState { done, active, pending }

class _StepTile extends StatelessWidget {
  const _StepTile({
    required this.number,
    required this.title,
    required this.state,
    this.summary,
    this.child,
    this.skipped = false,
  });

  final int number;
  final String title;
  final _StepState state;
  final String? summary;
  final Widget? child;
  final bool skipped;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = switch (state) {
      _StepState.done => toneColor(context, Tone.success),
      _StepState.active => theme.colorScheme.primary,
      _StepState.pending => theme.colorScheme.onSurfaceVariant,
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 4, AppSpacing.md, 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: state == _StepState.pending ? null : color.withValues(alpha: 0.16),
            border: Border.all(color: color),
          ),
          child: state == _StepState.done
              ? Icon(skipped ? Icons.redo_rounded : Icons.check_rounded, size: 13, color: color)
              : Text('$number', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SizedBox(
              height: 22,
              child: Row(children: [
                Text(title,
                    style: theme.textTheme.titleSmall?.copyWith(
                        color: state == _StepState.pending ? theme.colorScheme.onSurfaceVariant : null)),
                if (summary != null && summary!.isNotEmpty) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(summary!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.merge(AppFonts.userContent)),
                  ),
                ],
              ]),
            ),
            if (child != null) Padding(padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.md), child: child),
          ]),
        ),
      ]),
    );
  }
}

/// ✓/✕ 한 줄과 (있으면) 해결 버튼.
class _CheckRow extends StatelessWidget {
  const _CheckRow({required this.ok, required this.label, this.detail, this.action});

  final bool? ok;
  final String label;
  final String? detail;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: ok == null
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : Icon(ok! ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  size: 16, color: toneColor(context, ok! ? Tone.success : Tone.danger)),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: theme.textTheme.bodyMedium),
            if (detail != null && detail!.isNotEmpty) Text(detail!, style: theme.textTheme.bodySmall),
          ]),
        ),
        if (action != null && ok == false) action!,
      ]),
    );
  }
}

// --- ① 점검 ---------------------------------------------------------------

class _CheckStep extends StatelessWidget {
  const _CheckStep({required this.flow, required this.onShowChanges});

  final ReleaseFlow flow;
  final VoidCallback onShowChanges;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final repo = flow.repo;
    if (flow.loading) {
      return const Padding(padding: EdgeInsets.all(AppSpacing.lg), child: Center(child: CircularProgressIndicator()));
    }
    bool? c(ReleaseCheck k) => flow.checks[k];
    final wf = flow.workflow;
    final risks = flow.buildRisks;

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _CheckRow(
        ok: c(ReleaseCheck.cleanTree),
        label: l10n.checkCleanTree,
        action: TextButton(onPressed: onShowChanges, child: Text(l10n.checkShowChanges)),
      ),
      _CheckRow(
        ok: c(ReleaseCheck.onDefaultBranch),
        label: l10n.checkOnDefault(flow.defaultBranch),
        action: TextButton(
          onPressed: repo.busy
              ? null
              : () async {
                  final b = repo.localBranches.where((b) => b.name == flow.defaultBranch).firstOrNull;
                  if (b != null) await RepoActions.report(context, repo.switchTo(b), done: l10n.doneSwitch(b.name));
                  await flow.runChecks();
                },
          child: Text(l10n.branchesSwitch),
        ),
      ),
      _CheckRow(
        ok: c(ReleaseCheck.synced),
        label: l10n.checkSynced,
        detail: '↑${repo.status.ahead} ↓${repo.status.behind}',
        action: TextButton(
          onPressed: repo.busy
              ? null
              : () async {
                  if (repo.status.behind > 0) {
                    await RepoActions.pull(context, repo);
                  } else {
                    await RepoActions.push(context, repo);
                  }
                  await flow.runChecks();
                },
          child: Text(repo.status.behind > 0 ? l10n.headerPull : l10n.headerPush),
        ),
      ),
      _CheckRow(ok: c(ReleaseCheck.github), label: l10n.checkGitHub),
      _CheckRow(
        ok: c(ReleaseCheck.hasChanges),
        label: flow.lastTag == null ? l10n.checkFirstRelease : l10n.checkChangesSince(flow.releaseCommits.length, flow.lastTag!),
      ),
      const SizedBox(height: AppSpacing.sm),
      Text(
        wf == null ? l10n.checkNoWorkflow : (wf.onTags ? l10n.checkWorkflowCi(wf.file) : l10n.checkWorkflowOther(wf.file)),
        style: theme.textTheme.bodySmall,
      ),
      if (wf != null && wf.dispatch && risks.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.md),
        _Card(children: [
          Text(l10n.manualBuildTitle, style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(l10n.manualBuildWhy, style: theme.textTheme.bodySmall),
          const SizedBox(height: 4),
          for (final f in risks.take(5))
            Text('· $f', style: AppFonts.mono.copyWith(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
          if (risks.length > 5) Text('· …', style: theme.textTheme.bodySmall),
          const SizedBox(height: AppSpacing.sm),
          if (flow.buildRun != null) RunView(run: flow.buildRun!) else if (flow.checks.isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: repo.busy ? null : () => _report(context, flow.startManualBuild(), l10n.doneManualBuildStarted),
                icon: const Icon(Icons.build_circle_outlined, size: 16),
                label: Text(l10n.manualBuildStart),
              ),
            ),
        ]),
      ],
      const SizedBox(height: AppSpacing.md),
      Row(children: [
        TextButton.icon(
          onPressed: repo.busy ? null : flow.runChecks,
          icon: const Icon(Icons.refresh_rounded, size: 16),
          label: Text(l10n.envRecheck),
        ),
        const Spacer(),
        FilledButton(onPressed: flow.checksPassed ? flow.proceedToVersion : null, child: Text(l10n.stepNext)),
      ]),
    ]);
  }
}

Future<void> _report(BuildContext context, Future<CommandResult> run, String done) =>
    RepoActions.report(context, run, done: done);

class _Card extends StatelessWidget {
  const _Card({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.tile),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
    );
  }
}

// --- ② 버전 ---------------------------------------------------------------

class _VersionStep extends StatefulWidget {
  const _VersionStep({required this.flow});

  final ReleaseFlow flow;

  @override
  State<_VersionStep> createState() => _VersionStepState();
}

class _VersionStepState extends State<_VersionStep> {
  final _custom = TextEditingController();

  @override
  void dispose() {
    _custom.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final flow = widget.flow;
    final current = flow.current;
    final suggestion = suggestBump(current, flow.commits);
    final options = <(BumpKind, String)>[
      (BumpKind.patch, current.pre != null ? l10n.bumpFinal : 'patch'),
      (BumpKind.minor, 'minor'),
      (BumpKind.major, 'major'),
      (BumpKind.prerelease, l10n.bumpPrerelease),
    ];
    final taken = flow.repo.tags.map((t) => t.name).toSet();

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(l10n.versionCurrent(current.toString(), flow.files.isEmpty ? l10n.versionFromTag : flow.files.first.path),
          style: theme.textTheme.bodySmall),
      const SizedBox(height: AppSpacing.sm),
      Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [
        for (final (kind, label) in options)
          () {
            final v = bump(current, kind);
            final selected = flow.next == v;
            final recommended = kind == suggestion.kind;
            return ChoiceChip(
              selected: selected,
              onSelected: taken.contains(v.tag) ? null : (_) => flow.chooseVersion(v),
              label: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(label, style: theme.textTheme.labelMedium),
                  if (recommended) ...[
                    const SizedBox(width: 4),
                    StatusPill(label: l10n.versionRecommended, tone: Tone.primary),
                  ],
                ]),
                Text(v.tag, style: AppFonts.mono.copyWith(fontSize: 12.5, fontWeight: FontWeight.w700)),
              ]),
            );
          }(),
      ]),
      const SizedBox(height: 4),
      Text(l10n.versionReason(suggestion.feats, suggestion.fixes, suggestion.breaking), style: theme.textTheme.bodySmall),
      const SizedBox(height: AppSpacing.sm),
      TextField(
        controller: _custom,
        style: AppFonts.mono.copyWith(fontSize: 12.5),
        decoration: InputDecoration(isDense: true, labelText: l10n.versionCustom, hintText: '1.2.3 / 1.2.3-rc.1'),
        onChanged: (s) {
          final v = SemVer.tryParse(s);
          if (v != null) flow.chooseVersion(withNextBuild(current, v));
        },
      ),
      const SizedBox(height: AppSpacing.md),
      if (flow.fileChanges.isNotEmpty) ...[
        Text(l10n.versionFiles, style: theme.textTheme.labelMedium),
        for (final (path, from, to) in flow.fileChanges)
          Text('$path   $from → $to', style: AppFonts.mono.copyWith(fontSize: 11.5)),
        const SizedBox(height: AppSpacing.sm),
      ] else
        Text(l10n.versionNoFiles, style: theme.textTheme.bodySmall),
      if (flow.next != null && taken.contains(flow.next!.tag))
        Text(l10n.tagNameExists, style: TextStyle(color: theme.colorScheme.error)),
      CommandPreview(commands: flow.versionCommands),
      const SizedBox(height: AppSpacing.sm),
      Align(
        alignment: Alignment.centerRight,
        child: FilledButton(
          onPressed: flow.next == null || flow.repo.busy || taken.contains(flow.next!.tag)
              ? null
              : () => _report(context, flow.createReleaseCommit(), l10n.doneReleaseCommit(flow.next!.tag)),
          child: Text(l10n.versionCommit),
        ),
      ),
    ]);
  }
}

// --- ③ PR -----------------------------------------------------------------

class _PrStep extends StatefulWidget {
  const _PrStep({required this.flow});

  final ReleaseFlow flow;

  @override
  State<_PrStep> createState() => _PrStepState();
}

class _PrStepState extends State<_PrStep> {
  TextEditingController? _body;

  @override
  void dispose() {
    _body?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final flow = widget.flow;
    _body ??= TextEditingController(text: flow.prBody(l10n.prBodyChanges));
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(flow.prTitle, style: Theme.of(context).textTheme.titleSmall),
      Text('${flow.releaseBranch} → ${flow.defaultBranch}', style: AppFonts.mono.copyWith(fontSize: 11.5)),
      const SizedBox(height: AppSpacing.sm),
      TextField(
        controller: _body,
        minLines: 3,
        maxLines: 8,
        style: AppFonts.userContent.copyWith(fontSize: 12.5),
        decoration: InputDecoration(labelText: l10n.prBodyLabel),
      ),
      const SizedBox(height: AppSpacing.md),
      CommandPreview(commands: flow.prCommands),
      const SizedBox(height: AppSpacing.sm),
      Align(
        alignment: Alignment.centerRight,
        child: FilledButton(
          onPressed: flow.repo.busy ? null : () => _report(context, flow.createPr(_body!.text), l10n.donePrCreated),
          child: Text(l10n.releasePushAndPr),
        ),
      ),
    ]);
  }
}

// --- ④ 병합 ---------------------------------------------------------------

class _MergeStep extends StatelessWidget {
  const _MergeStep({required this.flow});

  final ReleaseFlow flow;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pr = flow.pr;
    if (pr == null) {
      return TextButton(onPressed: () => flow.refreshPr(), child: Text(l10n.appBarRefresh));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(l10n.mergeWaiting(pr.number), style: Theme.of(context).textTheme.bodySmall)),
        IconButton(
          tooltip: l10n.appBarRefresh,
          iconSize: 16,
          icon: const Icon(Icons.refresh_rounded),
          onPressed: () => flow.refreshPr(),
        ),
      ]),
      const SizedBox(height: AppSpacing.sm),
      PrCard(pr: pr, repo: flow.repo, onChanged: () => flow.refreshPr(), showMerge: false),
      const SizedBox(height: AppSpacing.md),
      CommandPreview(commands: flow.mergeCommands),
      const SizedBox(height: AppSpacing.sm),
      Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        TextButton(onPressed: () => launchUrl(Uri.parse(pr.url)), child: Text(l10n.prOpenOnGitHub)),
        const SizedBox(width: AppSpacing.sm),
        FilledButton(
          onPressed: flow.repo.busy || !pr.open || pr.conflicting || pr.draft
              ? null
              : () => _report(context, flow.mergePr(), l10n.donePrMerged(pr.number)),
          child: Text(l10n.prMerge),
        ),
      ]),
    ]);
  }
}

// --- ⑤ 태그 ---------------------------------------------------------------

class _TagStep extends StatelessWidget {
  const _TagStep({required this.flow});

  final ReleaseFlow flow;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    bool? c(TagCheck k) => flow.tagChecks[k];
    final tag = flow.tag ?? '';
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _CheckRow(ok: c(TagCheck.prMerged), label: l10n.tagCheckPrMerged(flow.pr?.number ?? 0)),
      _CheckRow(ok: c(TagCheck.synced), label: l10n.tagCheckSynced(flow.defaultBranch)),
      _CheckRow(
        ok: c(TagCheck.versionMatches),
        label: l10n.tagCheckVersion(tag),
        detail: c(TagCheck.versionMatches) == false ? l10n.tagCheckVersionWrong(flow.defaultBranchVersion) : null,
      ),
      _CheckRow(ok: c(TagCheck.tagFree), label: l10n.tagCheckFree(tag)),
      const SizedBox(height: AppSpacing.md),
      CommandPreview(commands: flow.tagCommands),
      const SizedBox(height: AppSpacing.sm),
      Row(children: [
        TextButton.icon(
          onPressed: flow.repo.busy ? null : flow.runTagChecks,
          icon: const Icon(Icons.refresh_rounded, size: 16),
          label: Text(l10n.envRecheck),
        ),
        const Spacer(),
        FilledButton(
          onPressed: !flow.tagChecksPassed || flow.repo.busy
              ? null
              : () async {
                  // 되돌릴 수 없지만 위험한 일은 아니므로 primary 확인 (UI_UX.md §4.5 ⑤).
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(l10n.tagConfirmTitle(tag)),
                      content: SizedBox(
                        width: 360,
                        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(l10n.tagConfirmMessage(tag, flow.defaultBranch)),
                          const SizedBox(height: AppSpacing.md),
                          CommandPreview(commands: flow.tagCommands),
                        ]),
                      ),
                      actions: [
                        TextButton(autofocus: true, onPressed: () => Navigator.pop(context, false), child: Text(l10n.commonCancel)),
                        FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.tagConfirmPush)),
                      ],
                    ),
                  );
                  if (ok == true && context.mounted) await _report(context, flow.pushTag(), l10n.doneTagPushed(tag));
                },
          child: Text(l10n.tagConfirmPush),
        ),
      ]),
    ]);
  }
}

// --- ⑥ 노트 ---------------------------------------------------------------

class _NotesStep extends StatefulWidget {
  const _NotesStep({required this.flow});

  final ReleaseFlow flow;

  @override
  State<_NotesStep> createState() => _NotesStepState();
}

class _NotesStepState extends State<_NotesStep> {
  late final _notes = TextEditingController(text: widget.flow.notes);

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final flow = widget.flow;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      MarkdownEditor(controller: _notes, label: l10n.notesLabel),
      const SizedBox(height: AppSpacing.md),
      CommandPreview(commands: [flow.releaseCreateCommand]),
      const SizedBox(height: AppSpacing.sm),
      Align(
        alignment: Alignment.centerRight,
        child: FilledButton(
          onPressed: flow.repo.busy ? null : () => _report(context, flow.createRelease(_notes.text), l10n.doneReleaseCreated),
          child: Text(l10n.notesCreateRelease),
        ),
      ),
    ]);
  }
}

// --- ⑦ CI -----------------------------------------------------------------

class _CiStep extends StatelessWidget {
  const _CiStep({required this.flow});

  final ReleaseFlow flow;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final run = flow.run;
    if (run == null) {
      return Row(children: [
        const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(l10n.ciWaitingForRun(flow.tag ?? ''), style: theme.textTheme.bodySmall)),
      ]);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      RunView(run: run),
      if (run.done && run.state != RunState.success) ...[
        const SizedBox(height: AppSpacing.sm),
        if (flow.failedLog.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppRadius.button),
              border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.5)),
            ),
            child: SelectableText(flow.failedLog, style: AppFonts.mono.copyWith(fontSize: 10.5)),
          ),
        const SizedBox(height: AppSpacing.sm),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: flow.repo.busy ? null : () => _report(context, flow.rerunFailed(), l10n.doneRerun),
            icon: const Icon(Icons.replay_rounded, size: 16),
            label: Text(l10n.ciRerunFailed),
          ),
        ),
      ],
    ]);
  }
}

String runStateLabel(AppLocalizations l10n, RunState s) => switch (s) {
      RunState.queued => l10n.runQueued,
      RunState.running => l10n.runRunning,
      RunState.success => l10n.runSuccess,
      RunState.failure => l10n.runFailure,
      RunState.cancelled => l10n.runCancelled,
      RunState.skipped => l10n.runSkipped,
    };

/// 워크플로 실행: 잡마다 한 줄 (UI_UX.md §4.5 ⑦).
class RunView extends StatelessWidget {
  const RunView({super.key, required this.run});

  final WorkflowRun run;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    Widget icon(RunState s) => switch (s) {
          RunState.success => Icon(Icons.check_circle_rounded, size: 15, color: toneColor(context, Tone.success)),
          RunState.failure => Icon(Icons.cancel_rounded, size: 15, color: toneColor(context, Tone.danger)),
          RunState.running || RunState.queued =>
            const SizedBox(width: 13, height: 13, child: CircularProgressIndicator(strokeWidth: 2)),
          _ => Icon(Icons.remove_circle_outline_rounded, size: 15, color: theme.colorScheme.onSurfaceVariant),
        };
    String dur(Duration d) => d.inMinutes > 0 ? '${d.inMinutes}m${d.inSeconds % 60}s' : '${d.inSeconds}s';
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        icon(run.state),
        const SizedBox(width: 6),
        Expanded(child: Text('${run.name} · ${runStateLabel(l10n, run.state)}', style: theme.textTheme.titleSmall)),
        TextButton.icon(
          onPressed: () => launchUrl(Uri.parse(run.url)),
          icon: const Icon(Icons.open_in_new_rounded, size: 14),
          label: Text(l10n.ciOpenInBrowser),
        ),
      ]),
      for (final j in run.jobs)
        Padding(
          padding: const EdgeInsets.only(left: 4, top: 2),
          child: Row(children: [
            icon(j.state),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                j.failedStep == null ? j.name : '${j.name} — ${j.failedStep}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.mono.copyWith(fontSize: 11.5, color: theme.colorScheme.onSurface),
              ),
            ),
            if (j.duration != null && j.state != RunState.skipped)
              Text(dur(j.duration!), style: theme.textTheme.labelSmall),
          ]),
        ),
    ]);
  }
}

class _Done extends StatefulWidget {
  const _Done({required this.flow});

  final ReleaseFlow flow;

  @override
  State<_Done> createState() => _DoneState();
}

class _DoneState extends State<_Done> {
  TextEditingController? _notes;

  @override
  void dispose() {
    _notes?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final flow = widget.flow;
    final r = flow.release;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: _Card(children: [
        Row(children: [
          Icon(Icons.celebration_rounded, color: toneColor(context, Tone.success)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(l10n.releaseDone(flow.tag ?? ''), style: theme.textTheme.titleMedium)),
        ]),
        if (r != null) ...[
          const SizedBox(height: AppSpacing.sm),
          TextButton.icon(
            style: TextButton.styleFrom(alignment: Alignment.centerLeft, padding: EdgeInsets.zero),
            onPressed: () => launchUrl(Uri.parse(r.url)),
            icon: const Icon(Icons.open_in_new_rounded, size: 14),
            label: Text(r.name.isEmpty ? r.tag : r.name),
          ),
          if (r.prerelease) StatusPill(label: l10n.releasePrerelease, tone: Tone.warning),
          for (final a in r.assets)
            Text('${a.name}  ${(a.size / 1024 / 1024).toStringAsFixed(1)} MB',
                style: AppFonts.mono.copyWith(fontSize: 11.5)),
          // CI가 만든 릴리스의 노트 고치기 (PLAN.md 3.8.4).
          if (flow.ciMode) ...[
            const SizedBox(height: AppSpacing.md),
            if (_notes == null)
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton(
                  onPressed: () => setState(() => _notes = TextEditingController(text: r.body)),
                  child: Text(l10n.notesEdit),
                ),
              )
            else ...[
              MarkdownEditor(controller: _notes!, label: l10n.notesLabel),
              const SizedBox(height: AppSpacing.sm),
              CommandPreview(commands: [GhCommands.releaseEditNotes(flow.tag ?? '')]),
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: flow.repo.busy
                      ? null
                      : () async {
                          await _report(context, flow.editReleaseNotes(_notes!.text), l10n.doneNotesSaved);
                          if (mounted) setState(() => _notes = null);
                        },
                  child: Text(l10n.commonSave),
                ),
              ),
            ],
          ],
        ],
        const SizedBox(height: AppSpacing.md),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
              flow.checks.clear();
              flow.cancel();
            },
            child: Text(l10n.commonClose),
          ),
        ),
      ]),
    );
  }
}

