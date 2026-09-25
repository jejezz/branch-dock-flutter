// v0.6.0: diff 보기, revert, cherry-pick, 진행 중 상태를 실제 git으로 확인한다.

import 'dart:io';

import 'package:branch_dock/core/command_log.dart';
import 'package:branch_dock/core/command_runner.dart';
import 'package:branch_dock/git/commands.dart';
import 'package:branch_dock/git/diff.dart';
import 'package:branch_dock/git/history.dart';
import 'package:branch_dock/repo/repo_controller.dart';
import 'package:flutter_test/flutter_test.dart';

late Directory tmp;

Future<void> git(String cwd, List<String> args) async {
  final r = await Process.run('git', args, workingDirectory: cwd);
  if (r.exitCode != 0) fail('git ${args.join(' ')}: ${r.stderr}');
}

Future<void> commitFile(String dir, String file, String content, String message) async {
  File('$dir/$file').writeAsStringSync(content);
  await git(dir, ['add', '-A']);
  await git(dir, ['commit', '-q', '-m', message]);
}

Future<RepoController> setUpRepo() async {
  final dir = '${tmp.path}/a';
  Directory(dir).createSync();
  await git(dir, ['init', '-q', '-b', 'main']);
  for (final c in [['user.email', 't@e.com'], ['user.name', 'T'], ['commit.gpgsign', 'false']]) {
    await git(dir, ['config', ...c]);
  }
  await commitFile(dir, 'f.txt', 'one\ntwo\nthree\n', 'chore: init');
  final runner = CommandRunner(log: CommandLog(), path: Platform.environment['PATH'] ?? '');
  final (repo, _) = await RepoController.open(runner, dir);
  return repo!;
}

void main() {
  setUp(() => tmp = Directory.systemTemp.createTempSync('bd_v6'));
  tearDown(() => tmp.deleteSync(recursive: true));

  test('parse unified diff with line numbers', () {
    const out = 'diff --git a/f b/f\nindex 1..2 100644\n--- a/f\n+++ b/f\n'
        '@@ -1,3 +1,3 @@ header\n one\n-two\n+TWO\n three\n\\ No newline at end of file\n';
    final d = FileDiff.parse(out);
    expect((d.added, d.removed, d.binary), (1, 1, false));
    expect(d.lines.map((l) => l.kind), [
      DiffLineKind.hunk, DiffLineKind.context, DiffLineKind.removed, DiffLineKind.added, DiffLineKind.context, DiffLineKind.meta,
    ]);
    expect((d.lines[2].oldNo, d.lines[3].newNo, d.lines[4].oldNo, d.lines[4].newNo), (2, 2, 3, 3));
    expect(FileDiff.parse('diff --git a/x b/x\nBinary files a/x and b/x differ\n').binary, isTrue);
    expect(FileDiff.parse('@@ -1 +1 @@\n${List.filled(50, '+x').join('\n')}', limit: 10).truncated, isTrue);
    expect(ChangedFile.parse('M\tf.txt\nR100\told.txt\tnew.txt\nA\tb.txt\n').map((f) => (f.status, f.path, f.oldPath)),
        [('M', 'f.txt', null), ('R', 'new.txt', 'old.txt'), ('A', 'b.txt', null)]);
  });

  test('diff of worktree, staged and untracked files', () async {
    final repo = await setUpRepo();
    File('${repo.root}/f.txt').writeAsStringSync('one\nTWO\nthree\n');
    File('${repo.root}/new.txt').writeAsStringSync('hello\n');
    final worktree = FileDiff.parse((await repo.read(GitCommands.diffWorktree('f.txt'))).stdout);
    expect((worktree.added, worktree.removed), (1, 1));
    // 추적 안 된 파일: 차이가 있으면 종료 코드 1이지만 출력은 있다.
    final untracked = await repo.read(GitCommands.diffUntracked('new.txt'));
    expect(FileDiff.parse(untracked.stdout).lines.last.text, 'hello');
    await git(repo.root, ['add', 'f.txt']);
    expect(FileDiff.parse((await repo.read(GitCommands.diffStaged('f.txt'))).stdout).added, 1);
    expect((await repo.read(GitCommands.diffWorktree('f.txt'))).stdout, isEmpty);
    repo.dispose();
  });

  test('commit files for root, normal and merge commits', () async {
    final repo = await setUpRepo();
    await git(repo.root, ['switch', '-q', '-c', 'b']);
    await commitFile(repo.root, 'b.txt', 'b\n', 'feat: b');
    await git(repo.root, ['switch', '-q', 'main']);
    await commitFile(repo.root, 'c.txt', 'c\n', 'feat: c');
    await git(repo.root, ['merge', '-q', '--no-ff', '-m', 'Merge b', 'b']);
    final log = LogEntry.parse((await repo.read(GitCommands.history())).stdout);
    final merge = log.first;
    expect(merge.isMerge, isTrue);
    final root = log.last;
    expect(root.parents, isEmpty);
    // 병합 커밋: 첫 부모와 비교하면 병합으로 들어온 b.txt
    final mergeFiles = ChangedFile.parse((await repo.read(GitCommands.commitFiles(merge.hash, parent: merge.parents.first))).stdout);
    expect(mergeFiles.map((f) => f.path), ['b.txt']);
    final rootFiles = ChangedFile.parse((await repo.read(GitCommands.commitFiles(root.hash))).stdout);
    expect(rootFiles.single.path, 'f.txt');
    final rootDiff = FileDiff.parse((await repo.read(GitCommands.commitFileDiff(root.hash, 'f.txt'))).stdout);
    expect(rootDiff.added, 3);
    // 다른 브랜치의 기록
    final other = LogEntry.parse((await repo.read(GitCommands.history(ref: 'b'))).stdout);
    expect(other.first.subject, 'feat: b');
    repo.dispose();
  });

  test('revert normal and merge commits', () async {
    final repo = await setUpRepo();
    await commitFile(repo.root, 'x.txt', 'x\n', 'feat: x');
    var log = LogEntry.parse((await repo.read(GitCommands.history())).stdout);
    expect((await repo.execute(GitCommands.revert(log.first.hash))).ok, isTrue);
    expect(File('${repo.root}/x.txt').existsSync(), isFalse);

    await git(repo.root, ['switch', '-q', '-c', 'b']);
    await commitFile(repo.root, 'b.txt', 'b\n', 'feat: b');
    await git(repo.root, ['switch', '-q', 'main']);
    await git(repo.root, ['merge', '-q', '--no-ff', '-m', 'Merge b', 'b']);
    log = LogEntry.parse((await repo.read(GitCommands.history())).stdout);
    // 병합 커밋은 -m 1이 없으면 실패한다.
    expect((await repo.execute(GitCommands.revert(log.first.hash, merge: log.first.isMerge))).ok, isTrue);
    expect(File('${repo.root}/b.txt').existsSync(), isFalse);
    repo.dispose();
  });

  test('cherry-pick, conflict state, abort', () async {
    final repo = await setUpRepo();
    await git(repo.root, ['switch', '-q', '-c', 'feat']);
    await commitFile(repo.root, 'n.txt', 'new\n', 'feat: n');
    await commitFile(repo.root, 'f.txt', 'one\nFEAT\nthree\n', 'feat: f');
    await git(repo.root, ['switch', '-q', 'main']);
    await commitFile(repo.root, 'f.txt', 'one\nMAIN\nthree\n', 'fix: f');
    await repo.refresh();
    final feat = LogEntry.parse((await repo.read(GitCommands.history(ref: 'feat'))).stdout);

    expect((await repo.execute(GitCommands.cherryPick(feat[1].hash))).ok, isTrue); // feat: n
    expect(File('${repo.root}/n.txt').existsSync(), isTrue);

    final conflict = await repo.execute(GitCommands.cherryPick(feat[0].hash)); // feat: f → 충돌
    expect(conflict.ok, isFalse);
    expect(repo.operation, RepoOperation.cherryPicking);
    expect(repo.skipCommand, GitCommands.cherryPickSkip);
    expect((await repo.abortOperation()).ok, isTrue);
    expect(repo.operation, RepoOperation.none);
    expect(File('${repo.root}/f.txt').readAsStringSync(), 'one\nMAIN\nthree\n');
    repo.dispose();
  });
}
