import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../core/command_runner.dart';
import '../git/commands.dart';
import '../git/refs.dart';
import '../git/remotes.dart';
import '../git/status.dart';

/// 병합·rebase가 끝나지 않은 상태.
enum RepoOperation { none, merging, rebasing }

/// 저장소를 열지 못한 이유.
enum OpenFailure { notFound, notARepository }

/// 열린 저장소 하나의 상태와 동작. 동작은 모두 명령 하나(또는 몇 개)를
/// 실행하고 상태를 다시 읽는다.
class RepoController extends ChangeNotifier {
  RepoController._(this.runner, this.root, this.gitDir);

  final CommandRunner runner;

  /// 저장소 루트 (작업 트리 최상위).
  final String root;
  final String gitDir;

  RepoStatus status = const RepoStatus();
  List<Branch> branches = const [];
  List<Remote> remotes = const [];
  RepoOperation operation = RepoOperation.none;
  bool loaded = false;

  /// 지금 실행 중인 명령 (진행 표시줄·취소용).
  CancelToken? _running;
  bool get busy => _running != null;

  StreamSubscription<FileSystemEvent>? _watch;
  Timer? _debounce;
  Timer? _poll;
  Future<void>? _refreshing;
  bool _refreshAgain = false;
  bool _disposed = false;

  String get name => root.split(Platform.pathSeparator).where((s) => s.isNotEmpty).last;

  List<Branch> get localBranches => branches.where((b) => !b.remote).toList();
  List<Branch> get remoteBranches => branches.where((b) => b.remote).toList();

  Remote? get githubRemote {
    for (final r in remotes) {
      if (r.name == 'origin' && r.isGitHub) return r;
    }
    for (final r in remotes) {
      if (r.isGitHub) return r;
    }
    return null;
  }

  /// 호스팅 표시용: origin(없으면 첫 원격)의 호스팅.
  RemoteHost? get primaryHost {
    if (remotes.isEmpty) return null;
    final origin = remotes.where((r) => r.name == 'origin');
    return (origin.isEmpty ? remotes.first : origin.first).host;
  }

  /// 게시(Publish)할 때 쓸 원격: origin, 없으면 첫 원격.
  String? get defaultRemote {
    if (remotes.isEmpty) return null;
    return remotes.any((r) => r.name == 'origin') ? 'origin' : remotes.first.name;
  }

  /// [path] 또는 그 상위의 저장소를 연다.
  static Future<(RepoController?, OpenFailure?)> open(CommandRunner runner, String path) async {
    if (!Directory(path).existsSync()) return (null, OpenFailure.notFound);
    final top = await runner.run(GitCommands.topLevel, workingDirectory: path, quiet: true);
    if (!top.ok) return (null, OpenFailure.notARepository);
    final root = _nativePath(top.stdout.trim());
    final dir = await runner.run(GitCommands.gitDir, workingDirectory: root, quiet: true);
    final controller = RepoController._(runner, root, _nativePath(dir.stdout.trim()));
    await controller.refresh();
    controller._startWatching();
    return (controller, null);
  }

  /// Windows의 git은 `C:/a/b`로 돌려준다.
  static String _nativePath(String p) => Platform.isWindows ? p.replaceAll('/', r'\') : p;

  /// 상태를 다시 읽는다. 이미 읽는 중이면 그 작업이 한 번 더 돌도록 표시하고
  /// 끝날 때까지 기다린다 — 호출한 쪽은 항상 최신 상태를 본다.
  Future<void> refresh() {
    if (_disposed) return Future.value();
    final running = _refreshing;
    if (running != null) {
      _refreshAgain = true;
      return running;
    }
    return _refreshing = _refreshLoop().whenComplete(() => _refreshing = null);
  }

  Future<void> _refreshLoop() async {
    do {
      _refreshAgain = false;
      final results = await Future.wait([
        runner.run(GitCommands.status, workingDirectory: root, quiet: true),
        runner.run(GitCommands.branches, workingDirectory: root, quiet: true),
        runner.run(GitCommands.remotes, workingDirectory: root, quiet: true),
      ]);
      if (_disposed) return;
      if (results[0].ok) status = RepoStatus.parse(results[0].stdout);
      if (results[1].ok) branches = Branch.parse(results[1].stdout);
      if (results[2].ok) remotes = Remote.parse(results[2].stdout);
      operation = _readOperation();
      loaded = true;
      notifyListeners();
    } while (_refreshAgain && !_disposed);
  }

  RepoOperation _readOperation() {
    bool exists(String name) => FileSystemEntity.typeSync('$gitDir/$name') != FileSystemEntityType.notFound;
    if (exists('rebase-merge') || exists('rebase-apply')) return RepoOperation.rebasing;
    if (exists('MERGE_HEAD')) return RepoOperation.merging;
    return RepoOperation.none;
  }

  /// 명령을 실행하고 상태를 다시 읽는다. 한 번에 하나만 실행한다.
  Future<CommandResult> execute(List<String> args) async {
    if (busy) return const CommandResult(1, '', 'busy');
    final token = CancelToken();
    _running = token;
    notifyListeners();
    try {
      return await runner.run(args, workingDirectory: root, cancel: token);
    } finally {
      _running = null;
      await refresh();
    }
  }

  /// 여러 명령을 차례로 실행한다. 하나라도 실패하면 멈춘다.
  Future<CommandResult> executeAll(List<List<String>> commands) async {
    var last = const CommandResult(0, '', '');
    for (final c in commands) {
      last = await execute(c);
      if (!last.ok) break;
    }
    return last;
  }

  void cancel() => _running?.cancel();

  // --- 동작 ---------------------------------------------------------------

  Future<CommandResult> stage(FileChange f) => execute(GitCommands.stage(f.path));
  Future<CommandResult> unstage(FileChange f) => execute(GitCommands.unstage(f.path, unborn: status.unborn));
  Future<CommandResult> stageAll() => execute(GitCommands.stageAll);
  Future<CommandResult> unstageAll() => execute(GitCommands.unstageAll(unborn: status.unborn));

  Future<CommandResult> commit(String message, {bool stageAllFirst = false}) => executeAll([
        if (stageAllFirst) GitCommands.stageAll,
        GitCommands.commit(message),
      ]);

  Future<CommandResult> fetch({String? remote}) => execute(GitCommands.fetch(remote: remote));
  Future<CommandResult> pull(PullMode mode) => execute(GitCommands.pull(mode));

  /// 추적 브랜치가 없으면 게시한다.
  Future<CommandResult> push() {
    final head = status.head;
    if (head != null && !status.hasUpstream && defaultRemote != null) {
      return execute(GitCommands.publish(defaultRemote!, head));
    }
    return execute(GitCommands.push);
  }

  List<String> get pushCommand {
    final head = status.head;
    if (head != null && !status.hasUpstream && defaultRemote != null) {
      return GitCommands.publish(defaultRemote!, head);
    }
    return GitCommands.push;
  }

  bool get needsPublish => !status.detached && !status.hasUpstream && remotes.isNotEmpty;

  Future<CommandResult> switchTo(Branch b) {
    if (!b.remote) return execute(GitCommands.switchTo(b.name));
    // 같은 이름의 로컬 브랜치가 있으면 그쪽으로 전환한다.
    final local = localBranches.where((l) => l.name == b.shortName);
    if (local.isNotEmpty) return execute(GitCommands.switchTo(local.first.name));
    return execute(GitCommands.switchTrack(b.name));
  }

  Future<CommandResult> continueOperation() => execute(switch (operation) {
        RepoOperation.rebasing => GitCommands.rebaseContinue,
        _ => GitCommands.mergeContinue,
      });

  Future<CommandResult> abortOperation() => execute(switch (operation) {
        RepoOperation.rebasing => GitCommands.rebaseAbort,
        _ => GitCommands.mergeAbort,
      });

  // --- 새로 고침 감시 -----------------------------------------------------

  /// 편집기에서 저장하거나 터미널에서 커밋해도 바로 반영한다 (PLAN.md §5).
  /// macOS·Windows는 저장소 전체를 재귀로 감시하고, 재귀 감시가 없는
  /// Linux는 .git만 감시하면서 몇 초마다 확인한다.
  void _startWatching() {
    final recursive = !Platform.isLinux;
    try {
      final dir = Directory(recursive ? root : gitDir);
      _watch = dir.watch(recursive: recursive).listen(_onFsEvent, onError: (_) {});
    } on Object {
      // 감시가 안 되는 파일 시스템(네트워크 드라이브 등)은 주기 확인만 한다.
    }
    if (!recursive || _watch == null) {
      _poll = Timer.periodic(const Duration(seconds: 5), (_) => refresh());
    }
  }

  void _onFsEvent(FileSystemEvent e) {
    final p = e.path.replaceAll(r'\', '/');
    // git 내부의 잦은 쓰기와 잠금 파일은 무시한다.
    if (p.contains('/.git/objects/') || p.contains('/.git/logs/') || p.endsWith('.lock')) return;
    if (p.contains('/.dart_tool/') || p.contains('/node_modules/') || p.contains('/build/')) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!busy) refresh();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _watch?.cancel();
    _debounce?.cancel();
    _poll?.cancel();
    super.dispose();
  }
}
