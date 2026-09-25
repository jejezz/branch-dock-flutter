import 'dart:convert';

import '../core/command_runner.dart';
import '../git/commands.dart';

/// `git`, `gh` 설치와 로그인 상태 (PLAN.md 3.1 환경 점검).
class EnvironmentStatus {
  const EnvironmentStatus({this.gitVersion, this.ghVersion, this.ghLogins = const {}, this.checked = false});

  final String? gitVersion;
  final String? ghVersion;

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

  static Future<EnvironmentStatus> check(CommandRunner runner, String cwd) async {
    final results = await Future.wait([
      runner.run(GitCommands.version, workingDirectory: cwd, quiet: true),
      runner.run(GhCommands.version, workingDirectory: cwd, quiet: true),
      runner.run(GhCommands.authStatus, workingDirectory: cwd, quiet: true),
    ]);
    final git = results[0];
    final gh = results[1];
    final auth = results[2];
    return EnvironmentStatus(
      gitVersion: git.ok ? parseVersion(git.stdout) : null,
      ghVersion: gh.ok ? parseVersion(gh.stdout) : null,
      ghLogins: parseAuthHosts(auth.stdout),
      checked: true,
    );
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
