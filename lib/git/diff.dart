/// 읽기 전용 diff (PLAN.md 3.2 P2): `git diff`의 unified 출력 파싱.
library;

enum DiffLineKind { context, added, removed, hunk, meta }

class DiffLine {
  const DiffLine(this.kind, this.text, {this.oldNo, this.newNo});

  final DiffLineKind kind;

  /// 앞의 `+`/`-`/` ` 표시를 뗀 내용.
  final String text;
  final int? oldNo;
  final int? newNo;
}

class FileDiff {
  const FileDiff({this.lines = const [], this.binary = false, this.truncated = false, this.added = 0, this.removed = 0});

  final List<DiffLine> lines;
  final bool binary;

  /// 너무 길어 [maxLines]에서 잘랐다.
  final bool truncated;
  final int added;
  final int removed;

  bool get empty => lines.isEmpty && !binary;

  static const maxLines = 3000;

  /// 파일 하나의 diff. `diff --git`·`index`·`---`·`+++` 머리는 빼고,
  /// `@@` 줄부터 줄 번호를 매긴다.
  static FileDiff parse(String output, {int limit = maxLines}) {
    final lines = <DiffLine>[];
    var binary = false;
    var added = 0, removed = 0;
    int? oldNo, newNo;
    var inHunk = false;
    var truncated = false;
    final hunk = RegExp(r'^@@ -(\d+)(?:,\d+)? \+(\d+)(?:,\d+)? @@(.*)$');
    for (final raw in output.split('\n')) {
      final line = raw.endsWith('\r') ? raw.substring(0, raw.length - 1) : raw;
      if (line.startsWith('Binary files ') || line.startsWith('GIT binary patch')) {
        binary = true;
        continue;
      }
      final h = hunk.firstMatch(line);
      if (h != null) {
        inHunk = true;
        oldNo = int.parse(h.group(1)!);
        newNo = int.parse(h.group(2)!);
        if (lines.length >= limit) {
          truncated = true;
          break;
        }
        lines.add(DiffLine(DiffLineKind.hunk, line));
        continue;
      }
      if (!inHunk) continue; // 파일 머리
      if (lines.length >= limit) {
        truncated = true;
        break;
      }
      if (line.startsWith('+')) {
        added++;
        lines.add(DiffLine(DiffLineKind.added, line.substring(1), newNo: newNo));
        newNo = (newNo ?? 0) + 1;
      } else if (line.startsWith('-')) {
        removed++;
        lines.add(DiffLine(DiffLineKind.removed, line.substring(1), oldNo: oldNo));
        oldNo = (oldNo ?? 0) + 1;
      } else if (line.startsWith(r'\')) {
        lines.add(DiffLine(DiffLineKind.meta, line)); // \ No newline at end of file
      } else if (line.startsWith(' ') || line.isEmpty) {
        if (line.isEmpty && raw == output.split('\n').last) continue;
        lines.add(DiffLine(DiffLineKind.context, line.isEmpty ? '' : line.substring(1), oldNo: oldNo, newNo: newNo));
        oldNo = (oldNo ?? 0) + 1;
        newNo = (newNo ?? 0) + 1;
      } else if (line.startsWith('diff --git')) {
        inHunk = false;
      }
    }
    return FileDiff(lines: lines, binary: binary, truncated: truncated, added: added, removed: removed);
  }
}

/// 커밋이 바꾼 파일 한 줄 (`git diff --name-status`).
class ChangedFile {
  const ChangedFile(this.status, this.path, {this.oldPath});

  /// A / M / D / R / C / T
  final String status;
  final String path;
  final String? oldPath;

  static List<ChangedFile> parse(String output) {
    final list = <ChangedFile>[];
    for (final line in output.split('\n')) {
      if (line.trim().isEmpty) continue;
      final f = line.split('\t');
      final s = f[0].isEmpty ? '?' : f[0][0];
      if ((s == 'R' || s == 'C') && f.length >= 3) {
        list.add(ChangedFile(s, f[2], oldPath: f[1]));
      } else if (f.length >= 2) {
        list.add(ChangedFile(s, f[1]));
      }
    }
    return list;
  }
}
