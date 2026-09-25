/// 커밋 기록 — 병합 미리 보기, 다음 버전 제안, 릴리스 노트 초안에 쓴다.
library;

/// [GitCommands.log]의 --format과 필드 순서가 같아야 한다. 레코드 구분은 %x1e.
const commitFormat = '%H%x00%h%x00%s%x00%b%x00%ct%x1e';

enum CommitKind { feat, fix, perf, refactor, docs, style, test, build, ci, chore, revert, other }

class Commit {
  const Commit({
    required this.hash,
    required this.shortHash,
    required this.subject,
    this.body = '',
    this.date,
  });

  final String hash;
  final String shortHash;
  final String subject;
  final String body;
  final DateTime? date;

  static final _conventional = RegExp(r'^([a-z]+)(\([^)]*\))?(!)?: ?(.*)$');

  CommitKind get kind {
    final m = _conventional.firstMatch(subject);
    if (m == null) return CommitKind.other;
    return CommitKind.values.asNameMap()[m.group(1)] ?? CommitKind.other;
  }

  /// `feat!:` 또는 본문의 `BREAKING CHANGE:`.
  bool get breaking {
    final m = _conventional.firstMatch(subject);
    return (m != null && m.group(3) == '!') || body.contains('BREAKING CHANGE');
  }

  /// 접두어를 뗀 설명.
  String get description => _conventional.firstMatch(subject)?.group(4) ?? subject;

  /// 병합 커밋(PR 병합)은 릴리스 노트에서 뺀다.
  bool get isMerge => subject.startsWith('Merge pull request ') || subject.startsWith('Merge branch ');

  bool get isRelease => subject.startsWith('chore(release):');

  static List<Commit> parse(String output) {
    final list = <Commit>[];
    for (final record in output.split('\x1e')) {
      final r = record.trim();
      if (r.isEmpty) continue;
      final f = r.split('\x00');
      if (f.length < 5) continue;
      final seconds = int.tryParse(f[4].trim());
      list.add(Commit(
        hash: f[0],
        shortHash: f[1],
        subject: f[2],
        body: f[3].trim(),
        date: seconds == null ? null : DateTime.fromMillisecondsSinceEpoch(seconds * 1000),
      ));
    }
    return list;
  }
}
