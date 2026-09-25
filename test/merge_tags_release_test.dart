// 병합·태그·릴리스 마법사의 로컬 단계를 실제 git으로 확인한다.
// gh가 필요한 단계(PR, 병합, CI)는 GitHub에 접속해야 해서 여기서 다루지 않는다.

import 'dart:io';

import 'package:branch_dock/core/command_log.dart';
import 'package:branch_dock/core/command_runner.dart';
import 'package:branch_dock/git/commands.dart';
import 'package:branch_dock/git/commits.dart';
import 'package:branch_dock/git/tags.dart';
import 'package:branch_dock/release/release_flow.dart';
import 'package:branch_dock/release/version_files.dart';
import 'package:branch_dock/repo/repo_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

/// bare 원격과 main에 커밋 하나가 있는 복제본.
Future<RepoController> setUpRepo({String pubspec = 'name: x\nversion: 0.1.0+3\n'}) async {
  await git(tmp.path, ['init', '-q', '--bare', '-b', 'main', 'remote.git']);
  await git(tmp.path, ['clone', '-q', 'remote.git', 'a']);
  final dir = '${tmp.path}/a';
  for (final c in [
    ['user.email', 't@example.com'],
    ['user.name', 'Test'],
    ['commit.gpgsign', 'false'],
    ['tag.gpgsign', 'false'],
  ]) {
    await git(dir, ['config', ...c]);
  }
  await commitFile(dir, 'pubspec.yaml', pubspec, 'chore: init');
  await git(dir, ['push', '-q', '-u', 'origin', 'main']);
  await git(tmp.path, ['--git-dir=remote.git', 'symbolic-ref', 'HEAD', 'refs/heads/main']);
  await git(dir, ['remote', 'set-head', 'origin', '--auto']);
  final (repo, _) = await RepoController.open(runner, dir);
  return repo!;
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tmp = await Directory.systemTemp.createTemp('branch_dock_v2');
    runner = CommandRunner(log: CommandLog(), path: Platform.environment['PATH'] ?? '');
  });

  tearDown(() => tmp.delete(recursive: true));

  test('merge: fast-forward, merge commit, squash', () async {
    final repo = await setUpRepo();
    final dir = repo.root;
    expect(repo.defaultBranch, 'main');

    // fast-forward: main이 feature의 조상.
    await git(dir, ['switch', '-q', '-c', 'feature']);
    await commitFile(dir, 'a.txt', 'a\n', 'feat: a');
    await git(dir, ['switch', '-q', 'main']);
    await repo.refresh();
    expect((await repo.read(GitCommands.isAncestor('HEAD', 'feature'))).ok, isTrue);
    final incoming = Commit.parse((await repo.read(GitCommands.incoming('feature'))).stdout);
    expect(incoming.single.subject, 'feat: a');
    expect((await repo.executeAll(GitCommands.merge('feature', MergeMode.fastForward))).ok, isTrue);
    expect(File('$dir/a.txt').existsSync(), isTrue);

    // 병합 커밋: 양쪽에 새 커밋 → fast-forward 불가.
    await git(dir, ['switch', '-q', '-c', 'feature2']);
    await commitFile(dir, 'b.txt', 'b\n', 'feat: b');
    await git(dir, ['switch', '-q', 'main']);
    await commitFile(dir, 'c.txt', 'c\n', 'fix: c');
    await repo.refresh();
    expect((await repo.read(GitCommands.isAncestor('HEAD', 'feature2'))).ok, isFalse);
    expect((await repo.executeAll(GitCommands.merge('feature2', MergeMode.mergeCommit, message: 'Merge feature2'))).ok,
        isTrue);
    final head = Commit.parse((await repo.read(GitCommands.log(until: 'HEAD'))).stdout).first;
    expect(head.subject, 'Merge feature2');

    // squash: 커밋 둘이 하나로.
    await git(dir, ['switch', '-q', '-c', 'feature3']);
    await commitFile(dir, 'd.txt', 'd\n', 'wip 1');
    await commitFile(dir, 'd.txt', 'd2\n', 'wip 2');
    await git(dir, ['switch', '-q', 'main']);
    await repo.refresh();
    expect((await repo.executeAll(GitCommands.merge('feature3', MergeMode.squash, message: 'feat: d'))).ok, isTrue);
    final log = Commit.parse((await repo.read(GitCommands.log(until: 'HEAD'))).stdout);
    expect(log.first.subject, 'feat: d');
    expect(log.where((c) => c.subject.startsWith('wip')), isEmpty);
    expect(repo.status.clean, isTrue);
    repo.dispose();
  });

  test('tags: create annotated and lightweight, push, remote state, delete', () async {
    final repo = await setUpRepo();
    await repo.executeAll([GitCommands.createTag('v0.1.0', message: 'X 0.1.0'), GitCommands.createTag('light')]);
    expect(repo.tags.map((t) => t.name), ['v0.1.0', 'light']);
    expect(repo.tags.first.annotated, isTrue);
    expect(repo.tags.last.annotated, isFalse);

    await repo.loadRemoteTags();
    expect(repo.tags.any((t) => t.pushed), isFalse);
    await repo.execute(GitCommands.pushTags('origin', ['v0.1.0']));
    await repo.loadRemoteTags();
    expect(repo.tags.firstWhere((t) => t.name == 'v0.1.0').pushed, isTrue);
    expect(repo.tags.firstWhere((t) => t.name == 'light').pushed, isFalse);

    await repo.execute(GitCommands.deleteRemoteTag('origin', 'v0.1.0'));
    await repo.execute(GitCommands.deleteTag('light'));
    await repo.loadRemoteTags();
    expect(repo.tags.map((t) => t.name), ['v0.1.0']);
    expect(repo.tags.single.pushed, isFalse);
    repo.dispose();
  });

  test('release flow: checks, version suggestion, release branch and bump commit', () async {
    final repo = await setUpRepo();
    final dir = repo.root;
    await repo.execute(GitCommands.createTag('v0.1.0', message: 'X 0.1.0'));
    await repo.execute(GitCommands.pushTags('origin', ['v0.1.0']));
    await commitFile(dir, 'a.txt', 'a\n', 'feat: 태그 탭');
    await commitFile(dir, 'b.txt', 'b\n', 'fix: 정렬');
    await git(dir, ['push', '-q']);
    await repo.refresh();

    final flow = ReleaseFlow(repo, ghReady: false);
    await flow.runChecks();
    expect(flow.lastTag, 'v0.1.0');
    expect(flow.releaseCommits.map((c) => c.subject), ['fix: 정렬', 'feat: 태그 탭']);
    expect(flow.checks[ReleaseCheck.cleanTree], isTrue);
    expect(flow.checks[ReleaseCheck.onDefaultBranch], isTrue);
    expect(flow.checks[ReleaseCheck.synced], isTrue);
    expect(flow.checks[ReleaseCheck.hasChanges], isTrue);
    // GitHub 원격이 아니고 gh도 없음 → 마법사를 진행할 수 없다.
    expect(flow.checks[ReleaseCheck.github], isFalse);
    expect(flow.checksPassed, isFalse);
    expect(flow.files.single.path, 'pubspec.yaml');

    // feat가 있으니 minor 추천, build +1.
    flow.proceedToVersion();
    expect(flow.next.toString(), '0.2.0+4');
    expect(flow.fileChanges.single, ('pubspec.yaml', '0.1.0+3', '0.2.0+4'));
    expect(flow.releaseBranch, 'release/v0.2.0');

    expect((await flow.createReleaseCommit()).ok, isTrue);
    expect(repo.status.head, 'release/v0.2.0');
    expect(readVersion(VersionFileKind.pubspec, File('$dir/pubspec.yaml').readAsStringSync()).toString(), '0.2.0+4');
    final last = Commit.parse((await repo.read(GitCommands.log(until: 'HEAD'))).stdout).first;
    expect(last.subject, 'chore(release): v0.2.0');
    expect(flow.step, ReleaseStep.pr);
    expect(flow.tagMessage, 'a 0.2.0'); // 표시 이름이 없으면 저장소 이름
    expect(flow.tagCommands.first, ['git', 'tag', '-a', 'v0.2.0', '-m', 'a 0.2.0']);

    // 진행 상태가 저장되어 다시 열면 이어서 한다.
    final again = ReleaseFlow(repo, ghReady: false);
    expect(await again.resume(), isTrue);
    expect((again.step, again.next.toString()), (ReleaseStep.pr, '0.2.0+4'));
    await again.cancel();
    expect(await ReleaseFlow(repo, ghReady: false).resume(), isFalse);

    flow.dispose();
    again.dispose();
    repo.dispose();
  });

  test('tag checks: version must match on the default branch', () async {
    final repo = await setUpRepo();
    final flow = ReleaseFlow(repo, ghReady: false);
    await flow.runChecks();
    flow.chooseVersion(SemVer.tryParse('0.2.0+4')!);
    await flow.runTagChecks();
    // 버전 올림이 main에 없으면 태그 버튼이 켜지지 않는다.
    expect(flow.tagChecks[TagCheck.versionMatches], isFalse);
    expect(flow.defaultBranchVersion, '0.1.0');
    expect(flow.tagChecks[TagCheck.prMerged], isFalse);
    expect(flow.tagChecks[TagCheck.synced], isTrue);
    expect(flow.tagChecks[TagCheck.tagFree], isTrue);
    expect(flow.tagChecksPassed, isFalse);
    flow.dispose();
    repo.dispose();
  });
}
