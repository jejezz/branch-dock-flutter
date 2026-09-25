/// 커밋 기록 탭 (PLAN.md 3.11)과 stash 목록.
library;

/// [GitCommands.history]의 --format. 레코드 구분 %x1e.
const historyFormat = '%H%x00%h%x00%s%x00%D%x00%ct%x00%an%x1e';

/// [GitCommands.stashList]의 --format.
const stashFormat = '%gd%x00%s%x00%ct';

class LogEntry {
  const LogEntry({
    required this.hash,
    required this.shortHash,
    required this.subject,
    this.branches = const [],
    this.tags = const [],
    this.isHead = false,
    this.date,
    this.author = '',
  });

  final String hash;
  final String shortHash;
  final String subject;

  /// 이 커밋을 가리키는 브랜치 (`main`, `origin/main`). `origin/HEAD`는 뺀다.
  final List<String> branches;
  final List<String> tags;
  final bool isHead;
  final DateTime? date;
  final String author;

  static List<LogEntry> parse(String output) {
    final list = <LogEntry>[];
    for (final record in output.split('\x1e')) {
      final r = record.trim();
      if (r.isEmpty) continue;
      final f = r.split('\x00');
      if (f.length < 6) continue;
      final branches = <String>[];
      final tags = <String>[];
      var head = false;
      // %D: "HEAD -> main, tag: v1.0.0, origin/main, origin/HEAD"
      for (final d in f[3].split(', ').where((d) => d.isNotEmpty)) {
        if (d.startsWith('tag: ')) {
          tags.add(d.substring(5));
        } else if (d.startsWith('HEAD -> ')) {
          head = true;
          branches.add(d.substring(8));
        } else if (d == 'HEAD') {
          head = true;
        } else if (!d.endsWith('/HEAD')) {
          branches.add(d);
        }
      }
      final seconds = int.tryParse(f[4]);
      list.add(LogEntry(
        hash: f[0],
        shortHash: f[1],
        subject: f[2],
        branches: branches,
        tags: tags,
        isHead: head,
        date: seconds == null ? null : DateTime.fromMillisecondsSinceEpoch(seconds * 1000),
        author: f[5],
      ));
    }
    return list;
  }
}

class Stash {
  const Stash({required this.ref, required this.message, this.date});

  /// `stash@{0}`
  final String ref;

  /// `On main: 메시지` 또는 `WIP on main: abc123 커밋 제목`
  final String message;
  final DateTime? date;

  /// 만든 브랜치와 설명을 나눈다.
  ({String branch, String text}) get parts {
    final m = RegExp(r'^(?:WIP on|On) ([^:]+): (.*)$').firstMatch(message);
    return m == null ? (branch: '', text: message) : (branch: m.group(1)!, text: m.group(2)!);
  }

  static List<Stash> parse(String output) => [
        for (final line in output.split('\n'))
          if (line.contains('\x00'))
            () {
              final f = line.split('\x00');
              final seconds = int.tryParse(f.length > 2 ? f[2] : '');
              return Stash(
                ref: f[0],
                message: f.length > 1 ? f[1] : '',
                date: seconds == null ? null : DateTime.fromMillisecondsSinceEpoch(seconds * 1000),
              );
            }(),
      ];
}
