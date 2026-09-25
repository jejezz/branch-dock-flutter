// PLAN.md 3.8.2a: 여러 언어의 버전 파일, lock 파일, 저장소별 지정, 바로 커밋 방식.

import 'dart:io';

import 'package:branch_dock/core/command_log.dart';
import 'package:branch_dock/core/command_runner.dart';
import 'package:branch_dock/git/commands.dart';
import 'package:branch_dock/git/tags.dart';
import 'package:branch_dock/github/onboarding.dart';
import 'package:branch_dock/release/release_flow.dart';
import 'package:branch_dock/release/version_files.dart';
import 'package:branch_dock/repo/repo_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

SemVer v(String s) => SemVer.tryParse(s)!;

void main() {
  group('version file formats', () {
    test('pyproject: only [project] or [tool.poetry], never another table', () {
      const text = '[tool.black]\nversion = "0.0.1"\n\n[project]\nname = "x"\nversion = "1.2.0"\n';
      expect(readVersion(VersionFileKind.pyproject, text).toString(), '1.2.0');
      final w = writeVersion(VersionFileKind.pyproject, text, v('1.3.0'));
      expect(w, contains('[tool.black]\nversion = "0.0.1"'));
      expect(w, contains('[project]\nname = "x"\nversion = "1.3.0"'));
      const poetry = '[tool.poetry]\nname = "x"\nversion = "0.4.0"\n';
      expect(readVersion(VersionFileKind.pyproject, poetry).toString(), '0.4.0');
    });

    test('cargo: [package] or [workspace.package], dependencies untouched', () {
      const ws = '[workspace]\nmembers = ["a"]\n\n[workspace.package]\nversion = "0.3.0"\n\n[workspace.dependencies]\nserde = { version = "1.0" }\n';
      expect(readVersion(VersionFileKind.cargo, ws).toString(), '0.3.0');
      expect(writeVersion(VersionFileKind.cargo, ws, v('0.4.0')), contains('serde = { version = "1.0" }'));
    });

    test('gradle versionName + versionCode, csproj, pom (not parent), setup.cfg, setup.py, VERSION', () {
      const gradle = 'android {\n  defaultConfig {\n    versionCode 41\n    versionName "1.4.2"\n  }\n}\n';
      final g = VersionFile(VersionFileKind.gradle, 'app/build.gradle', v('1.4.2'), versionCode: 41);
      final out = bumpFile(g, gradle, v('1.5.0'));
      expect(out, contains('versionCode 42'));
      expect(out, contains('versionName "1.5.0"'));
      const kts = 'versionCode = 7\nversionName = "2.0.0"\n';
      expect(readVersion(VersionFileKind.gradle, kts).toString(), '2.0.0');

      expect(readVersion(VersionFileKind.csproj, '<PropertyGroup><Version>3.1.0</Version></PropertyGroup>').toString(), '3.1.0');

      const pom = '<project><parent><version>9.9.9</version></parent><artifactId>x</artifactId>'
          '<version>1.0.0</version><dependencies><dependency><version>5.0.0</version></dependency></dependencies></project>';
      expect(readVersion(VersionFileKind.pom, pom).toString(), '1.0.0');
      final pw = writeVersion(VersionFileKind.pom, pom, v('1.1.0'));
      expect(pw, contains('<parent><version>9.9.9</version></parent>'));
      expect(pw, contains('<version>5.0.0</version>'));

      expect(readVersion(VersionFileKind.setupCfg, '[options]\nversion = 0.0.0\n[metadata]\nname = x\nversion = 2.1.0\n').toString(), '2.1.0');
      expect(readVersion(VersionFileKind.setupPy, 'setup(name="x", version="0.9.1")').toString(), '0.9.1');
      expect(writeVersion(VersionFileKind.plain, '1.0.0\n', v('1.0.1')), '1.0.1\n');
    });

    test('custom file and pattern', () {
      const text = 'APP_VERSION := 4.2.0\n';
      expect(readVersion(VersionFileKind.custom, text, pattern: r'APP_VERSION := (\S+)').toString(), '4.2.0');
      expect(writeVersion(VersionFileKind.custom, text, v('4.3.0'), pattern: r'APP_VERSION := (\S+)'), 'APP_VERSION := 4.3.0\n');
      expect(readVersion(VersionFileKind.custom, text, pattern: '(bad'), isNull);
    });
  });

  group('detection and lock files on disk', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('bd_vf'));
    tearDown(() => dir.deleteSync(recursive: true));

    test('detect node + rust and bump lock files', () {
      File('${dir.path}/package.json').writeAsStringSync('{\n  "name": "web",\n  "version": "1.0.0"\n}\n');
      File('${dir.path}/package-lock.json').writeAsStringSync(
          '{\n  "name": "web",\n  "version": "1.0.0",\n  "lockfileVersion": 3,\n  "packages": {\n    "": {\n      "name": "web",\n      "version": "1.0.0"\n    },\n    "node_modules/x": {\n      "version": "1.0.0"\n    }\n  }\n}\n');
      File('${dir.path}/Cargo.toml').writeAsStringSync('[package]\nname = "core"\nversion = "1.0.0"\n');
      File('${dir.path}/Cargo.lock').writeAsStringSync('[[package]]\nname = "core"\nversion = "1.0.0"\n\n[[package]]\nname = "serde"\nversion = "1.0.0"\n');
      final files = detectVersionFiles(dir.path);
      expect(files.map((f) => f.kind), [VersionFileKind.packageJson, VersionFileKind.cargo]);
      final changed = bumpLockFiles(dir.path, files, v('1.1.0'));
      expect(changed, ['package-lock.json', 'Cargo.lock']);
      final npm = File('${dir.path}/package-lock.json').readAsStringSync();
      expect('"version": "1.1.0"'.allMatches(npm).length, 2);
      expect(npm, contains('"node_modules/x": {\n      "version": "1.0.0"')); // 의존성은 그대로
      final cargo = File('${dir.path}/Cargo.lock').readAsStringSync();
      expect(cargo, contains('name = "core"\nversion = "1.1.0"'));
      expect(cargo, contains('name = "serde"\nversion = "1.0.0"'));
    });

    test('android app/build.gradle and custom override', () {
      Directory('${dir.path}/app').createSync();
      File('${dir.path}/app/build.gradle.kts').writeAsStringSync('versionCode = 3\nversionName = "0.3.0"\n');
      File('${dir.path}/Makefile').writeAsStringSync('APP_VERSION := 4.2.0\n');
      final auto = detectVersionFiles(dir.path);
      expect((auto.single.kind, auto.single.path, auto.single.versionCode), (VersionFileKind.gradle, 'app/build.gradle.kts', 3));
      final custom = detectVersionFiles(dir.path, custom: const CustomVersionFile('Makefile', r'APP_VERSION := (\S+)'));
      expect((custom.single.kind, custom.single.version.toString()), (VersionFileKind.custom, '4.2.0'));
    });
  });

  test('onboarding parsing', () {
    expect(parseDeviceCode('! One-time code (FFA0-F23C) copied to clipboard'), 'FFA0-F23C');
    expect(parseDeviceCode('! First copy your one-time code: 1A2B-3C4D\nPress Enter'), '1A2B-3C4D');
    expect(parseDeviceCode('nothing'), isNull);
    final fork = ForkInfo.parse('{"isFork":true,"nameWithOwner":"me/x","parent":{"id":"1","name":"x","owner":{"id":"2","login":"orig"}}}')!;
    expect((fork.isFork, fork.parent, fork.parentUrl), (true, 'orig/x', 'https://github.com/orig/x.git'));
    expect(ForkInfo.parse('{"isFork":false,"nameWithOwner":"me/y","parent":null}')!.isFork, isFalse);
    expect(sshAuthenticated("Hi jejezz! You've successfully authenticated, but GitHub does not provide shell access."), isTrue);
    expect(RepoSummary.parseList('[{"nameWithOwner":"me/a","isPrivate":true,"isFork":false,"description":"d","updatedAt":"2026-09-25T10:53:41Z"}]').single.private, isTrue);
  });

  test('direct commit release on a non-GitHub repo: check → version → tag, no PR', () async {
    SharedPreferences.setMockInitialValues({});
    final tmp = Directory.systemTemp.createTempSync('bd_direct');
    addTearDown(() => tmp.deleteSync(recursive: true));
    Future<void> git(String cwd, List<String> args) async {
      final r = await Process.run('git', args, workingDirectory: cwd);
      if (r.exitCode != 0) fail('git ${args.join(' ')}: ${r.stderr}');
    }

    await git(tmp.path, ['init', '-q', '--bare', '-b', 'main', 'remote.git']);
    await git(tmp.path, ['clone', '-q', 'remote.git', 'a']);
    final a = '${tmp.path}/a';
    for (final c in [['user.email', 't@e.com'], ['user.name', 'T'], ['commit.gpgsign', 'false'], ['tag.gpgsign', 'false']]) {
      await git(a, ['config', ...c]);
    }
    File('$a/package.json').writeAsStringSync('{\n  "name": "web",\n  "version": "1.0.0"\n}\n');
    await git(a, ['add', '-A']);
    await git(a, ['commit', '-q', '-m', 'chore: init']);
    await git(a, ['tag', '-a', 'v1.0.0', '-m', 'web 1.0.0']);
    File('$a/x.js').writeAsStringSync('x\n');
    await git(a, ['add', '-A']);
    await git(a, ['commit', '-q', '-m', 'feat: x']);
    await git(a, ['push', '-q', '-u', 'origin', 'main', '--follow-tags']);
    final runner = CommandRunner(log: CommandLog(), path: Platform.environment['PATH'] ?? '');
    final (repo, _) = await RepoController.open(runner, a);
    addTearDown(repo!.dispose);

    final flow = ReleaseFlow(repo, ghReady: false)..direct = true;
    addTearDown(flow.dispose);
    await flow.runChecks();
    expect(flow.checks[ReleaseCheck.github], isFalse);
    expect(flow.checksPassed, isTrue); // 바로 커밋 방식은 GitHub가 필요 없다
    flow.proceedToVersion();
    expect(flow.next.toString(), '1.1.0');
    expect(flow.versionCommands.first, GitCommands.add(['package.json'])); // 브랜치를 만들지 않는다
    expect((await flow.createReleaseCommit()).ok, isTrue);
    expect(repo.status.head, 'main');
    expect(flow.step, ReleaseStep.tag);
    expect(flow.tagChecksPassed, isTrue);
    expect(flow.tagCommands.first, ['git', 'push', '-u', 'origin', 'main']);
    expect((await flow.pushTag()).ok, isTrue);
    expect(flow.step, ReleaseStep.done); // GitHub가 아니면 노트·CI 없이 끝
    expect(repo.status.ahead, 0);
    expect(repo.remoteTagNames, contains('v1.1.0'));
  });
}
