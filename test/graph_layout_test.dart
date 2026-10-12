// 커밋 그래프 배치: 손으로 만든 기록과 실제 git 기록으로 확인한다.

import 'dart:io';

import 'package:branch_dock/git/commands.dart';
import 'package:branch_dock/git/graph_layout.dart';
import 'package:branch_dock/git/history.dart';
import 'package:flutter_test/flutter_test.dart';

LogEntry c(String hash, [List<String> parents = const []]) =>
    LogEntry(hash: hash, shortHash: hash, subject: hash, parents: parents);

/// 이어지는 두 행은 같은 줄에서 만나야 한다: 위 행이 아래로 내보낸 줄 = 아래 행이 위에서 받는 줄.
void expectConnected(CommitGraphLayout g) {
  for (var i = 0; i + 1 < g.rows.length; i++) {
    final a = g.rows[i];
    final b = g.rows[i + 1];
    final out = {...a.through, for (final s in a.bottom) s.to, for (final s in a.shifts) s.to};
    final into = {...b.through, for (final s in b.top) s.from, for (final s in b.shifts) s.from};
    expect(into, out, reason: 'row $i → ${i + 1}: out=$out into=$into');
  }
  for (final r in g.rows) {
    for (final s in [...r.top, ...r.bottom, ...r.shifts]) {
      expect(s.from < g.laneCount && s.to < g.laneCount, isTrue);
    }
    expect(r.lane < g.laneCount, isTrue);
  }
}

String shape(CommitGraphLayout g) => g.rows.map((r) => '${r.lane}${r.top}${r.through}${r.bottom}').join(' | ');

void main() {
  test('a straight history stays in one lane', () {
    final g = CommitGraphLayout.of([c('c3', ['c2']), c('c2', ['c1']), c('c1')]);
    expect(g.rows.map((r) => r.lane), [0, 0, 0]);
    expect(g.laneCount, 1);
    expect(g.rows.first.top, isEmpty); // 맨 위는 새 끝
    expect(g.rows.last.bottom, isEmpty); // 첫 커밋
    expectConnected(g);
  });

  test('a branch and its merge use two lanes and rejoin', () {
    // M(A, B)  A(R)  B(R)  R
    final g = CommitGraphLayout.of([c('M', ['A', 'B']), c('A', ['R']), c('B', ['R']), c('R')]);
    expect(g.rows.map((r) => r.lane), [0, 0, 1, 0]);
    expect(g.laneCount, 2);
    expect(g.rows[0].bottom.map((s) => '${s.from}→${s.to}'), ['0→0', '0→1']);
    expect(g.rows[2].bottom.map((s) => '${s.from}→${s.to}'), ['1→0']); // B는 이미 기다리는 R로 합쳐진다
    expect(g.rows[3].top.map((s) => '${s.from}→${s.to}'), ['0→0']);
    expectConnected(g);
  });

  test('the trunk stays on the left: a branch waiting for the trunk\'s parent is pulled over to it', () {
    // release → M(hotfix, ff) ; ff → fs → base ; hotfix → base ; base → init
    final g = CommitGraphLayout.of([
      c('release', ['M']),
      c('M', ['hotfix', 'ff']),
      c('ff', ['fs']),
      c('fs', ['base']),
      c('hotfix', ['base']),
      c('base', ['init']),
      c('init'),
    ]);
    // 줄기(release, M, hotfix, base, init)는 모두 0번 줄, 브랜치(ff, fs)는 1번 줄.
    expect(g.rows.map((r) => r.lane), [0, 0, 1, 1, 0, 0, 0]);
    final hotfix = g.rows[4];
    expect(hotfix.shifts.map((s) => '${s.from}→${s.to}'), ['1→0']); // fs가 기다리던 base를 줄기로 끌어온다
    expect(hotfix.bottom.map((s) => '${s.from}→${s.to}'), ['0→0']);
    expect(hotfix.through, isEmpty);
    expect(g.laneCount, 2);
    expectConnected(g);
  });

  test('two branch tips that share a parent join below', () {
    final g = CommitGraphLayout.of([c('X', ['R']), c('Y', ['R']), c('R')]);
    expect(g.rows.map((r) => r.lane), [0, 1, 0]);
    // Y의 부모 R을 이미 0번 줄이 기다리므로, Y의 선은 자기 행에서 바로 0번 줄로 합쳐진다.
    expect(g.rows[1].bottom.map((s) => '${s.from}→${s.to}'), ['1→0']);
    expect(g.rows[2].top.map((s) => '${s.from}→${s.to}'), ['0→0']);
    expectConnected(g);
  });

  test('an octopus merge fans out to every parent', () {
    final g = CommitGraphLayout.of([
      c('M', ['A', 'B', 'C']),
      c('A', ['R']),
      c('B', ['R']),
      c('C', ['R']),
      c('R'),
    ]);
    expect(g.rows.first.bottom.length, 3);
    expect(g.laneCount, 3);
    expectConnected(g);
  });

  test('lanes are reused once a branch ends', () {
    // 왼쪽 줄이 끝나면 새 끝이 그 자리를 쓴다.
    final g = CommitGraphLayout.of([c('A', ['B']), c('B'), c('C', ['D']), c('D')]);
    expect(g.rows.map((r) => r.lane), [0, 0, 0, 0]);
    expect(g.laneCount, 1);
  });

  test('a parent outside the list (history cut off) just keeps its line going', () {
    final g = CommitGraphLayout.of([c('A', ['gone']), c('B', ['gone2'])]);
    expect(g.rows.last.through, [0]);
    expect(g.rows.length, 2);
  });

  test('empty list', () {
    final g = CommitGraphLayout.of(const []);
    expect(g.rows, isEmpty);
    expect(g.laneCount, 1);
  });

  group('with a real repository', () {
    late Directory tmp;
    late String dir;
    var n = 0;

    Future<String> git(List<String> args) async {
      final r = await Process.run('git', args, workingDirectory: dir);
      if (r.exitCode != 0) fail('git ${args.join(' ')}: ${r.stderr}');
      return (r.stdout as String).trim();
    }

    Future<void> commit() async {
      n++;
      File('$dir/f$n.txt').writeAsStringSync('$n\n');
      await git(['add', '-A']);
      await git(['commit', '-q', '-m', 'c$n']);
    }

    setUp(() async {
      tmp = Directory.systemTemp.createTempSync('bd_graph');
      dir = '${tmp.path}/repo';
      Directory(dir).createSync();
      n = 0;
      await git(['init', '-q', '-b', 'main']);
      for (final cfg in [['user.email', 't@e.com'], ['user.name', 'T'], ['commit.gpgsign', 'false']]) {
        await git(['config', ...cfg]);
      }
    });
    tearDown(() => tmp.deleteSync(recursive: true));

    Future<CommitGraphLayout> layoutOf({bool all = false}) async {
      final out = await git(GitCommands.history(all: all, topo: true).sublist(1));
      final entries = LogEntry.parse(out);
      return CommitGraphLayout.of(entries);
    }

    test('branches, merges, an octopus and a long-lived side branch stay connected', () async {
      await commit();
      await commit();
      await git(['switch', '-q', '-c', 'feature']);
      await commit();
      await commit();
      await git(['switch', '-q', 'main']);
      await commit();
      await git(['merge', '-q', '--no-ff', '-m', 'merge feature', 'feature']);
      await git(['switch', '-q', '-c', 'side', 'HEAD~2']);
      await commit();
      await git(['switch', '-q', '-c', 'other', 'HEAD~1']);
      await commit();
      await git(['switch', '-q', 'main']);
      await commit();
      await git(['merge', '-q', '--no-ff', '-m', 'octopus', 'side', 'other']);
      await commit();

      for (final all in [false, true]) {
        final g = await layoutOf(all: all);
        final out = await git(GitCommands.history(all: all, topo: true).sublist(1));
        expect(g.rows.length, LogEntry.parse(out).length);
        expectConnected(g);
        if (all) expect(g.laneCount, greaterThan(1));
      }
    });

    test('a repository with many criss-crossing merges', () async {
      await commit();
      final names = ['a', 'b', 'c'];
      for (final b in names) {
        await git(['branch', b]);
      }
      for (var round = 0; round < 6; round++) {
        for (final b in names) {
          await git(['switch', '-q', b]);
          await commit();
        }
        // 한 브랜치를 다른 브랜치로 병합 (돌려 가며)
        final from = names[round % 3];
        final into = names[(round + 1) % 3];
        await git(['switch', '-q', into]);
        await git(['merge', '-q', '--no-ff', '-m', 'm$round', from]);
      }
      await git(['switch', '-q', 'main']);
      await git(['merge', '-q', '--no-ff', '-m', 'all', 'a', 'b', 'c']);
      final g = await layoutOf(all: true);
      expect(g.rows.length, greaterThan(20));
      expectConnected(g);
      expect(g.laneCount, lessThan(10));
    });
  });
}
