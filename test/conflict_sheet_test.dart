// 충돌 해결 시트: 실제 git 병합 충돌에서 구간을 고르고 파일·git 상태가 바뀌는지 확인한다.

import 'dart:io';

import 'package:branch_dock/core/command_log.dart';
import 'package:branch_dock/core/command_runner.dart';
import 'package:branch_dock/l10n/app_localizations.dart';
import 'package:branch_dock/repo/environment.dart';
import 'package:branch_dock/repo/repo_controller.dart';
import 'package:branch_dock/repo/repo_prefs.dart';
import 'package:branch_dock/theme/app_theme.dart';
import 'package:branch_dock/ui/conflict_sheet.dart';
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
  late Directory tmp;
  late String dir;
  late AppServices services;
  late RepoController repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tmp = Directory.systemTemp.createTempSync('bd_conflict_ui');
    dir = '${tmp.path}/repo';
    Directory(dir).createSync();
    await git(dir, ['init', '-q', '-b', 'main']);
    for (final c in [['user.email', 't@e.com'], ['user.name', 'T'], ['commit.gpgsign', 'false']]) {
      await git(dir, ['config', ...c]);
    }
    File('$dir/f.txt').writeAsStringSync('one\ntwo\n3\n4\n5\n6\n7\n8\nfive\n');
    await git(dir, ['add', '-A']);
    await git(dir, ['commit', '-q', '-m', 'init']);
    await git(dir, ['switch', '-q', '-c', 'topic']);
    File('$dir/f.txt').writeAsStringSync('one\nTWO-topic\n3\n4\n5\n6\n7\n8\nFIVE-topic\n');
    await git(dir, ['commit', '-qam', 'topic']);
    await git(dir, ['switch', '-q', 'main']);
    File('$dir/f.txt').writeAsStringSync('one\nTWO-main\n3\n4\n5\n6\n7\n8\nFIVE-main\n');
    await git(dir, ['commit', '-qam', 'main']);
    await git(dir, ['merge', 'topic'], allowFail: true);
    services = AppServices(
      runner: CommandRunner(log: CommandLog(), path: Platform.environment['PATH'] ?? ''),
      prefs: await RepoPrefs.load(),
    );
    final (r, _) = await RepoController.open(services.runner, dir);
    repo = r!;
  });

  tearDown(() {
    repo.dispose();
    tmp.deleteSync(recursive: true);
  });

  testWidgets('marking a file resolved warns while conflict markers are left', (tester) async {
    tester.view.physicalSize = const Size(440, 960);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const env = EnvironmentStatus(gitVersion: '2', ghVersion: '2', ghLogins: {}, checked: true);
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

    await tester.runAsync(() async {
      await tester.tap(find.text('해결됨 표시'));
      await Future<void>.delayed(const Duration(milliseconds: 400));
    });
    await tester.pumpAndSettle();
    expect(find.text('충돌 표시가 남아 있습니다'), findsOneWidget);

    // 취소하면 아무것도 바뀌지 않는다.
    await tester.tap(find.widgetWithText(TextButton, '취소'));
    await tester.pumpAndSettle();
    final unmerged = await tester.runAsync(() => Process.run('git', ['ls-files', '-u'], workingDirectory: dir));
    expect((unmerged!.stdout as String).trim(), isNotEmpty);
  });

  for (final clean in [false, true]) {
    testWidgets('mark resolved ${clean ? 'without a warning once the markers are gone' : 'anyway after confirming'}',
        (tester) async {
      tester.view.physicalSize = const Size(440, 960);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      if (clean) File('$dir/f.txt').writeAsStringSync('one\nfixed\n3\n4\n5\n6\n7\n8\nfixed\n');
      const env = EnvironmentStatus(gitVersion: '2', ghVersion: '2', ghLogins: {}, checked: true);
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
      await tester.runAsync(() async {
        await tester.tap(find.text('해결됨 표시'));
        await Future<void>.delayed(const Duration(milliseconds: 400));
      });
      await tester.pumpAndSettle();
      expect(find.text('충돌 표시가 남아 있습니다'), clean ? findsNothing : findsOneWidget);
      if (!clean) await tester.tap(find.widgetWithText(FilledButton, '그래도 해결됨 표시'));
      for (var i = 0; i < 20 && (repo.status.conflicts.isNotEmpty || repo.resolvedPaths.isEmpty); i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 250)));
        await tester.pump(const Duration(milliseconds: 300));
      }
      for (var i = 0; i < 3; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 250)));
        await tester.pump(const Duration(milliseconds: 300));
      }
      expect(repo.status.conflicts, isEmpty);
    });
  }

  testWidgets('picks a side per block, rewrites the file and stages it', (tester) async {
    tester.view.physicalSize = const Size(380, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    expect(repo.status.conflicts.length, 1);

    await tester.pumpWidget(ServicesScope(
      services: services,
      child: MaterialApp(
        theme: AppTheme.dark(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showConflictSheet(context, repo, repo.status.conflicts.first),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));
    await tester.runAsync(() async {
      await tester.tap(find.text('open'));
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pumpAndSettle();

    expect(find.text('충돌 1/2'), findsOneWidget);
    expect(find.text('TWO-main'), findsOneWidget);
    expect(find.text('TWO-topic'), findsOneWidget);
    // 아직 아무것도 안 골랐으니 적용 버튼은 막혀 있다.
    FilledButton apply() => tester.widget<FilledButton>(find.widgetWithText(FilledButton, '적용하고 해결됨 표시'));
    expect(apply().onPressed, isNull);

    // 1번 구간은 내 것(main, 위), 2번 구간은 들어오는 것(topic, 아래).
    await tester.tap(find.text('TWO-main'));
    await tester.pump();
    await tester.tap(find.text('FIVE-topic'));
    await tester.pump();
    expect(apply().onPressed, isNotNull);

    await tester.tap(find.widgetWithText(FilledButton, '적용하고 해결됨 표시'));
    // 파일 쓰기 → git add 가 이어지도록, 화면 갱신과 실제 대기를 번갈아 한다.
    // 상태 새로고침까지 끝나야 하므로, 해결 목록이 채워질 때까지 (최대 5초) 기다린 뒤 한 번 더 비운다.
    for (var i = 0; i < 20 && (repo.status.conflicts.isNotEmpty || repo.resolvedPaths.isEmpty); i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 250)));
      await tester.pump(const Duration(milliseconds: 300));
    }
    for (var i = 0; i < 3; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 250)));
      await tester.pump(const Duration(milliseconds: 300));
    }

    expect(File('$dir/f.txt').readAsStringSync(), 'one\nTWO-main\n3\n4\n5\n6\n7\n8\nFIVE-topic\n');
    final unmerged = await tester.runAsync(() => Process.run('git', ['ls-files', '-u'], workingDirectory: dir));
    expect((unmerged!.stdout as String).trim(), isEmpty, reason: 'git still lists unmerged entries');
    expect(repo.status.conflicts, isEmpty);
  });
}
