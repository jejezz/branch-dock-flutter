import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../git/commands.dart';
import '../../github/models.dart';
import '../../l10n/app_localizations.dart';
import '../../release/repo_release_info.dart';
import '../../repo/repo_controller.dart';
import '../../theme/app_theme.dart';
import '../action_sheet.dart';
import '../repo_actions.dart';
import '../repo_scope.dart';
import '../services.dart';
import '../widgets.dart';
import 'release_tab.dart';
import 'remotes_tab.dart';

/// CI 탭 (UI_UX.md §4.6, PLAN.md 3.10): 현재 브랜치의 최근 실행, 잡별 상태,
/// 다시 실행·취소, 수동 실행. 도는 실행이 있으면 15초마다 확인하고, 끝나면
/// 창이 뒤에 있을 때 OS 알림을 띄운다.
class ActionsTab extends StatefulWidget {
  const ActionsTab({super.key});

  @override
  State<ActionsTab> createState() => _ActionsTabState();
}

class _ActionsTabState extends State<ActionsTab> {
  List<WorkflowRun>? _runs;
  String? _loadedFor;
  int? _expanded;
  final Map<int, WorkflowRun> _details = {};
  final Map<int, String> _failedLogs = {};
  Timer? _poll;
  bool _loading = false;

  RepoController get _repo => RepoScope.of(context);

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final repo = _repo;
    final head = repo.status.head;
    if (head == null || _loading) return;
    _loading = true;
    final r = await repo.read(GhCommands.runList(branch: head, limit: 10));
    _loading = false;
    if (!mounted) return;
    final runs = r.ok ? WorkflowRun.parseList(r.stdout) : const <WorkflowRun>[];
    // 돌던 실행이 끝났으면 알린다.
    final before = {for (final x in _runs ?? const <WorkflowRun>[]) x.id: x};
    for (final run in runs) {
      final prev = before[run.id];
      if (prev != null && !prev.done && run.done) _notify(run);
    }
    setState(() {
      _runs = runs;
      _loadedFor = head;
    });
    if (_expanded != null) await _loadDetail(_expanded!);
    _poll?.cancel();
    if (runs.any((x) => !x.done)) _poll = Timer(const Duration(seconds: 15), _load);
  }

  void _notify(WorkflowRun run) {
    final l10n = AppLocalizations.of(context);
    ServicesScope.of(context).notifyIfAway(
      l10n.notifyRunTitle(run.name, runStateLabel(l10n, run.state)),
      run.title.isEmpty ? run.headBranch : run.title,
    );
  }

  Future<void> _loadDetail(int id) async {
    final repo = _repo;
    final v = await repo.read(GhCommands.runView(id));
    final run = WorkflowRun.parse(v.stdout);
    if (!mounted || run == null) return;
    String? log;
    if (run.done && run.state == RunState.failure && !_failedLogs.containsKey(id)) {
      final l = await repo.read(GhCommands.runFailedLog(id));
      final lines = l.stdout.trimRight().split('\n');
      log = lines.skip(lines.length > 20 ? lines.length - 20 : 0).join('\n');
    }
    if (!mounted) return;
    setState(() {
      _details[id] = run;
      if (log != null) _failedLogs[id] = log;
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
        message: repo.githubRemote == null ? l10n.ciNotGitHubMessage : ghUnavailableText(l10n, env),
      );
    }
    if (head != _loadedFor && !_loading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _load();
      });
    }
    final runs = _runs;
    final dispatch = detectDispatchWorkflows(repo.root);

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      children: [
        SectionHeader(
          title: l10n.ciTitle,
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            if (dispatch.isNotEmpty)
              Flexible(
                child: PopupMenuButton<String>(
                  tooltip: repo.status.hasUpstream ? l10n.ciDispatch : l10n.ciDispatchNeedsPush,
                  enabled: repo.status.hasUpstream && !repo.busy,
                  onSelected: (file) => _dispatch(context, repo, file),
                  itemBuilder: (context) => [
                    for (final f in dispatch) PopupMenuItem(value: f, child: Text(f, style: AppFonts.mono.copyWith(fontSize: 12))),
                  ],
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.play_arrow_rounded, size: 16),
                      const SizedBox(width: 4),
                      Flexible(child: Text(l10n.ciDispatch, overflow: TextOverflow.ellipsis)),
                      const Icon(Icons.arrow_drop_down_rounded, size: 18),
                    ]),
                  ),
                ),
              ),
            IconButton(tooltip: l10n.appBarRefresh, iconSize: 18, icon: const Icon(Icons.refresh_rounded), onPressed: _load),
          ]),
        ),
        if (head == null)
          EmptyState(icon: Icons.bolt_rounded, title: l10n.prDetached)
        else if (runs == null)
          const Padding(padding: EdgeInsets.all(AppSpacing.xl), child: Center(child: CircularProgressIndicator()))
        else if (runs.isEmpty)
          EmptyState(icon: Icons.bolt_rounded, title: l10n.ciEmptyTitle(head), message: l10n.ciEmptyMessage)
        else
          for (final run in runs) _runTile(context, repo, run),
      ],
    );
  }

  Widget _runTile(BuildContext context, RepoController repo, WorkflowRun run) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final expanded = _expanded == run.id;
    final detail = _details[run.id];
    final log = _failedLogs[run.id];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      InkWell(
        onTap: () {
          setState(() => _expanded = expanded ? null : run.id);
          if (!expanded) _loadDetail(run.id);
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 6, AppSpacing.md, 6),
          child: Row(children: [
            _stateIcon(context, run.state),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(run.name, style: theme.textTheme.titleSmall),
                if (run.title.isNotEmpty)
                  Text(run.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.merge(AppFonts.userContent)),
              ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              StatusPill(label: runStateLabel(l10n, run.state), tone: _tone(run.state)),
              const SizedBox(height: 2),
              Text('${run.event} · ${relativeTime(l10n, run.created)}', style: theme.textTheme.labelSmall),
            ]),
          ]),
        ),
      ),
      if (expanded)
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.md, AppSpacing.md),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (detail == null)
              const Padding(padding: EdgeInsets.all(AppSpacing.sm), child: LinearProgressIndicator(minHeight: 2))
            else
              RunView(run: detail),
            if (log != null && log.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(AppRadius.button),
                  border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.5)),
                ),
                child: SelectableText(log, style: AppFonts.mono.copyWith(fontSize: 10.5)),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            Wrap(alignment: WrapAlignment.end, spacing: AppSpacing.sm, children: [
              TextButton(onPressed: () => launchUrl(Uri.parse(run.url)), child: Text(l10n.ciOpenInBrowser)),
              if (!run.done)
                _action(context, repo, GhCommands.runCancel(run.id), l10n.ciCancel, l10n.doneRunCancelled)
              else if (run.state == RunState.failure)
                _action(context, repo, GhCommands.runRerunFailed(run.id), l10n.ciRerunFailed, l10n.doneRerun)
              else
                _action(context, repo, GhCommands.runRerun(run.id), l10n.ciRerun, l10n.doneRerun),
            ]),
          ]),
        ),
      const Divider(height: 1),
    ]);
  }

  Widget _action(BuildContext context, RepoController repo, List<String> command, String label, String done) => Tooltip(
        message: command.join(' '),
        child: OutlinedButton(
          onPressed: repo.busy
              ? null
              : () async {
                  final ok = await RepoActions.report(context, repo.execute(command), done: done);
                  if (ok) {
                    _failedLogs.remove(_expanded);
                    await Future<void>.delayed(const Duration(seconds: 2));
                    await _load();
                  }
                },
          child: Text(label),
        ),
      );

  Future<void> _dispatch(BuildContext context, RepoController repo, String file) {
    final head = repo.status.head!;
    final command = GhCommands.workflowRun(file, head);
    return showActionSheet<void>(context, (context) {
      final l10n = AppLocalizations.of(context);
      return ActionSheetBody(
        title: l10n.ciDispatchTitle(file),
        commands: [command],
        confirmLabel: l10n.ciDispatchConfirm,
        onConfirm: () async {
          Navigator.pop(context);
          final ok = await RepoActions.report(context, repo.execute(command), done: l10n.doneDispatched(file));
          if (ok) {
            // 실행이 목록에 나타날 때까지 조금 걸린다.
            await Future<void>.delayed(const Duration(seconds: 4));
            await _load();
          }
        },
        children: [Text(l10n.ciDispatchMessage(head), style: Theme.of(context).textTheme.bodySmall)],
      );
    });
  }

  static Tone _tone(RunState s) => switch (s) {
        RunState.success => Tone.success,
        RunState.failure => Tone.danger,
        RunState.running || RunState.queued => Tone.warning,
        _ => Tone.neutral,
      };

  static Widget _stateIcon(BuildContext context, RunState s) => switch (s) {
        RunState.success => Icon(Icons.check_circle_rounded, size: 18, color: toneColor(context, Tone.success)),
        RunState.failure => Icon(Icons.cancel_rounded, size: 18, color: toneColor(context, Tone.danger)),
        RunState.running || RunState.queued =>
          const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
        _ => Icon(Icons.remove_circle_outline_rounded, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
      };
}
