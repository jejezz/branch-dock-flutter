/// 브랜치 목록 — `git for-each-ref` 출력 파싱.
library;

/// [branchListArgs]의 --format과 필드 순서가 같아야 한다.
const branchFormat = '%(refname)%00%(refname:short)%00%(upstream:short)%00%(upstream:track)'
    '%00%(committerdate:unix)%00%(subject)%00%(HEAD)';

class Branch {
  const Branch({
    required this.name,
    required this.remote,
    this.remoteName,
    this.upstream,
    this.ahead = 0,
    this.behind = 0,
    this.upstreamGone = false,
    this.lastCommit,
    this.subject = '',
    this.current = false,
  });

  /// 로컬: `feature/x`. 원격: `origin/feature/x`.
  final String name;
  final bool remote;

  /// 원격 브랜치의 원격 이름(`origin`).
  final String? remoteName;
  final String? upstream;
  final int ahead;
  final int behind;

  /// 추적하던 원격 브랜치가 사라짐 (`[gone]`).
  final bool upstreamGone;
  final DateTime? lastCommit;
  final String subject;
  final bool current;

  /// 원격 브랜치에서 원격 이름을 뗀 이름 (`feature/x`).
  String get shortName => remote && remoteName != null ? name.substring(remoteName!.length + 1) : name;

  static List<Branch> parse(String output) {
    final result = <Branch>[];
    for (final line in output.split('\n')) {
      if (line.isEmpty) continue;
      final f = line.split('\x00');
      if (f.length < 7) continue;
      final ref = f[0];
      // refs/remotes/origin/HEAD 같은 기호 참조는 브랜치가 아니다.
      if (ref.endsWith('/HEAD')) continue;
      final remote = ref.startsWith('refs/remotes/');
      final track = f[3];
      final ahead = RegExp(r'ahead (\d+)').firstMatch(track);
      final behind = RegExp(r'behind (\d+)').firstMatch(track);
      final seconds = int.tryParse(f[4]);
      String? remoteName;
      if (remote) {
        final rest = ref.substring('refs/remotes/'.length);
        remoteName = rest.substring(0, rest.indexOf('/'));
      }
      result.add(Branch(
        name: f[1],
        remote: remote,
        remoteName: remoteName,
        upstream: f[2].isEmpty ? null : f[2],
        ahead: ahead == null ? 0 : int.parse(ahead.group(1)!),
        behind: behind == null ? 0 : int.parse(behind.group(1)!),
        upstreamGone: track.contains('gone'),
        lastCommit: seconds == null ? null : DateTime.fromMillisecondsSinceEpoch(seconds * 1000),
        subject: f[5],
        current: f[6] == '*',
      ));
    }
    return result;
  }
}

/// `git check-ref-format --branch`의 주요 규칙을 앱 안에서 먼저 검사한다.
/// 사용자가 입력하는 동안 즉시 알려 주기 위해서이고, 최종 판단은 git이 한다.
BranchNameProblem? validateBranchName(String name) {
  if (name.trim().isEmpty) return BranchNameProblem.empty;
  if (name.contains(RegExp(r'[\s~^:?*\[\\\x00-\x1f\x7f]'))) return BranchNameProblem.invalidCharacter;
  if (name.startsWith('-')) return BranchNameProblem.startsWithDash;
  if (name == '@' || name.contains('@{')) return BranchNameProblem.invalidCharacter;
  if (name.contains('..') || name.contains('//')) return BranchNameProblem.invalidSequence;
  if (name.startsWith('/') || name.endsWith('/') || name.endsWith('.')) return BranchNameProblem.invalidEdge;
  for (final part in name.split('/')) {
    if (part.startsWith('.') || part.endsWith('.lock')) return BranchNameProblem.invalidSequence;
  }
  return null;
}

enum BranchNameProblem { empty, invalidCharacter, startsWithDash, invalidSequence, invalidEdge }
