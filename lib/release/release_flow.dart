import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/command_runner.dart';
import '../git/commands.dart';
import '../git/commits.dart';
import '../git/tags.dart';
import '../github/models.dart';
import '../repo/repo_controller.dart';
import 'repo_release_info.dart';
import 'version_files.dart';

/// 릴리스 마법사 단계 (UI_UX.md §4.5, PLAN.md 3.8.3 — PR 경유가 기본).
enum ReleaseStep { check, version, pr, merge, tag, notes, ci, done }

/// ① 점검 항목.
enum ReleaseCheck { cleanTree, onDefaultBranch, synced, github, hasChanges }

/// ⑤ 태그 전 점검 항목.
enum TagCheck { prMerged, synced, versionMatches, tagFree }

/// 릴리스 하나의 진행. 저장소마다 하나이고, 진행 상태를 저장해 앱을 다시
/// 열어도 이어서 한다 (UI_UX.md §4.5 마지막 항목).
class ReleaseFlow extends ChangeNotifier {
  ReleaseFlow(this.repo, {required this.ghReady});

  final RepoController repo;

  /// gh 설치·로그인 여부 (EnvironmentStatus.ghReady).
  bool ghReady;

  ReleaseStep step = ReleaseStep.check;
  bool loading = false;
  bool _disposed = false;

  // ① 점검
  final Map<ReleaseCheck, bool> checks = {};
  String? lastTag;
  List<Commit> commits = const [];
  List<String> _risks = const [];
  List<VersionFile> files = const [];
  ReleaseWorkflow? workflow;
  WorkflowRun? buildRun;
  DateTime? _buildRequested;

  // ② 버전
  SemVer? next;

  // ③·④ PR
  PullRequest? pr;

  // ⑤ 태그
  final Map<TagCheck, bool> tagChecks = {};

  // ⑥·⑦ 노트와 CI
  String notes = '';
  WorkflowRun? run;
  String failedLog = '';
  GitHubRelease? release;

  Timer? _poll;

  /// CI 실행(태그 릴리스, 태그 전 수동 빌드)이 끝나면 한 번 부른다 — 알림용.
  void Function(WorkflowRun run, {required bool manualBuild})? onRunFinished;
  final Set<int> _notified = {};

  void _finished(WorkflowRun? run, {required bool manualBuild}) {
    if (run == null || !run.done || !_notified.add(run.id)) return;
    onRunFinished?.call(run, manualBuild: manualBuild);
  }

  List<String> get buildRisks => _risks;
  bool get ciMode => workflow?.onTags ?? false;
  bool get checksPassed => ReleaseCheck.values.every((c) => checks[c] ?? false);
  bool get tagChecksPassed => TagCheck.values.every((c) => tagChecks[c] ?? false);
  String get defaultBranch => repo.defaultBranch ?? 'main';
  String get remote => repo.githubRemote?.name ?? repo.defaultRemote ?? 'origin';
  String? get tag => next?.tag;
  String get releaseBranch => 'release/${next?.tag ?? 'vX.Y.Z'}';
  String get displayName => displayNameFor(repo.root, repo.name);

  /// 현재 버전: 버전 파일, 없으면 마지막 태그, 그것도 없으면 0.0.0.
  SemVer get current =>
      files.isNotEmpty ? files.first.version : (SemVer.tryParse(lastTag ?? '') ?? const SemVer(0, 0, 0));

  /// 버전 올림 커밋에 들어갈 파일 변경 (미리 보기용).
  List<(String path, String from, String to)> get fileChanges {
    final n = next;
    if (n == null) return const [];
    return [
      for (final f in files)
        (f.path, f.version.toString(), f.hasBuild ? n.toString() : n.name),
    ];
  }

  List<Commit> get releaseCommits => commits.where((c) => !c.isMerge && !c.isRelease).toList();

  // --- 저장·재개 -----------------------------------------------------------

  String get _key => 'release_flow:${repo.root}';

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    if (step == ReleaseStep.check || step == ReleaseStep.done || next == null) {
      await prefs.remove(_key);
      return;
    }
    await prefs.setString(
      _key,
      jsonEncode({'step': step.name, 'next': next.toString(), 'pr': pr?.number, 'run': run?.id, 'lastTag': lastTag}),
    );
  }

  /// 저장된 진행이 있으면 그 단계부터 이어서 연다. 없으면 false.
  Future<bool> resume() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return false;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      next = SemVer.tryParse(m['next'] as String);
      lastTag = m['lastTag'] as String?;
      step = ReleaseStep.values.asNameMap()[m['step']] ?? ReleaseStep.check;
      files = detectVersionFiles(repo.root);
      final workflows = detectReleaseWorkflows(repo.root);
      workflow = workflows.isEmpty ? null : workflows.first;
      final number = m['pr'] as int?;
      if (number != null) await refreshPr(number: number);
      final runId = m['run'] as int?;
      if (runId != null) await _loadRun(runId);
      if (lastTag != null) await _loadCommits();
      _schedulePoll();
      notifyListeners();
      return next != null;
    } on Object {
      await prefs.remove(_key);
      return false;
    }
  }

  Future<void> cancel() async {
    step = ReleaseStep.check;
    next = null;
    pr = null;
    run = null;
    release = null;
    _poll?.cancel();
    await _save();
    notifyListeners();
  }

  // --- ① 점검 -------------------------------------------------------------

  Future<void> runChecks() async {
    loading = true;
    notifyListeners();
    await repo.fetch();
    final last = await repo.read(GitCommands.lastTag);
    lastTag = last.ok ? last.stdout.trim() : null;
    await _loadCommits();
    if (lastTag != null) {
      final changed = await repo.read(GitCommands.changedFiles(lastTag!));
      _risks = buildRiskFiles(changed.stdout.split('\n').where((l) => l.isNotEmpty).toList());
    } else {
      _risks = const [];
    }
    files = detectVersionFiles(repo.root);
    final workflows = detectReleaseWorkflows(repo.root);
    workflow = workflows.isEmpty ? null : workflows.first;

    final s = repo.status;
    checks
      ..[ReleaseCheck.cleanTree] = s.staged.isEmpty && s.unstaged.isEmpty && s.conflicts.isEmpty
      ..[ReleaseCheck.onDefaultBranch] = s.head == defaultBranch
      ..[ReleaseCheck.synced] = s.hasUpstream && s.ahead == 0 && s.behind == 0
      ..[ReleaseCheck.github] = ghReady && repo.githubRemote != null
      ..[ReleaseCheck.hasChanges] = releaseCommits.isNotEmpty;
    loading = false;
    notifyListeners();
  }

  Future<void> _loadCommits() async {
    final log = await repo.read(GitCommands.log(since: lastTag, until: 'origin/$defaultBranch'));
    commits = log.ok ? Commit.parse(log.stdout) : const [];
  }

  /// 태그 전 수동 빌드 (3.8.1): 기본 브랜치로 release 워크플로를 돌린다.
  Future<CommandResult> startManualBuild() async {
    final wf = workflow;
    if (wf == null || !wf.dispatch) return const CommandResult(1, '', 'no workflow_dispatch');
    _buildRequested = DateTime.now().toUtc().subtract(const Duration(seconds: 5));
    final r = await repo.execute(GhCommands.workflowRun(wf.file, defaultBranch));
    if (r.ok) {
      buildRun = null;
      _schedulePoll();
    }
    notifyListeners();
    return r;
  }

  Future<void> _pollManualBuild() async {
    final wf = workflow;
    if (wf == null || _buildRequested == null) return;
    if (buildRun == null) {
      final r = await repo.read(
          GhCommands.runList(branch: defaultBranch, workflow: wf.file, event: 'workflow_dispatch', limit: 1));
      final found = WorkflowRun.parseList(r.stdout).firstOrNull;
      if (found != null && found.created != null && found.created!.isAfter(_buildRequested!)) buildRun = found;
    }
    final id = buildRun?.id;
    if (id != null && !(buildRun?.done ?? false)) {
      final v = await repo.read(GhCommands.runView(id));
      buildRun = WorkflowRun.parse(v.stdout) ?? buildRun;
      _finished(buildRun, manualBuild: true);
    }
  }

  void proceedToVersion() {
    step = ReleaseStep.version;
    next ??= bump(current, suggestBump(current, commits).kind);
    notifyListeners();
  }

  // --- ② 버전 -------------------------------------------------------------

  void chooseVersion(SemVer v) {
    next = v;
    notifyListeners();
  }

  /// release/vX.Y.Z 브랜치를 만들고 버전 파일을 고쳐 커밋한다.
  Future<CommandResult> createReleaseCommit() async {
    final n = next!;
    var r = await repo.execute(GitCommands.createBranch(releaseBranch));
    if (!r.ok) return r;
    for (final f in files) {
      final file = File('${repo.root}/${f.path}');
      file.writeAsStringSync(writeVersion(f.kind, file.readAsStringSync(), f.hasBuild ? n : SemVer(n.major, n.minor, n.patch, pre: n.pre)));
    }
    if (files.isNotEmpty) {
      r = await repo.executeAll([
        GitCommands.add(files.map((f) => f.path).toList()),
        GitCommands.commit('chore(release): ${n.tag}'),
      ]);
      if (!r.ok) return r;
    }
    step = ReleaseStep.pr;
    await _save();
    notifyListeners();
    return r;
  }

  List<List<String>> get versionCommands => [
        GitCommands.createBranch(releaseBranch),
        if (files.isNotEmpty) ...[
          GitCommands.add(files.map((f) => f.path).toList()),
          GitCommands.commit('chore(release): ${next?.tag ?? ''}'),
        ],
      ];

  // --- ③ PR ---------------------------------------------------------------

  String get prTitle => 'chore(release): ${next?.tag ?? ''}';

  String prBody(String changesTitle) {
    final lines = releaseCommits.map((c) => '- ${c.subject} (${c.shortHash})').join('\n');
    return '## $changesTitle${lastTag == null ? '' : ' ($lastTag → ${next?.tag})'}\n\n$lines\n';
  }

  List<List<String>> get prCommands => [
        GitCommands.publish(remote, releaseBranch),
        GhCommands.prCreate(base: defaultBranch, head: releaseBranch, title: prTitle),
      ];

  Future<CommandResult> createPr(String body) async {
    var r = await repo.execute(GitCommands.publish(remote, releaseBranch));
    if (!r.ok) return r;
    r = await repo.execute(GhCommands.prCreate(base: defaultBranch, head: releaseBranch, title: prTitle), stdin: body);
    if (!r.ok) return r;
    await refreshPr();
    step = ReleaseStep.merge;
    await _save();
    _schedulePoll();
    notifyListeners();
    return r;
  }

  // --- ④ 병합 -------------------------------------------------------------

  Future<void> refreshPr({int? number}) async {
    final ref = number?.toString() ?? pr?.number.toString() ?? releaseBranch;
    final r = await repo.read(GhCommands.prView(ref, PullRequest.jsonFields));
    if (r.ok) pr = PullRequest.parse(r.stdout) ?? pr;
    if (step == ReleaseStep.merge && (pr?.merged ?? false)) await _afterMerge();
    notifyListeners();
  }

  List<List<String>> get mergeCommands => [
        if (pr != null) GhCommands.prMerge(pr!.number, PrMergeMethod.merge),
        GitCommands.switchTo(defaultBranch),
        GitCommands.pullFastForward,
      ];

  Future<CommandResult> mergePr() async {
    final r = await repo.execute(GhCommands.prMerge(pr!.number, PrMergeMethod.merge));
    if (!r.ok) return r;
    await refreshPr();
    return r;
  }

  Future<void> _afterMerge() async {
    if (repo.status.head != defaultBranch) await repo.execute(GitCommands.switchTo(defaultBranch));
    await repo.execute(GitCommands.pullFastForward);
    // 병합된 release 브랜치는 로컬에서도 정리한다. 실패해도 괜찮다.
    await repo.read(GitCommands.deleteBranch(releaseBranch));
    await repo.refresh();
    step = ReleaseStep.tag;
    await _save();
    await runTagChecks();
  }

  // --- ⑤ 태그 -------------------------------------------------------------

  Future<void> runTagChecks() async {
    await repo.fetch();
    await repo.loadRemoteTags();
    final s = repo.status;
    final onDisk = detectVersionFiles(repo.root);
    final t = tag ?? '';
    tagChecks
      ..[TagCheck.prMerged] = pr?.merged ?? false
      ..[TagCheck.synced] = s.head == defaultBranch && s.hasUpstream && s.ahead == 0 && s.behind == 0
      ..[TagCheck.versionMatches] = onDisk.isEmpty || onDisk.every((f) => f.version.name == next?.name)
      ..[TagCheck.tagFree] =
          !repo.tags.any((x) => x.name == t) && !(repo.remoteTagNames?.contains(t) ?? false);
    notifyListeners();
  }

  /// 태그 전 점검에서 본 기본 브랜치의 버전 (다를 때 이유에 쓴다).
  String get defaultBranchVersion {
    final onDisk = detectVersionFiles(repo.root);
    return onDisk.isEmpty ? '' : onDisk.first.version.name;
  }

  String get tagMessage => '$displayName ${next?.name ?? ''}';

  List<List<String>> get tagCommands => [
        GitCommands.createTag(tag ?? '', message: tagMessage),
        GitCommands.pushTags(remote, [tag ?? '']),
      ];

  Future<CommandResult> pushTag() async {
    final r = await repo.executeAll(tagCommands);
    if (!r.ok) return r;
    await repo.loadRemoteTags();
    step = ciMode ? ReleaseStep.ci : ReleaseStep.notes;
    notes = _draftNotes;
    await _save();
    _schedulePoll();
    notifyListeners();
    return r;
  }

  // --- ⑥ 노트 -------------------------------------------------------------

  String Function() draftNotesBuilder = () => '';
  String get _draftNotes => draftNotesBuilder();

  List<String> get releaseCreateCommand =>
      GhCommands.releaseCreate(tag ?? '', title: '$displayName ${tag ?? ''}', prerelease: next?.pre != null);

  /// 앱이 릴리스를 만드는 저장소 (CI가 만들지 않음).
  Future<CommandResult> createRelease(String body) async {
    final r = await repo.execute(releaseCreateCommand, stdin: body);
    if (!r.ok) return r;
    await _loadRelease();
    step = workflow == null ? ReleaseStep.done : ReleaseStep.ci;
    await _save();
    notifyListeners();
    return r;
  }

  /// CI가 만든 릴리스의 노트를 고친다.
  Future<CommandResult> editReleaseNotes(String body) async {
    final r = await repo.execute(GhCommands.releaseEditNotes(tag ?? ''), stdin: body);
    if (r.ok) await _loadRelease();
    notifyListeners();
    return r;
  }

  // --- ⑦ CI ---------------------------------------------------------------

  Future<void> _pollRun() async {
    final t = tag;
    if (t == null) return;
    if (run == null) {
      final r = await repo.read(GhCommands.runList(branch: t, limit: 1));
      final found = WorkflowRun.parseList(r.stdout).firstOrNull;
      if (found == null) return;
      await _loadRun(found.id);
      await _save();
    } else if (!run!.done) {
      await _loadRun(run!.id);
    }
    if (run != null && run!.done) {
      _finished(run, manualBuild: false);
      if (run!.state == RunState.success) {
        await _loadRelease();
        if (release != null || !ciMode) step = ReleaseStep.done;
        await _save();
      } else if (failedLog.isEmpty) {
        final log = await repo.read(GhCommands.runFailedLog(run!.id));
        final lines = log.stdout.trimRight().split('\n');
        failedLog = lines.skip(lines.length > 20 ? lines.length - 20 : 0).join('\n');
      }
    }
  }

  Future<void> _loadRun(int id) async {
    final v = await repo.read(GhCommands.runView(id));
    run = WorkflowRun.parse(v.stdout) ?? run;
  }

  Future<void> _loadRelease() async {
    final r = await repo.read(GhCommands.releaseView(tag ?? ''));
    release = r.ok ? GitHubRelease.parse(r.stdout) : null;
  }

  Future<CommandResult> rerunFailed() async {
    final id = run?.id;
    if (id == null) return const CommandResult(1, '', '');
    final r = await repo.execute(GhCommands.runRerunFailed(id));
    if (r.ok) {
      failedLog = '';
      await _loadRun(id);
      _schedulePoll();
    }
    notifyListeners();
    return r;
  }

  // --- 주기 확인 ----------------------------------------------------------

  /// PR 병합을 기다리거나 CI·수동 빌드가 도는 동안 15초마다 확인한다.
  void _schedulePoll() {
    _poll?.cancel();
    _poll = Timer.periodic(const Duration(seconds: 15), (_) => poll());
  }

  bool get _waiting =>
      (step == ReleaseStep.merge && !(pr?.merged ?? false)) ||
      step == ReleaseStep.ci ||
      (_buildRequested != null && !(buildRun?.done ?? false));

  /// 창이 활성화될 때도 부른다.
  Future<void> poll() async {
    if (_disposed) return;
    if (!_waiting) {
      _poll?.cancel();
      return;
    }
    if (_buildRequested != null && !(buildRun?.done ?? false)) await _pollManualBuild();
    if (step == ReleaseStep.merge) await refreshPr();
    if (step == ReleaseStep.ci) await _pollRun();
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _poll?.cancel();
    super.dispose();
  }
}
