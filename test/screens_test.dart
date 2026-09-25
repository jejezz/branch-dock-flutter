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
import 'package:branch_dock/github/models.dart';
import 'package:branch_dock/git/tags.dart';
import 'package:branch_dock/release/release_flow.dart';
import 'package:branch_dock/ui/merge_sheet.dart';
import 'package:branch_dock/ui/tabs/pr_tab.dart';
import 'package:branch_dock/ui/tabs/release_tab.dart';
import 'package:branch_dock/ui/tabs/tags_tab.dart';
import 'package:flutter/gestures.dart';
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

  testWidgets('v0.2 screens: tags, PR card, merge sheet, every wizard step', (tester) async {
    await tester.runAsync(() async {
      await git(repo.root, ['tag', '-a', 'v0.1.0', '-m', 'Test 0.1.0']);
      await git(repo.root, ['tag', 'light-tag']);
      await repo.refresh();
    });
    await pump(tester, const TagsTab());
    expect(find.text('v0.1.0'), findsOneWidget);

    final pr = PullRequest.parse('{"number":12,"title":"chore(release): v0.2.0","url":"https://github.com/me/repo/pull/12",'
        '"state":"OPEN","isDraft":false,"mergeable":"MERGEABLE","mergeStateStatus":"CLEAN","reviewDecision":"REVIEW_REQUIRED",'
        '"statusCheckRollup":[{"name":"test","status":"COMPLETED","conclusion":"SUCCESS"},'
        '{"name":"lint","status":"IN_PROGRESS","conclusion":""}],'
        '"headRefName":"release/v0.2.0","baseRefName":"main"}')!;
    await pump(tester, ListView(children: [PrCard(pr: pr, repo: repo, onChanged: () {})]));
    expect(find.text('#12'), findsOneWidget);

    late MergePreview preview;
    final source = repo.localBranches.firstWhere((b) => !b.current);
    await tester.runAsync(() async {
      await git(repo.root, ['switch', '-q', source.name]);
      await git(repo.root, ['commit', '-q', '--allow-empty', '-m', 'feat: on branch']);
      await git(repo.root, ['switch', '-q', 'main']);
      await repo.refresh();
      preview = await loadMergePreview(repo, source);
    });
    expect(preview.commits.single.subject, 'feat: on branch');
    expect(preview.canFastForward, isTrue);
    await pump(tester, Builder(builder: (context) {
      return TextButton(onPressed: () => showMergeSheetWith(context, repo, source, preview), child: const Text('merge'));
    }));
    await tester.tap(find.text('merge'));
    await tester.pumpAndSettle();
    expect(find.textContaining('git merge --ff-only'), findsOneWidget);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    final flow = ReleaseFlow(repo, ghReady: true);
    addTearDown(flow.dispose);
    await pump(tester, ReleaseTab(flow: flow, onShowChanges: () {}));
    expect(find.byIcon(Icons.rocket_launch_rounded), findsOneWidget);

    // 각 단계를 직접 세팅해 그려 본다.
    flow.checks.addAll({for (final c in ReleaseCheck.values) c: c != ReleaseCheck.synced});
    flow.lastTag = 'v0.1.0';
    flow.buildRun = WorkflowRun.parse('{"databaseId":1,"workflowName":"Release","status":"in_progress","conclusion":"",'
        '"url":"u","jobs":[{"name":"build-macos","status":"in_progress","conclusion":"","startedAt":"2026-09-25T03:38:38Z"}]}');
    for (final step in ReleaseStep.values) {
      flow.step = step;
      flow.next = SemVer.tryParse('0.2.0+4');
      flow.pr = pr;
      flow.tagChecks.addAll({for (final c in TagCheck.values) c: c != TagCheck.versionMatches});
      if (step == ReleaseStep.ci || step == ReleaseStep.done) {
        flow.run = WorkflowRun.parse('{"databaseId":2,"workflowName":"Release","status":"completed","conclusion":"failure",'
            '"url":"u","jobs":[{"name":"build-windows","status":"completed","conclusion":"failure",'
            '"startedAt":"2026-09-25T03:38:38Z","completedAt":"2026-09-25T03:42:00Z","steps":[{"name":"Package installer","conclusion":"failure"}]}]}');
        flow.failedLog = 'error: something failed\n' * 5;
        flow.release = GitHubRelease.parse('{"tagName":"v0.2.0","name":"Test v0.2.0","url":"u","isPrerelease":false,'
            '"assets":[{"name":"Test-0.2.0-macos-universal.dmg","size":24980387}]}');
      }
      flow.notifyListeners();
      // 기다리는 단계에는 도는 진행 표시가 있어서 settle되지 않는다.
      await tester.pump(const Duration(milliseconds: 300));
    }
    expect(find.textContaining('Test-0.2.0-macos-universal.dmg'), findsOneWidget);
  });

  testWidgets('branch row shows a switch button on hover', (tester) async {
    await pump(tester, const BranchesTab());
    expect(find.text('전환'), findsNothing);
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await gesture.moveTo(tester.getCenter(find.text('feature/a-rather-long-branch-name-for-narrow-windows')));
    await tester.pumpAndSettle();
    expect(find.text('전환'), findsOneWidget);
  });

  testWidgets('create PR sheet: any branch, base selection, publish first', (tester) async {
    await tester.runAsync(() async {
      // 원격 브랜치 main, develop이 있는 것처럼 추적 참조를 만든다.
      await git(repo.root, ['update-ref', 'refs/remotes/origin/main', 'HEAD']);
      await git(repo.root, ['update-ref', 'refs/remotes/origin/develop', 'HEAD']);
      await repo.refresh();
    });
    const head = 'feature/a-rather-long-branch-name-for-narrow-windows';
    await pump(tester, Builder(builder: (context) {
      return TextButton(
        onPressed: () => showCreatePrSheetWith(context, repo, head: head, commits: const []),
        child: const Text('open'),
      );
    }));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    // 원격에 없는 브랜치는 먼저 게시한다 (현재 브랜치가 아니어도).
    expect(find.textContaining('git push -u origin $head'), findsOneWidget);
    expect(find.textContaining('--base main --head $head'), findsOneWidget);
    expect(find.text('게시하고 PR 만들기'), findsOneWidget);

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('develop').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('--base develop --head $head'), findsOneWidget);
    expect(find.textContaining('기본 브랜치(main)가 아닌 곳'), findsOneWidget);
  });
}
