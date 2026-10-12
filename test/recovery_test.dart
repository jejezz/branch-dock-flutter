// 실수 복구: reflog 읽기와 되돌리기 명령을 실제 git으로 확인한다.

import 'dart:io';

import 'package:branch_dock/core/command_log.dart';
import 'package:branch_dock/core/command_runner.dart';
import 'package:branch_dock/git/commands.dart';
import 'package:branch_dock/git/error_hints.dart';
import 'package:branch_dock/git/reflog.dart';
import 'package:branch_dock/repo/repo_controller.dart';
import 'package:branch_dock/l10n/app_localizations.dart';
import 'package:branch_dock/repo/repo_prefs.dart';
import 'package:branch_dock/theme/app_theme.dart';
import 'package:branch_dock/ui/recovery_sheet.dart';
import 'package:branch_dock/ui/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<String> git(String cwd, List<String> args) async {
  final r = await Process.run('git', args, workingDirectory: cwd);
  if (r.exitCode != 0) fail('git ${args.join(' ')}: ${r.stderr}');
  return (r.stdout as String).trim();
}

void main() {
  group('ReflogEntry', () {
    ReflogEntry e(String m) => ReflogEntry(hash: 'h', shortHash: 's', selector: 'HEAD@{0}', message: m);

    test('kinds and details', () {
      expect(e('commit: feat: add').kind, ReflogKind.commit);
      expect(e('commit: feat: add').detail, 'feat: add');
      expect(e('commit (initial): init').kind, ReflogKind.commit);
      expect(e('commit (amend): fix').kind, ReflogKind.amend);
      expect(e('commit (merge): Merge').kind, ReflogKind.commit);
      expect(e('checkout: moving from main to topic').kind, ReflogKind.checkout);
      expect(e('checkout: moving from main to topic').detail, 'main → topic');
      expect(e('reset: moving to HEAD~1').kind, ReflogKind.reset);
      expect(e('merge topic: Fast-forward').kind, ReflogKind.merge);
      expect(e('pull: Fast-forward').kind, ReflogKind.pull);
      expect(e('rebase (finish): returning to refs/heads/main').kind, ReflogKind.rebase);
      expect(e('cherry-pick: msg').kind, ReflogKind.cherryPick);
      expect(e('revert: Revert "x"').kind, ReflogKind.revert);
      expect(e('clone: from https://x').kind, ReflogKind.other);
    });

    test('parse reads records and tolerates junk', () {
      const out = 'aaaa\x00aa\x00HEAD@{0}\x00commit: two\x001700000100\x1ebbbb\x00bb\x00HEAD@{1}\x00commit (initial): one\x001700000000\x1e\x1ejunk';
      final list = ReflogEntry.parse(out);
      expect(list.length, 2);
      expect(list.first.shortHash, 'aa');
      expect(list.first.selector, 'HEAD@{0}');
      expect(list.first.date, DateTime.fromMillisecondsSinceEpoch(1700000100 * 1000));
      expect(list.last.kind, ReflogKind.commit);
    });
  });

  test('reset --keep blocked by local changes is offered "stash and retry"', () {
    const out = "error: Entry 'a.txt' not uptodate. Cannot merge.\nfatal: Could not reset index file to revision 'HEAD~1'.";
    expect(classifyError(out, exitCode: 128), GitErrorKind.localChangesWouldBeOverwritten);
  });

  group('with real git', () {
    late Directory tmp;
    late String dir;
    late RepoController repo;
    late List<String> hashes;

    Future<void> commit(String file, String content, String msg) async {
      File('$dir/$file').writeAsStringSync(content);
      await git(dir, ['add', '-A']);
      await git(dir, ['commit', '-q', '-m', msg]);
      hashes.add(await git(dir, ['rev-parse', 'HEAD']));
    }

    setUp(() async {
      tmp = Directory.systemTemp.createTempSync('bd_recovery');
      dir = '${tmp.path}/repo';
      Directory(dir).createSync();
      hashes = [];
      await git(dir, ['init', '-q', '-b', 'main']);
      for (final c in [['user.email', 't@e.com'], ['user.name', 'T'], ['commit.gpgsign', 'false']]) {
        await git(dir, ['config', ...c]);
      }
      await commit('a.txt', 'a1\n', 'one');
      await commit('a.txt', 'a2\n', 'two');
      await commit('b.txt', 'b1\n', 'three');
      final runner = CommandRunner(log: CommandLog(), path: Platform.environment['PATH'] ?? '');
      repo = (await RepoController.open(runner, dir)).$1!;
    });

    tearDown(() {
      repo.dispose();
      tmp.deleteSync(recursive: true);
    });

    test('reflog lists recent moves newest first', () async {
      final r = await repo.read(GitCommands.reflog());
      final list = ReflogEntry.parse(r.stdout);
      expect(list.length, 3);
      expect(list.first.hash, hashes.last);
      expect(list.first.detail, 'three');
      expect(list.last.message, startsWith('commit (initial)'));
    });

    test('undo last commit keeps the work, staged', () async {
      expect((await repo.read(GitCommands.hasParent)).ok, isTrue);
      final r = await repo.execute(GitCommands.undoLastCommit);
      expect(r.ok, isTrue, reason: r.stderr);
      expect(await git(dir, ['rev-parse', 'HEAD']), hashes[1]);
      expect(File('$dir/b.txt').existsSync(), isTrue);
      expect(await git(dir, ['status', '--short']), 'A  b.txt');
    });

    test('the first commit has no parent to go back to', () async {
      await git(dir, ['reset', '-q', '--hard', hashes.first]);
      expect((await repo.read(GitCommands.hasParent)).ok, isFalse);
    });

    test('reset --keep moves back and keeps unrelated uncommitted work', () async {
      File('$dir/notes.txt').writeAsStringSync('mine\n');
      File('$dir/b.txt').writeAsStringSync('b1\nedited\n');
      final r = await repo.execute(GitCommands.resetKeep(hashes.first));
      // b.txt는 되돌릴 구간에서 바뀐 파일이라 겹친다 → 멈추고 아무것도 바꾸지 않는다.
      expect(r.ok, isFalse);
      expect(await git(dir, ['rev-parse', 'HEAD']), hashes.last);
      expect(File('$dir/b.txt').readAsStringSync(), 'b1\nedited\n');

      File('$dir/b.txt').writeAsStringSync('b1\n');
      final r2 = await repo.execute(GitCommands.resetKeep(hashes.first));
      expect(r2.ok, isTrue, reason: r2.stderr);
      expect(await git(dir, ['rev-parse', 'HEAD']), hashes.first);
      expect(File('$dir/notes.txt').readAsStringSync(), 'mine\n');
      expect(File('$dir/a.txt').readAsStringSync(), 'a1\n');
    });

    Future<void> openSheet(WidgetTester tester, {Locale locale = const Locale('ko')}) async {
      SharedPreferences.setMockInitialValues({});
      final services = AppServices(
        runner: CommandRunner(log: CommandLog(), path: Platform.environment['PATH'] ?? ''),
        prefs: (await tester.runAsync(RepoPrefs.load))!,
      );
      tester.view.physicalSize = const Size(380, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(ServicesScope(
        services: services,
        child: MaterialApp(
          theme: AppTheme.dark(),
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(onPressed: () => showRecoverySheet(context, repo), child: const Text('open')),
            ),
          ),
        ),
      ));
      await tester.runAsync(() async {
        await tester.tap(find.text('open'));
        await Future<void>.delayed(const Duration(milliseconds: 600));
      });
      await tester.pumpAndSettle();
    }

    Future<void> settle(WidgetTester tester, bool Function() done) async {
      for (var i = 0; i < 20 && !done(); i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 250)));
        await tester.pump(const Duration(milliseconds: 300));
      }
      for (var i = 0; i < 3; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 250)));
        await tester.pump(const Duration(milliseconds: 300));
      }
    }

    for (final locale in const [Locale('ko'), Locale('en')]) {
      testWidgets('recovery sheet renders at 380px (${locale.languageCode})', (tester) async {
        await openSheet(tester, locale: locale);
        final l10n = await AppLocalizations.delegate.load(locale);
        expect(find.text(l10n.recoveryTitle), findsOneWidget);
        expect(find.text(l10n.recoveryUndoCommit), findsOneWidget);
        expect(find.text('three'), findsWidgets);
        expect(find.text(l10n.recoveryNow), findsOneWidget);
      });
    }

    testWidgets('undo the last commit from the sheet', (tester) async {
      await openSheet(tester);
      await tester.tap(find.text('마지막 커밋 취소'));
      await tester.pumpAndSettle();
      expect(find.textContaining('three'), findsWidgets);
      await tester.tap(find.widgetWithText(FilledButton, '커밋 취소'));
      var head = hashes.last;
      await settle(tester, () => false);
      head = (await tester.runAsync(() => git(dir, ['rev-parse', 'HEAD'])))!;
      expect(head, hashes[1]);
      expect(File('$dir/b.txt').existsSync(), isTrue);
    });

    testWidgets('go back to an earlier reflog entry from the sheet', (tester) async {
      await openSheet(tester);
      // 세 번째 줄(첫 커밋 one)의 메뉴에서 되돌린다.
      final more = find.byTooltip('더 보기');
      expect(more, findsWidgets);
      await tester.tap(more.last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('여기로 되돌리기'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, '되돌리기'));
      await settle(tester, () => false);
      final head = (await tester.runAsync(() => git(dir, ['rev-parse', 'HEAD'])))!;
      expect(head, hashes.first);
    });

    test('after a reset the old commit is still in the reflog and can be rescued', () async {
      await repo.execute(GitCommands.resetKeep(hashes.first));
      final list = ReflogEntry.parse((await repo.read(GitCommands.reflog())).stdout);
      expect(list.any((e) => e.hash == hashes.last), isTrue);
      expect(list.first.kind, ReflogKind.reset);

      final r = await repo.execute(GitCommands.rescueBranch('rescue/three', hashes.last));
      expect(r.ok, isTrue, reason: r.stderr);
      expect(await git(dir, ['rev-parse', 'rescue/three']), hashes.last);
      expect(await git(dir, ['branch', '--show-current']), 'main'); // 전환하지 않는다
    });
  });
}
