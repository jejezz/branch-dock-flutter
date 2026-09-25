// v0.4.0 매일 쓰는 git 작업을 실제 git으로 확인한다.

import 'dart:io';

import 'package:branch_dock/core/command_log.dart';
import 'package:branch_dock/core/command_runner.dart';
import 'package:branch_dock/git/commands.dart';
import 'package:branch_dock/git/history.dart';
import 'package:branch_dock/repo/repo_controller.dart';
import 'package:flutter_test/flutter_test.dart';

late Directory tmp;
late CommandRunner runner;

Future<void> git(String cwd, List<String> args) async {
  final r = await Process.run('git', args, workingDirectory: cwd);
  if (r.exitCode != 0) fail('git ${args.join(' ')}: ${r.stderr}');
}

Future<void> commitFile(String dir, String file, String content, String message) async {
  File('$dir/$file').writeAsStringSync(content);
  await git(dir, ['add', '-A']);
  await git(dir, ['commit', '-q', '-m', message]);
}

Future<Directory> clone(String name) async {
  await git(tmp.path, ['clone', '-q', 'remote.git', name]);
  final dir = Directory('${tmp.path}/$name');
  for (final c in [
    ['user.email', 't@example.com'],
    ['user.name', 'Test'],
    ['commit.gpgsign', 'false'],
    ['tag.gpgsign', 'false'],
  ]) {
    await git(dir.path, ['config', ...c]);
  }
  return dir;
}

/// bare 원격 + 복제본 a (main에 커밋 하나, push됨).
Future<RepoController> setUpRepo() async {
  await git(tmp.path, ['init', '-q', '--bare', '-b', 'main', 'remote.git']);
  final a = await clone('a');
  await commitFile(a.path, 'f.txt', 'base\n', 'chore: init');
  await git(a.path, ['push', '-q', '-u', 'origin', 'main']);
  await git(a.path, ['remote', 'set-head', 'origin', 'main']);
  final (repo, _) = await RepoController.open(runner, a.path);
  return repo!;
}

void main() {
  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('branch_dock_v4');
    runner = CommandRunner(log: CommandLog(), path: Platform.environment['PATH'] ?? '');
  });
  tearDown(() => tmp.delete(recursive: true));

  test('parse history decorations and stash list', () {
    final log = LogEntry.parse('H1\x00h1\x00feat: a\x00HEAD -> main, tag: v1.0.0, origin/main, origin/HEAD\x001700000000\x00Me\x1e\n'
        'H2\x00h2\x00fix: b\x00\x001700000000\x00You\x1e');
    expect(log.first.isHead, isTrue);
    expect(log.first.branches, ['main', 'origin/main']);
    expect(log.first.tags, ['v1.0.0']);
    expect(log.last.branches, isEmpty);
    final stashes = Stash.parse('stash@{0}\x00On main: 실험 중\x001700000000\nstash@{1}\x00WIP on feat/x: abc123 feat: y\x001700000000\n');
    expect(stashes.map((s) => s.ref), ['stash@{0}', 'stash@{1}']);
    expect(stashes.first.parts, (branch: 'main', text: '실험 중'));
    expect(stashes.last.parts.branch, 'feat/x');
  });

  test('stash push, list, pop and drop', () async {
    final repo = await setUpRepo();
    File('${repo.root}/f.txt').writeAsStringSync('changed\n');
    File('${repo.root}/new.txt').writeAsStringSync('new\n');
    await repo.refresh();
    expect(repo.status.changedCount, 2);
    expect((await repo.execute(GitCommands.stashPush('실험 중'))).ok, isTrue);
    expect(repo.status.clean, isTrue); // 추적 안 된 파일도 함께 저장
    expect(repo.stashes.single.parts.text, '실험 중');
    expect((await repo.execute(GitCommands.stashPop(repo.stashes.single.ref))).ok, isTrue);
    expect(repo.status.changedCount, 2);
    expect(repo.stashes, isEmpty);
    await repo.execute(GitCommands.stashPush(''));
    await repo.execute(GitCommands.stashDrop(repo.stashes.single.ref));
    expect(repo.stashes, isEmpty);
    repo.dispose();
  });

  test('amend, discard, remove untracked', () async {
    final repo = await setUpRepo();
    File('${repo.root}/f.txt').writeAsStringSync('more\n');
    await repo.refresh();
    await repo.commit('feat: typo', stageAllFirst: true);
    File('${repo.root}/g.txt').writeAsStringSync('forgot\n');
    await repo.execute(GitCommands.stageAll);
    expect((await repo.execute(GitCommands.amend('feat: fixed'))).ok, isTrue);
    final subjects = (await repo.read(['git', 'log', '--format=%s'])).stdout.trim().split('\n');
    expect(subjects, ['feat: fixed', 'chore: init']); // 새 커밋이 아니라 고침
    expect(repo.status.ahead, 1);

    File('${repo.root}/f.txt').writeAsStringSync('oops\n');
    File('${repo.root}/junk.txt').writeAsStringSync('x\n');
    await repo.refresh();
    await repo.execute(GitCommands.discard('f.txt'));
    await repo.execute(GitCommands.removeUntracked('junk.txt'));
    expect(repo.status.clean, isTrue);
    expect(File('${repo.root}/f.txt').readAsStringSync(), 'more\n');
    repo.dispose();
  });

  test('force-with-lease refuses to overwrite commits you have not fetched', () async {
    final repo = await setUpRepo();
    await git(repo.root, ['switch', '-q', '-c', 'feat/x']);
    await commitFile(repo.root, 'x.txt', '1\n', 'feat: x');
    await repo.refresh();
    await repo.push();
    // 다른 사람이 같은 브랜치에 push
    final b = await clone('b');
    await git(b.path, ['switch', '-q', 'feat/x']);
    await commitFile(b.path, 'y.txt', '2\n', 'feat: y');
    await git(b.path, ['push', '-q']);
    // 나는 기록을 고쳐 강제 push — 아직 fetch하지 않았으므로 lease가 막는다
    await git(repo.root, ['commit', '-q', '--amend', '-m', 'feat: x2']);
    await repo.refresh();
    final forced = await repo.execute(GitCommands.forcePush('origin', 'feat/x'));
    expect(forced.ok, isFalse);
    expect(forced.combined, contains('stale info'));
    repo.dispose();
  });

  test('set upstream, cleanup candidates, detached switch, follow-tags', () async {
    final repo = await setUpRepo();
    await git(repo.root, ['switch', '-q', '-c', 'merged']);
    await commitFile(repo.root, 'm.txt', 'm\n', 'feat: m');
    await git(repo.root, ['push', '-q', '-u', 'origin', 'merged']);
    await git(repo.root, ['switch', '-q', 'main']);
    await git(repo.root, ['merge', '-q', '--no-ff', '-m', 'Merge m', 'merged']);
    await git(repo.root, ['push', '-q']);
    await git(repo.root, ['push', '-q', 'origin', '--delete', 'merged']);
    await git(repo.root, ['switch', '-q', '-c', 'wip']);
    await commitFile(repo.root, 'w.txt', 'w\n', 'feat: w');
    await git(repo.root, ['switch', '-q', 'main']);
    await repo.fetch();

    final candidates = await repo.cleanupCandidates();
    expect(candidates.map((c) => c.branch.name), ['merged']);
    expect(candidates.single.merged, isTrue);

    // wip의 추적 브랜치를 origin/main으로
    expect((await repo.execute(GitCommands.setUpstream('wip', 'origin/main'))).ok, isTrue);
    expect(repo.localBranches.firstWhere((b) => b.name == 'wip').upstream, 'origin/main');

    await repo.execute(GitCommands.createTag('v1.0.0', message: 'X 1.0.0'));
    expect((await repo.execute(GitCommands.switchDetach('v1.0.0'))).ok, isTrue);
    expect(repo.status.detached, isTrue);
    await repo.execute(GitCommands.switchTo('main'));

    expect(repo.pushCommandWith(followTags: true), ['git', 'push', '--follow-tags']);
    await commitFile(repo.root, 'n.txt', 'n\n', 'feat: n');
    await repo.execute(GitCommands.createTag('v1.1.0', message: 'X 1.1.0'));
    await repo.refresh();
    expect((await repo.push(followTags: true)).ok, isTrue);
    await repo.loadRemoteTags();
    expect(repo.remoteTagNames, contains('v1.1.0'));
    repo.dispose();
  });

  test('conflict sides and rebase skip', () async {
    final repo = await setUpRepo();
    await git(repo.root, ['switch', '-q', '-c', 'other']);
    await commitFile(repo.root, 'f.txt', 'theirs\n', 'feat: other');
    await git(repo.root, ['switch', '-q', 'main']);
    await commitFile(repo.root, 'f.txt', 'mine\n', 'feat: main');
    await repo.refresh();

    // 병합 충돌: ours = 현재 브랜치(main)
    await repo.execute(['git', 'merge', 'other']);
    expect(repo.operation, RepoOperation.merging);
    await repo.execute(GitCommands.checkoutSide('f.txt', ours: false));
    expect(File('${repo.root}/f.txt').readAsStringSync(), 'theirs\n');
    await repo.abortOperation();

    // rebase 충돌을 건너뛰면 그 커밋은 빠진다.
    await repo.execute(['git', 'rebase', 'other']);
    expect(repo.operation, RepoOperation.rebasing);
    expect((await repo.execute(GitCommands.rebaseSkip)).ok, isTrue);
    expect(repo.operation, RepoOperation.none);
    expect(File('${repo.root}/f.txt').readAsStringSync(), 'theirs\n');
    repo.dispose();
  });

  test('background fetch is quiet and throttled', () async {
    final repo = await setUpRepo();
    final b = await clone('b');
    await commitFile(b.path, 'z.txt', 'z\n', 'feat: z');
    await git(b.path, ['push', '-q']);
    final before = runner.log.entries.length;
    await repo.backgroundFetch(minInterval: Duration.zero);
    expect(repo.status.behind, 1);
    expect(runner.log.entries.length, before); // 기록에 남기지 않는다
    final last = repo.lastFetch;
    await repo.backgroundFetch();
    expect(repo.lastFetch, last); // 1분 안에는 다시 하지 않는다
    repo.dispose();
  });
}
