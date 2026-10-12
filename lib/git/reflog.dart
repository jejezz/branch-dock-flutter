/// 실수 복구 (PLAN.md 3.15): HEAD가 지나간 자리(reflog)를 읽는다.
///
/// reflog는 이 컴퓨터에만 남는 기록이라, 커밋을 되돌리거나 브랜치를 지워도 한동안
/// (기본 90일) 그 시점을 찾을 수 있다.
library;

/// [GitCommands.reflog]의 --format. 레코드 구분 %x1e.
const reflogFormat = '%H%x00%h%x00%gd%x00%gs%x00%ct%x1e';

enum ReflogKind { commit, amend, checkout, reset, merge, pull, rebase, cherryPick, revert, other }

class ReflogEntry {
  const ReflogEntry({
    required this.hash,
    required this.shortHash,
    required this.selector,
    required this.message,
    this.date,
  });

  final String hash;
  final String shortHash;

  /// `HEAD@{3}`
  final String selector;

  /// git이 적은 그대로: `commit: 제목`, `checkout: moving from a to b`, `reset: moving to HEAD~1` …
  final String message;
  final DateTime? date;

  ReflogKind get kind {
    final action = message.split(':').first.trim();
    if (action.startsWith('commit (amend)')) return ReflogKind.amend;
    if (action.startsWith('commit')) return ReflogKind.commit;
    if (action.startsWith('checkout')) return ReflogKind.checkout;
    if (action.startsWith('reset')) return ReflogKind.reset;
    if (action.startsWith('merge')) return ReflogKind.merge;
    if (action.startsWith('pull')) return ReflogKind.pull;
    if (action.startsWith('rebase')) return ReflogKind.rebase;
    if (action.startsWith('cherry-pick')) return ReflogKind.cherryPick;
    if (action.startsWith('revert')) return ReflogKind.revert;
    return ReflogKind.other;
  }

  /// 종류 이름 뒤의 설명. `checkout: moving from a to b`는 `a → b`로 줄인다.
  String get detail {
    final i = message.indexOf(':');
    final rest = i < 0 ? message : message.substring(i + 1).trim();
    final moving = RegExp(r'^moving from (.+) to (.+)$').firstMatch(rest);
    if (moving != null) return '${moving.group(1)} → ${moving.group(2)}';
    return rest;
  }

  static List<ReflogEntry> parse(String output) {
    final list = <ReflogEntry>[];
    for (final record in output.split('\x1e')) {
      final r = record.trim();
      if (r.isEmpty) continue;
      final f = r.split('\x00');
      if (f.length < 4) continue;
      final seconds = int.tryParse(f.length > 4 ? f[4] : '');
      list.add(ReflogEntry(
        hash: f[0],
        shortHash: f[1],
        selector: f[2],
        message: f[3],
        date: seconds == null ? null : DateTime.fromMillisecondsSinceEpoch(seconds * 1000),
      ));
    }
    return list;
  }
}
