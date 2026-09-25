// RepoController를 실제 git으로 확인한다: 임시 폴더에 bare 원격과 복제본
// 두 개를 만들고 커밋 → 게시 → push 거부 → pull → 브랜치 → 원격 흐름을 돌린다.
// GitHub에는 접속하지 않는다 (PLAN.md §5 테스트).

import 'dart:io';

import 'package:branch_dock/core/command_log.dart';
import 'package:branch_dock/core/command_runner.dart';
import 'package:branch_dock/git/commands.dart';
import 'package:branch_dock/git/error_hints.dart';
import 'package:branch_dock/repo/repo_controller.dart';
import 'package:flutter_test/flutter_test.dart';

late Directory tmp;
late CommandRunner runner;

Future<void> git(String cwd, List<String> args) async {
  final r = await Process.run('git', args, workingDirectory: cwd);
  if (r.exitCode != 0) fail('git ${args.join(' ')}: ${r.stderr}');
}

Future<Directory> clone(String name) async {
  await git(tmp.path, ['clone', '-q', 'remote.git', name]);
  final dir = Directory('${tmp.path}/$name');
  await git(dir.path, ['config', 'user.email', 't@example.com']);
  await git(dir.path, ['config', 'user.name', 'Test']);
  await git(dir.path, ['config', 'commit.gpgsign', 'false']);
  return dir;
}

Future<RepoController> open(Directory dir) async {
  final (repo, failure) = await RepoController.open(runner, dir.path);
  expect(failure, isNull);
  return repo!;
}

void main() {
  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('branch_dock_test');
    runner = CommandRunner(log: CommandLog(), path: Platform.environment['PATH'] ?? '');
    await git(tmp.path, ['init', '-q', '--bare', '-b', 'main', 'remote.git']);
  });

  tearDown(() async {
    await tmp.delete(recursive: true);
  });

  test('not a repository', () async {
    final (repo, failure) = await RepoController.open(runner, tmp.path);
    expect(repo, isNull);
    expect(failure, OpenFailure.notARepository);
  });

  test('commit, publish, rejected push, pull, push', () async {
    final a = await clone('a');
    final repoA = await open(a);
    expect(repoA.status.unborn, isTrue);

    File('${a.path}/readme.md').writeAsStringSync('hello\n');
    await repoA.refresh();
    expect(repoA.status.untracked.single.path, 'readme.md');

    // 스테이징된 것이 없으면 모두 스테이징하고 커밋한다.
    final first = await repoA.commit('feat: first', stageAllFirst: true);
    expect(first.ok, isTrue, reason: first.combined);
    expect(repoA.status.clean, isTrue);
    expect(repoA.needsPublish, isTrue);
    expect(repoA.pushCommand, GitCommands.publish('origin', 'main'));

    expect((await repoA.push()).ok, isTrue);
    expect(repoA.status.upstream, 'origin/main');
    expect(repoA.status.ahead, 0);

    // 다른 복제본이 먼저 push하면 A의 push는 거부된다.
    final b = await clone('b');
    File('${b.path}/b.txt').writeAsStringSync('b\n');
    await git(b.path, ['add', '-A']);
    await git(b.path, ['commit', '-q', '-m', 'from b']);
    await git(b.path, ['push', '-q']);

    File('${a.path}/a.txt').writeAsStringSync('a\n');
    await repoA.refresh();
    await repoA.stage(repoA.status.untracked.single);
    expect(repoA.status.staged.single.path, 'a.txt');
    await repoA.unstage(repoA.status.staged.single);
    expect(repoA.status.untracked.single.path, 'a.txt');
    await repoA.commit('feat: a', stageAllFirst: true);
    expect(repoA.status.ahead, 1);

    final rejected = await repoA.push();
    expect(rejected.ok, isFalse);
    expect(classifyError(rejected.combined), GitErrorKind.pushRejected);

    // fetch 후에는 ↓1, 갈라졌으니 fast-forward만은 실패, 병합은 성공.
    await repoA.fetch();
    expect((repoA.status.ahead, repoA.status.behind), (1, 1));
    final ff = await repoA.pull(PullMode.fastForwardOnly);
    expect(ff.ok, isFalse);
    expect(classifyError(ff.combined), GitErrorKind.notFastForward);
    expect((await repoA.pull(PullMode.merge)).ok, isTrue);
    expect(repoA.status.behind, 0);
    expect((await repoA.push()).ok, isTrue);
    expect(repoA.status.ahead, 0);

    // 명령 로그에 사용자가 실행한 명령이 남는다 (상태 읽기는 남기지 않는다).
    expect(runner.log.entries.map((e) => e.args[1]), containsAllInOrder(['add', 'commit', 'push', 'fetch', 'pull']));
    expect(runner.log.entries.any((e) => e.args.contains('status')), isFalse);
    repoA.dispose();
  });

  test('branches: create, switch, rename, delete, remote track and delete', () async {
    final a = await clone('a');
    File('${a.path}/x').writeAsStringSync('x\n');
    await git(a.path, ['add', '-A']);
    await git(a.path, ['commit', '-q', '-m', 'init']);
    await git(a.path, ['push', '-q', '-u', 'origin', 'main']);
    final repo = await open(a);

    expect((await repo.execute(GitCommands.createBranch('feature/x'))).ok, isTrue);
    expect(repo.status.head, 'feature/x');
    expect(repo.localBranches.map((b) => b.name), containsAll(['main', 'feature/x']));

    // 새 브랜치에 커밋하고 게시.
    File('${a.path}/y').writeAsStringSync('y\n');
    await repo.commit('feat: y', stageAllFirst: true);
    expect((await repo.push()).ok, isTrue);
    expect(repo.remoteBranches.map((b) => b.name), contains('origin/feature/x'));

    // 어디에도 병합되지 않은 브랜치는 -d로 지울 수 없다 (upstream에 올린 것은 지워진다).
    await repo.execute(GitCommands.createBranch('local-only'));
    File('${a.path}/z').writeAsStringSync('z\n');
    await repo.commit('feat: z', stageAllFirst: true);
    await repo.switchTo(repo.localBranches.firstWhere((b) => b.name == 'main'));
    final notMerged = await repo.execute(GitCommands.deleteBranch('local-only'));
    expect(classifyError(notMerged.combined), GitErrorKind.branchNotMerged);
    expect((await repo.execute(GitCommands.deleteBranch('local-only', force: true))).ok, isTrue);

    // 원격 브랜치를 고르면 같은 이름의 로컬 브랜치로 전환한다.
    await repo.execute(GitCommands.renameBranch('feature/x', 'feature/y'));
    expect(repo.localBranches.map((b) => b.name), contains('feature/y'));
    await repo.execute(GitCommands.deleteBranch('feature/y', force: true));
    final remoteX = repo.remoteBranches.firstWhere((b) => b.name == 'origin/feature/x');
    expect((await repo.switchTo(remoteX)).ok, isTrue);
    expect(repo.status.head, 'feature/x');
    expect(repo.status.upstream, 'origin/feature/x');

    await repo.switchTo(repo.localBranches.firstWhere((b) => b.name == 'main'));
    expect((await repo.execute(GitCommands.deleteRemoteBranch('origin', 'feature/x'))).ok, isTrue);
    await repo.fetch();
    final gone = repo.localBranches.firstWhere((b) => b.name == 'feature/x');
    expect(gone.upstreamGone, isTrue);
    repo.dispose();
  });

  test('remotes: add, rename, set-url, remove', () async {
    final a = await clone('a');
    final repo = await open(a);
    expect(repo.remotes.single.name, 'origin');
    await repo.execute(GitCommands.remoteAdd('lab', 'git@gitlab.com:me/x.git'));
    expect(repo.remotes.map((r) => r.name), ['lab', 'origin']..sort());
    await repo.execute(GitCommands.remoteRename('lab', 'gitlab'));
    await repo.execute(GitCommands.remoteSetUrl('gitlab', 'https://gitlab.com/me/x.git'));
    final lab = repo.remotes.firstWhere((r) => r.name == 'gitlab');
    expect(lab.fetchUrl, 'https://gitlab.com/me/x.git');
    await repo.execute(GitCommands.remoteRemove('gitlab'));
    expect(repo.remotes.single.name, 'origin');
    repo.dispose();
  });

  test('merge conflict state, abort', () async {
    final a = await clone('a');
    File('${a.path}/f').writeAsStringSync('base\n');
    await git(a.path, ['add', '-A']);
    await git(a.path, ['commit', '-q', '-m', 'base']);
    await git(a.path, ['switch', '-q', '-c', 'other']);
    File('${a.path}/f').writeAsStringSync('other\n');
    await git(a.path, ['commit', '-q', '-am', 'other']);
    await git(a.path, ['switch', '-q', 'main']);
    File('${a.path}/f').writeAsStringSync('main\n');
    await git(a.path, ['commit', '-q', '-am', 'main']);
    final repo = await open(a);

    final merge = await repo.execute(['git', 'merge', 'other']);
    expect(merge.ok, isFalse);
    expect(classifyError(merge.combined), GitErrorKind.conflict);
    expect(repo.operation, RepoOperation.merging);
    expect(repo.status.conflicts.single.path, 'f');

    expect((await repo.abortOperation()).ok, isTrue);
    expect(repo.operation, RepoOperation.none);
    expect(repo.status.clean, isTrue);
    repo.dispose();
  });

  // v0.2.0 릴리스 때 발견: PR이 병합되고 원격 브랜치가 지워진 뒤에도
  // "게시"를 권했다. 게시하면 지운 브랜치가 되살아난다.
  test('merged and deleted branch: suggest switching back, not publishing', () async {
    final a = await clone('a');
    File('${a.path}/x').writeAsStringSync('x\n');
    await git(a.path, ['add', '-A']);
    await git(a.path, ['commit', '-q', '-m', 'init']);
    await git(a.path, ['push', '-q', '-u', 'origin', 'main']);
    await git(a.path, ['switch', '-q', '-c', 'feat/x']);
    File('${a.path}/y').writeAsStringSync('y\n');
    await git(a.path, ['add', '-A']);
    await git(a.path, ['commit', '-q', '-m', 'feat: y']);
    await git(a.path, ['push', '-q', '-u', 'origin', 'feat/x']);

    // GitHub에서 PR 병합(병합 커밋) + 브랜치 삭제를 다른 복제본으로 흉내 낸다.
    final b = await clone('b');
    await git(b.path, ['merge', '-q', '--no-ff', '-m', 'Merge pull request #1', 'origin/feat/x']);
    await git(b.path, ['push', '-q', 'origin', 'main']);
    await git(b.path, ['push', '-q', 'origin', '--delete', 'feat/x']);

    final repo = await open(a);
    await repo.fetch();
    expect(repo.status.head, 'feat/x');
    expect(repo.status.upstreamGone, isTrue);
    expect(repo.headMergedAndGone, isTrue);
    expect(repo.needsPublish, isFalse);

    expect((await repo.switchToDefault()).ok, isTrue);
    expect(repo.status.head, 'main');
    expect(repo.headMergedAndGone, isFalse);
    repo.dispose();
  });

  test('unmerged branch whose upstream is gone still suggests publishing', () async {
    final a = await clone('a');
    File('${a.path}/x').writeAsStringSync('x\n');
    await git(a.path, ['add', '-A']);
    await git(a.path, ['commit', '-q', '-m', 'init']);
    await git(a.path, ['push', '-q', '-u', 'origin', 'main']);
    await git(a.path, ['switch', '-q', '-c', 'feat/z']);
    File('${a.path}/z').writeAsStringSync('z\n');
    await git(a.path, ['add', '-A']);
    await git(a.path, ['commit', '-q', '-m', 'feat: z']);
    await git(a.path, ['push', '-q', '-u', 'origin', 'feat/z']);
    await git(a.path, ['push', '-q', 'origin', '--delete', 'feat/z']);
    final repo = await open(a);
    await repo.fetch();
    expect(repo.status.upstreamGone, isTrue);
    expect(repo.headMergedAndGone, isFalse);
    expect(repo.needsPublish, isTrue);
    repo.dispose();
  });
}
