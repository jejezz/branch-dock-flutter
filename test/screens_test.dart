// 좁은 세로 창(380px)에서 화면·시트·도움말이 오류 없이 그려지는지 확인한다.
// 실제 git으로 만든 임시 저장소를 쓴다. 넘침(overflow)도 실패로 잡힌다.

import 'dart:io';

import 'package:branch_dock/core/command_log.dart';
import 'package:branch_dock/core/command_runner.dart';
import 'package:branch_dock/l10n/app_localizations.dart';
import 'package:branch_dock/repo/environment.dart';
import 'package:branch_dock/repo/repo_controller.dart';
import 'package:branch_dock/repo/repo_prefs.dart';
import 'package:branch_dock/theme/app_theme.dart';
import 'package:branch_dock/ui/help/concept_sheet.dart';
import 'package:branch_dock/ui/help/concepts.dart';
import 'package:branch_dock/ui/repo_scope.dart';
import 'package:branch_dock/ui/services.dart';
import 'package:branch_dock/ui/start_screen.dart';
import 'package:branch_dock/ui/status_header.dart';
import 'package:branch_dock/ui/tabs/branches_tab.dart';
import 'package:branch_dock/ui/tabs/changes_tab.dart';
import 'package:branch_dock/ui/tabs/remotes_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> git(String cwd, List<String> args) async {
  final r = await Process.run('git', args, workingDirectory: cwd);
  if (r.exitCode != 0) fail('git ${args.join(' ')}: ${r.stderr}');
}

void main() {
  late Directory tmp;
  late AppServices services;
  late RepoController repo;
  const env = EnvironmentStatus(gitVersion: '2.50.1', ghVersion: '2.101.0', ghLogins: {'github.com': 'me'}, checked: true);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tmp = Directory.systemTemp.createTempSync('branch_dock_ui');
    final dir = '${tmp.path}/repo';
    Directory(dir).createSync();
    await git(dir, ['init', '-q', '-b', 'main']);
    await git(dir, ['config', 'user.email', 't@example.com']);
    await git(dir, ['config', 'user.name', 'Test']);
    File('$dir/a.txt').writeAsStringSync('a\n');
    await git(dir, ['add', '-A']);
    await git(dir, ['commit', '-q', '-m', 'init']);
    await git(dir, ['branch', 'feature/a-rather-long-branch-name-for-narrow-windows']);
    await git(dir, ['remote', 'add', 'origin', 'https://github.com/me/repo.git']);
    await git(dir, ['remote', 'add', 'lab', 'git@gitlab.com:me/repo.git']);
    File('$dir/a.txt').writeAsStringSync('changed\n');
    File('$dir/new file with a long name.md').writeAsStringSync('x\n');
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

  Future<void> pump(WidgetTester tester, Widget child, {Locale locale = const Locale('ko')}) async {
    tester.view.physicalSize = const Size(380, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ServicesScope(
      services: services,
      child: MaterialApp(
        theme: AppTheme.dark(),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: RepoScope(repo: repo, environment: env, child: child)),
      ),
    ));
    await tester.pumpAndSettle();
  }

  for (final locale in const [Locale('ko'), Locale('en')]) {
    testWidgets('header and tabs render at 380px (${locale.languageCode})', (tester) async {
      await pump(
        tester,
        Column(children: [
          StatusHeader(onBranchTap: () {}),
          Expanded(child: ChangesTab(commitFocus: FocusNode())),
        ]),
        locale: locale,
      );
      expect(find.text('a.txt'), findsOneWidget);

      await pump(tester, const BranchesTab(), locale: locale);
      expect(find.text('feature/a-rather-long-branch-name-for-narrow-windows'), findsOneWidget);

      await pump(tester, const RemotesTab(), locale: locale);
      expect(find.text('me/repo'), findsNWidgets(2));
    });
  }

  testWidgets('sheets and concept cards render', (tester) async {
    await pump(tester, Builder(builder: (context) {
      return Column(children: [
        TextButton(onPressed: () => showCreateBranchSheet(context, repo), child: const Text('branch')),
        TextButton(onPressed: () => showRemoteSheet(context, repo), child: const Text('remote')),
        TextButton(onPressed: () => showPublishToGitHubSheet(context, repo), child: const Text('publish')),
        TextButton(onPressed: () => showPullModeSheet(context, repo), child: const Text('pull')),
        TextButton(onPressed: () => showEnvironmentSheet(context, env, () {}), child: const Text('env')),
        for (final c in Concept.values)
          TextButton(onPressed: () => showConceptSheet(context, c), child: Text(c.name)),
      ]);
    }));

    Future<void> openAndClose(String label) async {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10)); // 시트 밖을 눌러 닫는다
      await tester.pumpAndSettle();
    }

    for (final label in ['branch', 'remote', 'publish', 'pull', 'env', for (final c in Concept.values) c.name]) {
      await openAndClose(label);
    }
  });

  testWidgets('create branch sheet validates and previews the command', (tester) async {
    await pump(tester, Builder(builder: (context) {
      return TextButton(onPressed: () => showCreateBranchSheet(context, repo), child: const Text('open'));
    }));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'bad name');
    await tester.pump();
    expect(find.textContaining('공백'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'feature/login');
    await tester.pump();
    expect(find.text('git switch -c feature/login'), findsOneWidget);
  });
}
