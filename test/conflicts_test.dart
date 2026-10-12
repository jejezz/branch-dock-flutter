// 충돌 표시 파서: 손으로 만든 입력과, 실제 git이 만든 충돌 파일로 확인한다.

import 'dart:io';

import 'package:branch_dock/git/conflicts.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> git(String cwd, List<String> args, {bool allowFail = false}) async {
  final r = await Process.run('git', args, workingDirectory: cwd);
  if (r.exitCode != 0 && !allowFail) fail('git ${args.join(' ')}: ${r.stderr}');
}

void main() {
  group('parse', () {
    const sample = 'a\n<<<<<<< HEAD\nmine\n=======\ntheirs\n>>>>>>> feature\nb\n';

    test('splits plain text and a conflict block', () {
      final f = ConflictFile.parse(sample)!;
      expect(f.parts.length, 3);
      final b = f.blocks.single;
      expect(b.first, 'mine\n');
      expect(b.second, 'theirs\n');
      expect(b.firstLabel, 'HEAD');
      expect(b.secondLabel, 'feature');
      expect(b.base, isNull);
    });

    test('resolves each choice', () {
      final f = ConflictFile.parse(sample)!;
      expect(f.resolve([ConflictChoice.first]), 'a\nmine\nb\n');
      expect(f.resolve([ConflictChoice.second]), 'a\ntheirs\nb\n');
      expect(f.resolve([ConflictChoice.both]), 'a\nmine\ntheirs\nb\n');
    });

    test('keeps CRLF line endings untouched', () {
      final f = ConflictFile.parse('<<<<<<< HEAD\r\nx\r\n=======\r\ny\r\n>>>>>>> topic\r\n')!;
      expect(f.blocks.single.firstLabel, 'HEAD');
      expect(f.resolve([ConflictChoice.second]), 'y\r\n');
    });

    test('reads several blocks in order and an empty side', () {
      final f = ConflictFile.parse(
          '<<<<<<< HEAD\n=======\nnew\n>>>>>>> t\nmid\n<<<<<<< HEAD\nold\n=======\n>>>>>>> t\n')!;
      expect(f.blocks.length, 2);
      expect(f.resolve([ConflictChoice.second, ConflictChoice.second]), 'new\nmid\n');
      expect(f.resolve([ConflictChoice.first, ConflictChoice.first]), 'mid\nold\n');
    });

    test('reads diff3 style and keeps the base side', () {
      final f = ConflictFile.parse('<<<<<<< HEAD\nA\n||||||| base\nO\n=======\nB\n>>>>>>> t\n')!;
      final b = f.blocks.single;
      expect(b.base, 'O\n');
      expect(b.first, 'A\n');
      expect(b.second, 'B\n');
    });

    test('a markdown rule outside a block is plain text', () {
      final f = ConflictFile.parse('Title\n=======\nbody\n')!;
      expect(f.hasConflicts, isFalse);
      expect(f.resolve([]), 'Title\n=======\nbody\n');
    });

    test('no trailing newline is preserved', () {
      final f = ConflictFile.parse('<<<<<<< HEAD\nx\n=======\ny\n>>>>>>> t')!;
      expect(f.resolve([ConflictChoice.first]), 'x\n');
      expect(ConflictFile.parse('plain')!.resolve([]), 'plain');
    });

    test('broken markers return null instead of guessing', () {
      expect(ConflictFile.parse('<<<<<<< HEAD\nx\n=======\ny\n'), isNull);
      expect(ConflictFile.parse('<<<<<<< HEAD\nx\n<<<<<<< HEAD\n'), isNull);
    });
  });

  test('countMarkers counts block starts, also in broken files, and ignores look-alikes', () {
    expect(ConflictFile.countMarkers('a\nb\n'), 0);
    expect(ConflictFile.countMarkers('<<<<<<< HEAD\nx\n=======\ny\n>>>>>>> t\n'), 1);
    expect(ConflictFile.countMarkers('<<<<<<< HEAD\nx\n<<<<<<< HEAD\n'), 2);
    expect(ConflictFile.countMarkers('<<<<<<<< not a marker\n=======x\n'), 0);
    expect(ConflictFile.countMarkers('Title\n=======\n'), 0);
  });

  group('with real git', () {
    late Directory tmp;
    setUp(() => tmp = Directory.systemTemp.createTempSync('bd_conflict'));
    tearDown(() => tmp.deleteSync(recursive: true));

    Future<String> conflictedFile({String? style}) async {
      final d = tmp.path;
      await git(d, ['init', '-q', '-b', 'main']);
      for (final c in [['user.email', 't@e.com'], ['user.name', 'T'], ['commit.gpgsign', 'false']]) {
        await git(d, ['config', ...c]);
      }
      if (style != null) await git(d, ['config', 'merge.conflictStyle', style]);
      File('$d/f.txt').writeAsStringSync('one\ntwo\n3\n4\n5\n6\n7\n8\nfive\n');
      await git(d, ['add', '-A']);
      await git(d, ['commit', '-q', '-m', 'init']);
      await git(d, ['switch', '-q', '-c', 'topic']);
      File('$d/f.txt').writeAsStringSync('one\nTWO-topic\n3\n4\n5\n6\n7\n8\nFIVE-topic\n');
      await git(d, ['commit', '-qam', 'topic']);
      await git(d, ['switch', '-q', 'main']);
      File('$d/f.txt').writeAsStringSync('one\nTWO-main\n3\n4\n5\n6\n7\n8\nFIVE-main\n');
      await git(d, ['commit', '-qam', 'main']);
      await git(d, ['merge', 'topic'], allowFail: true);
      return File('$d/f.txt').readAsStringSync();
    }

    test('parses a real merge conflict and resolves per block', () async {
      final text = await conflictedFile();
      final f = ConflictFile.parse(text)!;
      expect(f.blocks.length, 2);
      expect(f.blocks.first.firstLabel, 'HEAD');
      expect(f.blocks.first.secondLabel, 'topic');
      final merged = f.resolve([ConflictChoice.first, ConflictChoice.second]);
      expect(merged, 'one\nTWO-main\n3\n4\n5\n6\n7\n8\nFIVE-topic\n');
      expect(merged.contains('<<<<<<<'), isFalse);
    });

    test('parses diff3 style from git', () async {
      final f = ConflictFile.parse(await conflictedFile(style: 'diff3'))!;
      expect(f.blocks.first.base, 'two\n');
    });
  });
}
