// 해결한 충돌을 다시 충돌 상태로 되돌리기: 실제 git 병합으로 확인한다.

import 'dart:io';

import 'package:branch_dock/core/command_log.dart';
import 'package:branch_dock/core/command_runner.dart';
import 'package:branch_dock/git/commands.dart';
import 'package:branch_dock/git/conflicts.dart';
import 'package:branch_dock/repo/repo_controller.dart';
import 'package:branch_dock/l10n/app_localizations.dart';
import 'package:branch_dock/repo/environment.dart';
import 'package:branch_dock/repo/repo_prefs.dart';
import 'package:branch_dock/theme/app_theme.dart';
import 'package:branch_dock/ui/repo_scope.dart';
import 'package:branch_dock/ui/services.dart';
import 'package:branch_dock/ui/tabs/changes_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> git(String cwd, List<String> args, {bool allowFail = false}) async {
  final r = await Process.run('git', args, workingDirectory: cwd);
  if (r.exitCode != 0 && !allowFail) fail('git ${args.join(' ')}: ${r.stderr}');
}

void main() {
  test('parseResolveUndo reads the path after the tab, once per file', () {
    const out = '100644 aaa 1\tf.txt\n100644 bbb 2\tf.txt\n100644 ccc 3\tdir/a b.txt\n';
    expect(parseResolveUndo(out), {'f.txt', 'dir/a b.txt'});
    expect(parseResolveUndo(''), isEmpty);
  });

  group('with a real merge', () {
    late Directory tmp;
    late String dir;
    late RepoController repo;

    setUp(() async {
      tmp = Directory.systemTemp.createTempSync('bd_reconflict');
      dir = '${tmp.path}/repo';
      Directory(dir).createSync();
      await git(dir, ['init', '-q', '-b', 'main']);
      for (final c in [['user.email', 't@e.com'], ['user.name', 'T'], ['commit.gpgsign', 'false']]) {
        await git(dir, ['config', ...c]);
      }
      File('$dir/f.txt').writeAsStringSync('one\ntwo\n');
      await git(dir, ['add', '-A']);
      await git(dir, ['commit', '-q', '-m', 'init']);
      await git(dir, ['switch', '-q', '-c', 'topic']);
      File('$dir/f.txt').writeAsStringSync('one\nTOPIC\n');
      await git(dir, ['commit', '-qam', 'topic']);
      await git(dir, ['switch', '-q', 'main']);
      File('$dir/f.txt').writeAsStringSync('one\nMAIN\n');
      await git(dir, ['commit', '-qam', 'main']);
      await git(dir, ['merge', 'topic'], allowFail: true);
      final runner = CommandRunner(log: CommandLog(), path: Platform.environment['PATH'] ?? '');
      repo = (await RepoController.open(runner, dir)).$1!;
    });

    tearDown(() {
      repo.dispose();
      tmp.deleteSync(recursive: true);
    });

    test('a conflicted file is not listed as resolved yet', () {
      expect(repo.status.conflicts.length, 1);
      expect(repo.resolvedPaths, isEmpty);
    });

    test('resolved file can be put back into conflict, staged or unstaged', () async {
      File('$dir/f.txt').writeAsStringSync('one\nMAIN and TOPIC\n');
      await repo.execute(GitCommands.stage('f.txt'));
      expect(repo.status.conflicts, isEmpty);
      expect(repo.resolvedPaths, {'f.txt'});

      // 스테이징 해제해도 다시 되돌릴 수 있어야 한다.
      await repo.execute(GitCommands.unstage('f.txt', unborn: false));
      expect(repo.resolvedPaths, {'f.txt'});

      final r = await repo.execute(GitCommands.reconflict('f.txt'));
      expect(r.ok, isTrue, reason: r.stderr);
      expect(repo.status.conflicts.length, 1);
      expect(File('$dir/f.txt').readAsStringSync(), contains('<<<<<<<'));
      expect(repo.resolvedPaths, isEmpty);
    });

    testWidgets('during a merge with nothing changed, says the operation is not finished', (tester) async {
      SharedPreferences.setMockInitialValues({});
      // 해결한 내용이 HEAD와 같으면 변경이 0개 — 그래도 병합은 끝나지 않았다.
      File('$dir/f.txt').writeAsStringSync('one\nMAIN\n');
      await tester.runAsync(() => repo.execute(GitCommands.stage('f.txt')));
      expect(repo.status.clean, isTrue);
      expect(repo.operation, RepoOperation.merging);

      final services = AppServices(
        runner: CommandRunner(log: CommandLog(), path: Platform.environment['PATH'] ?? ''),
        prefs: (await tester.runAsync(RepoPrefs.load))!,
      );
      const env = EnvironmentStatus(gitVersion: '2', ghVersion: '2', ghLogins: {}, checked: true);
      tester.view.physicalSize = const Size(440, 960);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(ServicesScope(
        services: services,
        child: MaterialApp(
          theme: AppTheme.dark(),
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: RepoScope(repo: repo, environment: env, child: ChangesTab(commitFocus: FocusNode()))),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('아직 작업이 끝나지 않았습니다'), findsOneWidget);
      expect(find.text('커밋할 변경이 없습니다'), findsNothing);
    });

    test('resolved paths are cleared once the merge ends', () async {
      File('$dir/f.txt').writeAsStringSync('one\nDONE\n');
      await repo.execute(GitCommands.stage('f.txt'));
      expect(repo.resolvedPaths, isNotEmpty);
      await repo.continueOperation();
      expect(repo.operation, RepoOperation.none);
      expect(repo.resolvedPaths, isEmpty);
    });
  });
}
