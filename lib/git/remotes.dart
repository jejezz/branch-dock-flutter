/// 원격 목록과 호스팅 판별 (PLAN.md §2.1).
library;

enum RemoteHost { github, gitlab, bitbucket, other }

class Remote {
  const Remote({required this.name, required this.fetchUrl, required this.pushUrl});

  final String name;
  final String fetchUrl;
  final String pushUrl;

  RemoteLocation? get location => RemoteLocation.parse(fetchUrl);
  RemoteHost get host => location?.kind ?? RemoteHost.other;
  bool get isGitHub => host == RemoteHost.github;

  /// `git remote -v` 출력: `origin\thttps://… (fetch)`.
  static List<Remote> parse(String output) {
    final fetch = <String, String>{};
    final push = <String, String>{};
    final order = <String>[];
    for (final line in output.split('\n')) {
      final m = RegExp(r'^(\S+)\t(.+?) \((fetch|push)\)$').firstMatch(line.trim());
      if (m == null) continue;
      final name = m.group(1)!;
      if (!order.contains(name)) order.add(name);
      (m.group(3) == 'fetch' ? fetch : push)[name] = m.group(2)!;
    }
    return [
      for (final n in order) Remote(name: n, fetchUrl: fetch[n] ?? push[n]!, pushUrl: push[n] ?? fetch[n]!),
    ];
  }
}

/// 원격 URL에서 뽑은 호스트와 `owner/repo`.
class RemoteLocation {
  const RemoteLocation({required this.host, required this.path, required this.ssh});

  final String host;

  /// `owner/repo` (끝의 `.git` 제거).
  final String path;
  final bool ssh;

  RemoteHost get kind {
    final h = host.toLowerCase();
    if (h == 'github.com' || h.endsWith('.github.com') || h == 'ssh.github.com') return RemoteHost.github;
    if (h == 'gitlab.com' || h.startsWith('gitlab.')) return RemoteHost.gitlab;
    if (h == 'bitbucket.org' || h.startsWith('bitbucket.')) return RemoteHost.bitbucket;
    return RemoteHost.other;
  }

  String get webUrl => 'https://$host/$path';
  String get httpsUrl => 'https://$host/$path.git';
  String get sshUrl => 'git@$host:$path.git';

  /// 지원 형식: `https://host/owner/repo(.git)`, `ssh://[user@]host[:port]/owner/repo`,
  /// `[user@]host:owner/repo` (scp 형식). 로컬 경로는 null.
  static RemoteLocation? parse(String url) {
    var u = url.trim();
    String strip(String p) {
      var s = p;
      while (s.startsWith('/')) {
        s = s.substring(1);
      }
      if (s.endsWith('/')) s = s.substring(0, s.length - 1);
      if (s.endsWith('.git')) s = s.substring(0, s.length - 4);
      return s;
    }

    final scheme = RegExp(r'^([a-z+]+)://').firstMatch(u);
    if (scheme != null) {
      final proto = scheme.group(1)!;
      if (proto == 'file') return null;
      final uri = Uri.tryParse(u);
      if (uri == null || uri.host.isEmpty) return null;
      return RemoteLocation(host: uri.host, path: strip(uri.path), ssh: proto.contains('ssh'));
    }
    final scp = RegExp(r'^(?:[^@/]+@)?([^:/]+):(.+)$').firstMatch(u);
    // Windows 드라이브 문자(C:\…)는 원격이 아니다.
    if (scp != null && scp.group(1)!.length > 1) {
      return RemoteLocation(host: scp.group(1)!, path: strip(scp.group(2)!), ssh: true);
    }
    return null;
  }
}
