/// 충돌 표시(`<<<<<<<` / `=======` / `>>>>>>>`)가 든 파일을 구간으로 나누고,
/// 구간마다 고른 쪽으로 다시 합친다 (PLAN.md 3.5 P1).
///
/// git이 파일에 남기는 표시를 읽기만 한다. diff3 스타일(`|||||||` 공통 조상)도 읽는다.
library;

/// 한 구간에서 고를 수 있는 것.
enum ConflictChoice { first, second, both }

/// 충돌이 아닌 일반 줄 묶음 (줄바꿈 포함).
sealed class ConflictPart {
  const ConflictPart();
}

class PlainPart extends ConflictPart {
  const PlainPart(this.text);
  final String text;
}

/// 충돌 구간 하나. [first]는 `<<<<<<<` 쪽(HEAD), [second]는 `>>>>>>>` 쪽.
/// 어느 쪽이 "내 것"인지는 병합/rebase에 따라 달라서 여기서는 판단하지 않는다.
class ConflictBlock extends ConflictPart {
  const ConflictBlock({
    required this.first,
    required this.second,
    required this.firstLabel,
    required this.secondLabel,
    this.base,
  });

  final String first;
  final String second;

  /// `<<<<<<< HEAD`의 HEAD, `>>>>>>> feature`의 feature. 없으면 빈 문자열.
  final String firstLabel;
  final String secondLabel;

  /// diff3 스타일일 때 공통 조상 쪽. 아니면 null.
  final String? base;

  String resolve(ConflictChoice choice) => switch (choice) {
        ConflictChoice.first => first,
        ConflictChoice.second => second,
        ConflictChoice.both => first + second,
      };
}

class ConflictFile {
  const ConflictFile(this.parts);

  final List<ConflictPart> parts;

  List<ConflictBlock> get blocks => parts.whereType<ConflictBlock>().toList();
  bool get hasConflicts => parts.any((p) => p is ConflictBlock);

  /// [choices]는 [blocks] 순서대로. 모자라면 첫 번째(`first`)를 쓴다.
  String resolve(List<ConflictChoice> choices) {
    final out = StringBuffer();
    var i = 0;
    for (final p in parts) {
      switch (p) {
        case PlainPart():
          out.write(p.text);
        case ConflictBlock():
          out.write(p.resolve(i < choices.length ? choices[i] : ConflictChoice.first));
          i++;
      }
    }
    return out.toString();
  }

  /// 표시가 깨져 있어 안전하게 읽을 수 없으면 null.
  /// (닫히지 않은 구간, 짝이 안 맞는 표시 등. 이럴 땐 편집기로 넘긴다.)
  static ConflictFile? parse(String content) {
    final lines = _splitKeepingEnds(content);
    final parts = <ConflictPart>[];
    final plain = StringBuffer();

    void flushPlain() {
      if (plain.isNotEmpty) {
        parts.add(PlainPart(plain.toString()));
        plain.clear();
      }
    }

    var i = 0;
    while (i < lines.length) {
      final line = lines[i];
      if (!_isMarker(line, '<')) {
        // 구간 밖에서 `=======`나 `>>>>>>>`가 나오면 일반 텍스트(예: 마크다운 제목선)로 본다.
        plain.write(line);
        i++;
        continue;
      }
      final firstLabel = _label(line, '<');
      final first = StringBuffer();
      final base = StringBuffer();
      final second = StringBuffer();
      var inBase = false;
      var sawBase = false;
      var seenSeparator = false;
      var closed = false;
      var secondLabel = '';
      i++;
      while (i < lines.length) {
        final l = lines[i];
        if (!seenSeparator && !inBase && _isMarker(l, '|')) {
          inBase = true;
          sawBase = true;
        } else if (!seenSeparator && _isMarker(l, '=', bare: true)) {
          seenSeparator = true;
          inBase = false;
        } else if (seenSeparator && _isMarker(l, '>')) {
          secondLabel = _label(l, '>');
          closed = true;
          i++;
          break;
        } else if (_isMarker(l, '<')) {
          return null; // 구간 안에서 또 시작 → 깨진 표시
        } else {
          (seenSeparator ? second : inBase ? base : first).write(l);
        }
        i++;
      }
      if (!closed) return null;
      flushPlain();
      parts.add(ConflictBlock(
        first: first.toString(),
        second: second.toString(),
        firstLabel: firstLabel,
        secondLabel: secondLabel,
        base: sawBase ? base.toString() : null,
      ));
    }
    flushPlain();
    return ConflictFile(parts);
  }

  /// 파일에 남아 있는 충돌 시작 표시(`<<<<<<<`)의 개수. 표시가 깨진 파일도 센다.
  static int countMarkers(String content) => _splitKeepingEnds(content).where((l) => _isMarker(l, '<')).length;

  static List<String> _splitKeepingEnds(String s) {
    final out = <String>[];
    var start = 0;
    for (var i = 0; i < s.length; i++) {
      if (s.codeUnitAt(i) == 0x0A) {
        out.add(s.substring(start, i + 1));
        start = i + 1;
      }
    }
    if (start < s.length) out.add(s.substring(start));
    return out;
  }

  /// 줄 맨 앞에 [ch]가 정확히 7개. 뒤에는 공백+이름이거나 줄 끝이어야 한다
  /// (`<<<<<<<<` 8개짜리나 `=======x` 같은 것은 표시가 아니다).
  static bool _isMarker(String line, String ch, {bool bare = false}) {
    final marker = ch * 7;
    if (!line.startsWith(marker)) return false;
    final rest = line.substring(7);
    final trimmed = rest.replaceAll(RegExp(r'[\r\n]+$'), '');
    if (trimmed.isEmpty) return true;
    if (bare) return false; // `=======`는 뒤에 아무것도 없어야 한다
    return trimmed.startsWith(' ');
  }

  static String _label(String line, String ch) =>
      line.substring(7).replaceAll(RegExp(r'[\r\n]+$'), '').trim();
}

/// `git ls-files --resolve-undo` 출력에서 경로만 뽑는다 (줄마다 `<mode> <object> <stage>\t<path>`).
Set<String> parseResolveUndo(String output) {
  final paths = <String>{};
  for (final line in output.split('\n')) {
    final tab = line.indexOf('\t');
    if (tab < 0) continue;
    final path = line.substring(tab + 1).trimRight();
    if (path.isNotEmpty) paths.add(path);
  }
  return paths;
}
