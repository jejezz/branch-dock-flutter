import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../core/command_runner.dart';
import '../git/commands.dart';
import '../git/refs.dart';
import '../git/remotes.dart';
import '../git/status.dart';
import '../git/tags.dart';

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
  List<Tag> tags = const [];

  /// 기본 원격에 있는 태그 이름. 네트워크를 쓰므로 [loadRemoteTags]로만 읽는다.
  Set<String>? remoteTagNames;

  /// 원격의 기본 브랜치 (`main`). 모르면 main → master → 현재 브랜치.
  String? defaultBranch;

  /// 현재 브랜치의 원격 브랜치가 사라졌고, 그 커밋이 이미 원격 기본 브랜치에
  /// 들어 있다 — PR이 병합되고 브랜치가 지워진 경우. 이때 게시하면 지운
  /// 브랜치가 다시 생기므로 게시 대신 기본 브랜치로 전환을 권한다.
  bool headMergedAndGone = false;
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
        runner.run(GitCommands.tags, workingDirectory: root, quiet: true),
      ]);
      if (_disposed) return;
      if (results[3].ok) tags = _withPushed(Tag.parse(results[3].stdout));
      if (results[0].ok) status = RepoStatus.parse(results[0].stdout);
      if (results[1].ok) branches = Branch.parse(results[1].stdout);
      if (results[2].ok) remotes = Remote.parse(results[2].stdout);
      operation = _readOperation();
      defaultBranch = await _readDefaultBranch();
      headMergedAndGone = await _readHeadMergedAndGone();
      loaded = true;
      notifyListeners();
    } while (_refreshAgain && !_disposed);
  }

  List<Tag> _withPushed(List<Tag> list) {
    final remote = remoteTagNames;
    return remote == null ? list : [for (final t in list) t.withPushed(remote.contains(t.name))];
  }

  /// `git ls-remote --tags` — 태그 탭을 열 때, 태그를 push·삭제한 뒤에 부른다.
  Future<void> loadRemoteTags() async {
    final remote = defaultRemote;
    if (remote == null) {
      remoteTagNames = {};
    } else {
      final r = await runner.run(GitCommands.remoteTags(remote), workingDirectory: root, quiet: true);
      if (!r.ok) return;
      remoteTagNames = Tag.parseRemote(r.stdout);
    }
    tags = _withPushed(tags);
    if (!_disposed) notifyListeners();
  }

  Future<String?> _readDefaultBranch() async {
    final remote = defaultRemote;
    if (remote != null) {
      final r = await runner.run(GitCommands.remoteHead(remote), workingDirectory: root, quiet: true);
      final v = r.stdout.trim();
      if (r.ok && v.startsWith('$remote/') && v != '$remote/HEAD') return v.substring(remote.length + 1);
    }
    final names = localBranches.map((b) => b.name).toSet();
    if (names.contains('main')) return 'main';
    if (names.contains('master')) return 'master';
    return status.head;
  }

  Future<bool> _readHeadMergedAndGone() async {
    final head = status.head;
    final remote = defaultRemote;
    final base = defaultBranch;
    if (!status.upstreamGone || head == null || remote == null || base == null || head == base) return false;
    final r = await runner.run(GitCommands.isAncestor('HEAD', '$remote/$base'), workingDirectory: root, quiet: true);
    return r.ok;
  }

  /// 기본 브랜치로 전환한다. 로컬에 없으면 원격 브랜치를 추적해 만든다.
  Future<CommandResult> switchToDefault() {
    final base = defaultBranch ?? 'main';
    final local = localBranches.where((b) => b.name == base);
    if (local.isNotEmpty) return switchTo(local.first);
    return execute(GitCommands.switchTrack('${defaultRemote ?? 'origin'}/$base'));
  }

  RepoOperation _readOperation() {
    bool exists(String name) => FileSystemEntity.typeSync('$gitDir/$name') != FileSystemEntityType.notFound;
    if (exists('rebase-merge') || exists('rebase-apply')) return RepoOperation.rebasing;
    if (exists('MERGE_HEAD')) return RepoOperation.merging;
    return RepoOperation.none;
  }

  /// 명령을 실행하고 상태를 다시 읽는다. 한 번에 하나만 실행한다.
  Future<CommandResult> execute(List<String> args, {String? stdin}) async {
    if (busy) return const CommandResult(1, '', 'busy');
    final token = CancelToken();
    _running = token;
    notifyListeners();
    try {
      return await runner.run(args, workingDirectory: root, cancel: token, stdin: stdin);
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

  Future<CommandResult> fetch({String? remote}) async {
    final r = await execute(GitCommands.fetch(remote: remote));
    if (r.ok && remoteTagNames != null) await loadRemoteTags();
    return r;
  }

  /// 읽기 전용 명령 (로그에 남기지 않음, 바쁨 표시 없음).
  Future<CommandResult> read(List<String> args) => runner.run(args, workingDirectory: root, quiet: true);
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

  bool get needsPublish => !status.detached && !status.hasUpstream && remotes.isNotEmpty && !headMergedAndGone;

  /// [switchTo]가 실행할 명령 (툴팁·미리 보기).
  List<String> switchCommand(Branch b) {
    if (!b.remote) return GitCommands.switchTo(b.name);
    final local = localBranches.where((l) => l.name == b.shortName);
    return local.isNotEmpty ? GitCommands.switchTo(local.first.name) : GitCommands.switchTrack(b.name);
  }

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
