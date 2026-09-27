import 'dart:convert';
import 'dart:io';

import '../core/command_runner.dart';
import '../git/commands.dart';

/// `git`, `gh` 설치와 로그인 상태 (PLAN.md 3.1 환경 점검).
class EnvironmentStatus {
  const EnvironmentStatus({
    this.gitVersion,
    this.ghVersion,
    this.ghLogins = const {},
    this.checked = false,
    this.gitPath,
    this.ghPath,
    this.gitCustom = false,
    this.ghCustom = false,
    this.searchPath = '',
  });

  /// 최소 버전 (PLAN.md §5). gh는 `gh auth status --json`이 2.81.0에서 생겼다 —
  /// 그보다 낮으면 로그인했어도 "로그인 안 됨"으로 보인다.
  static const minGit = '2.30.0';
  static const minGh = '2.81.0';

  final String? gitVersion;
  final String? ghVersion;

  /// 실제로 실행하는 파일의 전체 경로. 찾지 못했으면 null.
  final String? gitPath;
  final String? ghPath;

  /// 설정에서 직접 지정한 경로인가 (아니면 PATH에서 찾음).
  final bool gitCustom;
  final bool ghCustom;

  /// 앱이 git·gh에 넘기는 PATH.
  final String searchPath;

  /// 호스트 → 로그인 계정. 로그인이 안 됐으면 비어 있다.
  final Map<String, String> ghLogins;
  final bool checked;

  bool get hasGit => gitVersion != null;
  bool get hasGh => ghVersion != null;
  bool get ghLoggedIn => ghLogins.containsKey('github.com');

  /// git이 없으면 아무것도 할 수 없다.
  bool get usable => hasGit;

  /// PR·릴리스·GitHub에 올리기 같은 gh 기능을 쓸 수 있는가.
  bool get ghReady => hasGh && ghLoggedIn;

  bool get gitTooOld => hasGit && compareVersions(gitVersion!, minGit) < 0;
  bool get ghTooOld => hasGh && compareVersions(ghVersion!, minGh) < 0;

  /// `2.9.1` < `2.30.0`처럼 숫자로 비교한다.
  static int compareVersions(String a, String b) {
    List<int> parts(String v) => v.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    final x = parts(a), y = parts(b);
    for (var i = 0; i < 3; i++) {
      final d = (i < x.length ? x[i] : 0) - (i < y.length ? y[i] : 0);
      if (d != 0) return d.sign;
    }
    return 0;
  }

  /// 문제 제보에 붙일 진단 정보 (PLAN.md 3.14). 계정 이름은 넣지만 토큰은 없다.
  String diagnostics({required String appVersion, String? os}) {
    final sep = Platform.isWindows ? ';' : ':';
    String tool(String name, String? version, String? path, bool custom, bool tooOld, String min) =>
        '$name: ${version ?? 'not found'}'
        '${tooOld ? ' (below $min)' : ''}'
        ' — ${path ?? '-'}${custom ? ' [custom]' : ''}';
    return [
      'Branch Dock $appVersion',
      'OS: ${os ?? '${Platform.operatingSystem} ${Platform.operatingSystemVersion}'}',
      tool('git', gitVersion, gitPath, gitCustom, gitTooOld, minGit),
      tool('gh', ghVersion, ghPath, ghCustom, ghTooOld, minGh),
      'gh login: ${ghLogins.isEmpty ? 'none' : ghLogins.entries.map((e) => '${e.key} (${e.value})').join(', ')}',
      'PATH:',
      for (final p in searchPath.split(sep))
        if (p.trim().isNotEmpty) '  $p',
    ].join('\n');
  }

  static Future<EnvironmentStatus> check(CommandRunner runner, String cwd) async {
    final results = await Future.wait([
      runner.run(GitCommands.version, workingDirectory: cwd, quiet: true),
      runner.run(GhCommands.version, workingDirectory: cwd, quiet: true),
      runner.run(GhCommands.authStatus, workingDirectory: cwd, quiet: true),
    ]);
    final git = results[0];
    final gh = results[1];
    final auth = results[2];
    final path = runner.effectivePath;
    return EnvironmentStatus(
      gitVersion: git.ok ? parseVersion(git.stdout) : null,
      ghVersion: gh.ok ? parseVersion(gh.stdout) : null,
      ghLogins: parseAuthHosts(auth.stdout),
      checked: true,
      gitPath: runner.gitPath ?? findExecutable('git', path),
      ghPath: runner.ghPath ?? findExecutable('gh', path),
      gitCustom: runner.gitPath != null,
      ghCustom: runner.ghPath != null,
      searchPath: path,
    );
  }

  /// 실행 파일 하나가 정말 [tool](`git`/`gh`)인지 확인하고 버전을 읽는다 —
  /// 경로를 지정하기 전에. 실행할 수 없거나 다른 프로그램이면 null.
  static Future<String?> probe(CommandRunner runner, String tool, String executable, String cwd) async {
    final r = await runner.run([executable, '--version'], workingDirectory: cwd, quiet: true);
    if (!r.ok || !r.stdout.trimLeft().startsWith('$tool version')) return null;
    return parseVersion(r.stdout);
  }

  /// `git version 2.50.1 (Apple Git-155)` / `gh version 2.101.0 (2026-09-15)` → `2.50.1`.
  static String? parseVersion(String output) =>
      RegExp(r'version (\d+(?:\.\d+)+)').firstMatch(output)?.group(1);

  /// `gh auth status --json hosts` → {host: login}. 성공한 계정만.
  static Map<String, String> parseAuthHosts(String json) {
    try {
      final hosts = (jsonDecode(json) as Map<String, dynamic>)['hosts'] as Map<String, dynamic>;
      final result = <String, String>{};
      for (final MapEntry(key: host, value: accounts) in hosts.entries) {
        for (final a in accounts as List<dynamic>) {
          final m = a as Map<String, dynamic>;
          if (m['state'] == 'success' && (m['active'] ?? true) == true) {
            result[host] = (m['login'] ?? '') as String;
          }
        }
      }
      return result;
    } on Object {
      return const {};
    }
  }
}
