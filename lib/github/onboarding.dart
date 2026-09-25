/// 시작·로그인·원격 보조 (PLAN.md 3.1, 3.6 P1).
library;

import 'dart:convert';
import 'dart:io';

/// `gh auth login --web` 출력에서 일회용 코드. 예: `! One-time code (FFA0-F23C) copied to clipboard`
/// 또는 `! First copy your one-time code: FFA0-F23C`.
String? parseDeviceCode(String output) => RegExp(r'\b([A-Z0-9]{4}-[A-Z0-9]{4})\b').firstMatch(output)?.group(1);

const deviceLoginUrl = 'https://github.com/login/device';

/// `gh repo list --json` 한 줄.
class RepoSummary {
  const RepoSummary({required this.nameWithOwner, this.description = '', this.private = false, this.fork = false, this.updated});

  final String nameWithOwner;
  final String description;
  final bool private;
  final bool fork;
  final DateTime? updated;

  String get name => nameWithOwner.split('/').last;

  static List<RepoSummary> parseList(String json) {
    try {
      return [
        for (final m in (jsonDecode(json) as List<dynamic>).whereType<Map<String, dynamic>>())
          RepoSummary(
            nameWithOwner: (m['nameWithOwner'] ?? '') as String,
            description: (m['description'] ?? '') as String,
            private: (m['isPrivate'] ?? false) as bool,
            fork: (m['isFork'] ?? false) as bool,
            updated: DateTime.tryParse((m['updatedAt'] ?? '') as String),
          ),
      ];
    } on Object {
      return const [];
    }
  }
}

/// `gh repo view --json nameWithOwner,isFork,parent,defaultBranchRef`.
class ForkInfo {
  const ForkInfo({required this.nameWithOwner, this.parent});

  final String nameWithOwner;

  /// 원본 저장소 `owner/repo`. fork가 아니면 null.
  final String? parent;

  bool get isFork => parent != null;
  String? get parentUrl => parent == null ? null : 'https://github.com/$parent.git';

  static ForkInfo? parse(String json) {
    try {
      final m = jsonDecode(json) as Map<String, dynamic>;
      final parent = m['parent'] as Map<String, dynamic>?;
      String? parentName;
      if (m['isFork'] == true && parent != null) {
        final owner = (parent['owner'] as Map<String, dynamic>?)?['login'] as String?;
        final name = parent['name'] as String?;
        parentName = owner != null && name != null ? '$owner/$name' : parent['nameWithOwner'] as String?;
      }
      return ForkInfo(
        nameWithOwner: (m['nameWithOwner'] ?? '') as String,
        parent: parentName,
      );
    } on Object {
      return null;
    }
  }
}

/// SSH 로그인 안내 (PLAN.md 3.1): 공개 키 파일 찾기.
List<String> findPublicKeys({String? home}) {
  final h = home ?? Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '';
  final dir = Directory('$h/.ssh');
  if (!dir.existsSync()) return const [];
  const preferred = ['id_ed25519.pub', 'id_ecdsa.pub', 'id_rsa.pub'];
  final all = dir.listSync().whereType<File>().map((f) => f.uri.pathSegments.last).where((n) => n.endsWith('.pub')).toList();
  all.sort((a, b) {
    final ia = preferred.indexOf(a);
    final ib = preferred.indexOf(b);
    return (ia < 0 ? 99 : ia).compareTo(ib < 0 ? 99 : ib);
  });
  return [for (final n in all) '${dir.path}/$n'];
}

/// `ssh -T git@github.com`: 성공해도 종료 코드는 1이고 stderr에
/// `Hi <user>! You've successfully authenticated`가 나온다.
bool sshAuthenticated(String output) => output.contains('successfully authenticated');

/// SSH 연결 확인 명령. BatchMode로 암호 문구·호스트 확인을 묻지 않는다.
/// accept-new: 처음 보는 github.com 호스트 키는 받아들여 known_hosts에 더한다.
const sshTestCommand = [
  'ssh', '-T', '-o', 'BatchMode=yes', '-o', 'StrictHostKeyChecking=accept-new', '-o', 'ConnectTimeout=10', 'git@github.com',
];
