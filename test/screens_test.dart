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
import 'package:branch_dock/ui/onboarding.dart';
import 'package:branch_dock/github/onboarding.dart';
import 'package:branch_dock/ui/tabs/release_list.dart' show showRollbackDialog;
import 'package:branch_dock/git/diff.dart';
import 'package:branch_dock/git/history.dart';
import 'package:branch_dock/git/commands.dart';
import 'package:branch_dock/ui/diff_view.dart';
import 'package:branch_dock/ui/command_palette.dart';
import 'package:branch_dock/ui/tabs/history_tab.dart';
import 'package:branch_dock/ui/markdown_editor.dart';
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
      return ListView(children: [
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
      await tester.ensureVisible(find.text(label));
      await tester.pumpAndSettle();
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
    // 각 단계를 직접 세팅해 그려 본다. 개요(릴리스 목록)는 gh를 불러서 건너뛴다.
    flow.checks.addAll({for (final c in ReleaseCheck.values) c: c != ReleaseCheck.synced});
    await pump(tester, ReleaseTab(flow: flow, onShowChanges: () {}));
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

  testWidgets('markdown editor previews notes', (tester) async {
    final notes = TextEditingController(text: '## 새 기능\n\n- **태그 탭** 추가\n- [링크](https://example.com)');
    addTearDown(notes.dispose);
    await pump(tester, ListView(children: [MarkdownEditor(controller: notes, label: 'notes')]));
    expect(find.byType(TextField), findsOneWidget);
    await tester.tap(find.text('미리 보기'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
    expect(find.textContaining('새 기능', findRichText: true), findsWidgets);
  });

  testWidgets('PR sheet offers checkout for another branch', (tester) async {
    final pr = PullRequest.parse('{"number":21,"title":"feat: 다른 사람 PR","url":"https://github.com/me/repo/pull/21",'
        '"state":"OPEN","isDraft":false,"mergeable":"MERGEABLE","mergeStateStatus":"CLEAN","reviewDecision":"",'
        '"statusCheckRollup":[],"headRefName":"feat/other","baseRefName":"main"}')!;
    await pump(tester, Builder(builder: (context) {
      return TextButton(onPressed: () => showPrSheetWith(context, repo, pr), child: const Text('open'));
    }));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('gh pr checkout 21'), findsOneWidget);
    expect(find.text('이 PR 브랜치로 체크아웃'), findsOneWidget);
  });

  // v0.3.0 사고 재현: 버전 올림 없이 태그 탭에서 v0.3.0을 push하려 함.
  testWidgets('new tag is blocked from pushing when it does not match the version file', (tester) async {
    late SemVer? head;
    await tester.runAsync(() async {
      File('${repo.root}/pubspec.yaml').writeAsStringSync('name: x\nversion: 0.2.2+6\n');
      await git(repo.root, ['add', 'pubspec.yaml']);
      await git(repo.root, ['commit', '-q', '-m', 'chore: pubspec']);
      await repo.refresh();
      head = await loadCommittedVersion(repo, 'HEAD');
    });
    expect(head.toString(), '0.2.2+6');
    var wizardOpened = false;
    await pump(tester, Builder(builder: (context) {
      return TextButton(
        onPressed: () => showCreateTagSheet(context, repo, headVersion: head, onOpenReleaseWizard: () => wizardOpened = true),
        child: const Text('open'),
      );
    }));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final nameField = find.byType(TextField).first;
    await tester.enterText(nameField, 'v0.3.0');
    await tester.pumpAndSettle();
    expect(find.textContaining('pubspec.yaml의 버전은 0.2.2인데 태그는 v0.3.0'), findsOneWidget);
    expect(find.textContaining('push는 막았습니다'), findsOneWidget);
    FilledButton confirm() => tester.widget<FilledButton>(find.widgetWithText(FilledButton, '만들고 push'));
    expect(confirm().onPressed, isNull);
    // 메시지는 직접 고치기 전까지 이름을 따라간다 (표시 이름이 없으면 저장소 이름).
    expect(tester.widget<TextField>(find.byType(TextField).at(1)).controller!.text, 'repo 0.3.0');

    // push를 끄면 로컬 태그는 만들 수 있다.
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, '만들기')).onPressed, isNotNull);

    // 버전 파일과 같은 태그는 막지 않는다.
    await tester.tap(find.byType(CheckboxListTile));
    await tester.enterText(nameField, 'v0.2.2');
    await tester.pumpAndSettle();
    expect(find.textContaining('push는 막았습니다'), findsNothing);
    expect(confirm().onPressed, isNotNull);

    await tester.enterText(nameField, 'v0.3.0');
    await tester.pumpAndSettle();
    await tester.tap(find.text('릴리스 마법사 열기'));
    await tester.pumpAndSettle();
    expect(wizardOpened, isTrue);
  });

  testWidgets('v0.4 sheets: push options, stash, cleanup, set upstream; stash section', (tester) async {
    await tester.runAsync(() async {
      await git(repo.root, ['update-ref', 'refs/remotes/origin/main', 'HEAD']);
      await git(repo.root, ['stash', 'push', '--include-untracked', '-m', '실험 중']);
      File('${repo.root}/a.txt').writeAsStringSync('again\n');
      await repo.refresh();
    });
    expect(repo.stashes.single.parts.text, '실험 중');

    await pump(tester, ChangesTab(commitFocus: FocusNode()));
    expect(find.text('실험 중'), findsOneWidget);
    expect(find.text('직전 커밋 고치기'), findsOneWidget);

    final branch = repo.localBranches.firstWhere((b) => !b.current);
    await pump(tester, Builder(builder: (context) {
      return Column(children: [
        TextButton(onPressed: () => showPushOptionsSheet(context, repo), child: const Text('push')),
        TextButton(onPressed: () => showStashSheet(context, repo), child: const Text('stash')),
        TextButton(
          onPressed: () => showCleanupSheetWith(context, repo, [(branch: branch, merged: false)]),
          child: const Text('cleanup'),
        ),
        TextButton(onPressed: () => showSetUpstreamSheet(context, repo, branch), child: const Text('upstream')),
      ]);
    }));
    for (final label in ['push', 'stash', 'cleanup', 'upstream']) {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      if (label == 'push') expect(find.textContaining('--follow-tags'), findsOneWidget);
      if (label == 'stash') expect(find.textContaining('git stash push --include-untracked'), findsOneWidget);
      // 병합 안 된 브랜치는 기본으로 고르지 않는다.
      if (label == 'cleanup') expect(find.text('0개 삭제'), findsOneWidget);
      if (label == 'upstream') expect(find.textContaining('git branch -u origin/main'), findsOneWidget);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
    }
  });

  testWidgets('v0.5 screens: login guide, start screen init, fork card, version file, rollback, direct wizard', (tester) async {
    // 로그인 안내: SSH 5단계 (로그인 안 됨 상태)
    const loggedOut = EnvironmentStatus(gitVersion: '2.50.1', ghVersion: '2.101.0', checked: true);
    await pump(tester, Builder(builder: (context) {
      return TextButton(
        onPressed: () => showLoginSheet(context, loggedOut, onChanged: () {}, preferSsh: true),
        child: const Text('login'),
      );
    }));
    await tester.tap(find.text('login'));
    await tester.pumpAndSettle();
    expect(find.text('SSH 권장'), findsOneWidget);
    expect(find.textContaining('gh auth login --hostname github.com --web --git-protocol ssh'), findsOneWidget);
    expect(find.textContaining('ssh -T'), findsOneWidget);
    await tester.tap(find.text('HTTPS'));
    await tester.pumpAndSettle();
    expect(find.textContaining('--git-protocol https'), findsOneWidget);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    // 시작 화면: 저장소가 아닌 폴더 → git 저장소로 만들기
    String? inited;
    await pump(
      tester,
      StartScreen(
        recent: const [],
        environment: env,
        failure: OpenFailure.notARepository,
        failedPath: '/tmp/plain-folder',
        onOpenFolder: () {},
        onOpenRecent: (_) {},
        onRemoveRecent: (_) {},
        onCheckEnvironment: () {},
        onInitRepository: (p) => inited = p,
        onClone: () {},
      ),
    );
    await tester.tap(find.text('이 폴더를 git 저장소로 만들기'));
    expect(inited, '/tmp/plain-folder');
    expect(find.text('GitHub에서 복제'), findsOneWidget);

    // fork 카드
    await pump(tester, ListView(children: [
      ForkCard(fork: ForkInfo.parse('{"isFork":true,"nameWithOwner":"me/repo","parent":{"name":"repo","owner":{"login":"orig"}}}')!, repo: repo),
    ]));
    expect(find.text('orig/repo의 fork입니다'), findsOneWidget);
    expect(find.textContaining('git remote add upstream https://github.com/orig/repo.git'), findsOneWidget);

    // 버전 파일 지정, 되돌리기
    await tester.runAsync(() async {
      File('${repo.root}/Makefile').writeAsStringSync('APP_VERSION := 4.2.0\n');
    });
    final flow = ReleaseFlow(repo, ghReady: true);
    addTearDown(flow.dispose);
    await pump(tester, Builder(builder: (context) {
      return Column(children: [
        TextButton(onPressed: () => showVersionFileSheet(context, flow), child: const Text('vf')),
        TextButton(onPressed: () => showRollbackDialog(context, repo, 'v0.3.0', hasRelease: true), child: const Text('rb')),
      ]);
    }));
    await tester.tap(find.text('vf'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Makefile');
    await tester.enterText(find.byType(TextField).last, r'APP_VERSION := (\S+)');
    await tester.pumpAndSettle();
    expect(find.text('찾았습니다: 4.2.0'), findsOneWidget);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    await tester.tap(find.text('rb'));
    await tester.pumpAndSettle();
    expect(find.textContaining('gh release delete v0.3.0 --yes'), findsOneWidget);
    expect(find.textContaining('v0.3.1'), findsOneWidget);
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();

    // 바로 커밋 방식 마법사: PR·병합은 건너뜀으로 그려진다.
    flow
      ..direct = true
      ..checks.addAll({for (final c in ReleaseCheck.values) c: true})
      ..next = SemVer.tryParse('0.2.0+4')
      ..step = ReleaseStep.tag;
    flow.tagChecks.addAll({for (final c in TagCheck.values) c: true});
    await pump(tester, ReleaseTab(flow: flow, onShowChanges: () {}));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byIcon(Icons.redo_rounded), findsNWidgets(2));
    expect(find.textContaining('원격에 내게 없는 커밋이 없다'), findsOneWidget);
  });

  testWidgets('v0.6 screens: diff sheet, commit changes, palette, cherry-pick state', (tester) async {
    const diffOut = 'diff --git a/a.txt b/a.txt\n--- a/a.txt\n+++ b/a.txt\n@@ -1 +1,2 @@\n-a\n+changed\n+a very long line that should wrap in a narrow window rather than overflow the row at all\n';
    const entry = LogEntry(hash: 'abcdef1234', shortHash: 'abcdef1', subject: 'feat: 무언가', parents: ['p1', 'p2'], author: 'Me');
    var ran = '';
    await pump(tester, Builder(builder: (context) {
      return Column(children: [
        TextButton(
          onPressed: () => showDiffSheet(
            context,
            title: 'a.txt',
            command: GitCommands.diffWorktree('a.txt'),
            result: const CommandResult(0, diffOut, ''),
          ),
          child: const Text('diff'),
        ),
        TextButton(
          onPressed: () => showCommitChangesSheetWith(context, repo, entry, ChangedFile.parse('M\ta.txt\nR100\told.md\tnew.md\n')),
          child: const Text('commit'),
        ),
        TextButton(
          onPressed: () => showCommandPalette(context, [
            PaletteItem(title: 'Push', keywords: 'push', onRun: () => ran = 'push'),
            PaletteItem(title: '새 브랜치', keywords: 'branch', onRun: () => ran = 'branch'),
            PaletteItem(title: '비활성', enabled: false, onRun: () => ran = 'disabled'),
          ]),
          child: const Text('palette'),
        ),
      ]);
    }));
    await tester.tap(find.text('diff'));
    await tester.pumpAndSettle();
    expect(find.text('+2'), findsOneWidget);
    expect(find.text('−1'), findsOneWidget);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    await tester.tap(find.text('commit'));
    await tester.pumpAndSettle();
    expect(find.text('old.md → new.md'), findsOneWidget);
    expect(find.textContaining('git diff --name-status --no-color p1 abcdef1234'), findsOneWidget);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    // 팔레트: 검색 → ↓ → Enter
    await tester.tap(find.text('palette'));
    await tester.pumpAndSettle();
    expect(find.text('비활성'), findsNothing);
    await tester.enterText(find.byType(TextField), 'bra');
    await tester.pumpAndSettle();
    expect(find.text('Push'), findsNothing);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(ran, 'branch');

    // cherry-pick 충돌 → 헤더에 계속·건너뛰기·중단
    await tester.runAsync(() async {
      await git(repo.root, ['stash', '-u', '-q']);
      final branch = repo.localBranches.firstWhere((b) => !b.current).name;
      await git(repo.root, ['switch', '-q', branch]);
      File('${repo.root}/a.txt').writeAsStringSync('from branch\n');
      await git(repo.root, ['commit', '-q', '-am', 'feat: branch']);
      await git(repo.root, ['switch', '-q', 'main']);
      File('${repo.root}/a.txt').writeAsStringSync('from main\n');
      await git(repo.root, ['commit', '-q', '-am', 'fix: main']);
      await Process.run('git', ['cherry-pick', branch], workingDirectory: repo.root);
      await repo.refresh();
    });
    expect(repo.operation, RepoOperation.cherryPicking);
    await pump(tester, StatusHeader(onBranchTap: () {}));
    expect(find.textContaining('cherry-pick 중'), findsOneWidget);
    expect(find.text('건너뛰기'), findsOneWidget);
  });
}
