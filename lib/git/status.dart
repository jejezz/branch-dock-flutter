/// `git status --porcelain=v2 --branch -z` 파싱.
/// https://git-scm.com/docs/git-status#_porcelain_format_version_2
library;

enum ChangeKind { modified, added, deleted, renamed, copied, typeChanged, unmerged, untracked }

/// 파일 하나의 상태. 한 파일이 스테이징된 변경과 안 된 변경을 함께 가질 수 있다.
class FileChange {
  const FileChange({
    required this.path,
    this.originalPath,
    required this.index,
    required this.worktree,
    this.untracked = false,
    this.conflicted = false,
  });

  final String path;

  /// 이름이 바뀐 파일의 옛 경로.
  final String? originalPath;

  /// 스테이징 영역(X) / 작업 트리(Y) 상태 글자. 변경 없음은 '.'.
  final String index;
  final String worktree;
  final bool untracked;
  final bool conflicted;

  bool get staged => !untracked && !conflicted && index != '.';
  bool get unstaged => !untracked && !conflicted && worktree != '.';

  ChangeKind get stagedKind => _kind(index);
  ChangeKind get unstagedKind => _kind(worktree);

  static ChangeKind _kind(String c) => switch (c) {
        'A' => ChangeKind.added,
        'D' => ChangeKind.deleted,
        'R' => ChangeKind.renamed,
        'C' => ChangeKind.copied,
        'T' => ChangeKind.typeChanged,
        _ => ChangeKind.modified,
      };

  String get fileName {
    final i = path.lastIndexOf('/');
    return i < 0 ? path : path.substring(i + 1);
  }

  String get directory {
    final i = path.lastIndexOf('/');
    return i < 0 ? '' : path.substring(0, i + 1);
  }
}

class RepoStatus {
  const RepoStatus({
    this.head,
    this.oid,
    this.upstream,
    this.ahead = 0,
    this.behind = 0,
    this.upstreamGone = false,
    this.files = const [],
  });

  /// 현재 브랜치 이름. 분리된 HEAD면 null.
  final String? head;

  /// HEAD 커밋. 아직 커밋이 없으면 null.
  final String? oid;
  final String? upstream;
  final int ahead;
  final int behind;

  /// 추적 브랜치가 설정돼 있지만 원격에 없다 (빈 저장소를 복제했거나 원격에서
  /// 지워짐). git은 이때 branch.ab 줄을 내지 않는다.
  final bool upstreamGone;
  final List<FileChange> files;

  /// 원격에 짝이 있는 추적 브랜치가 있는가.
  bool get hasUpstream => upstream != null && !upstreamGone;

  bool get detached => head == null;
  bool get unborn => oid == null;
  bool get clean => files.isEmpty;

  Iterable<FileChange> get conflicts => files.where((f) => f.conflicted);
  Iterable<FileChange> get staged => files.where((f) => f.staged);
  Iterable<FileChange> get unstaged => files.where((f) => f.unstaged);
  Iterable<FileChange> get untracked => files.where((f) => f.untracked);

  /// 커밋되지 않은 변경이 있는 파일 수 (한 파일은 한 번만 센다).
  int get changedCount => files.length;

  static RepoStatus parse(String output) {
    String? head;
    String? oid;
    String? upstream;
    var ahead = 0;
    var behind = 0;
    var hasAb = false;
    final files = <FileChange>[];

    final records = output.split('\x00');
    for (var i = 0; i < records.length; i++) {
      final r = records[i];
      if (r.isEmpty) continue;
      if (r.startsWith('# ')) {
        final header = r.substring(2);
        if (header.startsWith('branch.oid ')) {
          final v = header.substring(11);
          oid = v == '(initial)' ? null : v;
        } else if (header.startsWith('branch.head ')) {
          final v = header.substring(12);
          head = v == '(detached)' ? null : v;
        } else if (header.startsWith('branch.upstream ')) {
          upstream = header.substring(16);
        } else if (header.startsWith('branch.ab ')) {
          final m = RegExp(r'\+(\d+) -(\d+)').firstMatch(header);
          hasAb = true;
          if (m != null) {
            ahead = int.parse(m.group(1)!);
            behind = int.parse(m.group(2)!);
          }
        }
        continue;
      }
      switch (r[0]) {
        case '1':
          // 1 XY sub mH mI mW hH hI path
          final f = _fields(r, 8);
          files.add(FileChange(path: f.rest, index: f.xy[0], worktree: f.xy[1]));
        case '2':
          // 2 XY sub mH mI mW hH hI Xscore path \0 origPath
          final f = _fields(r, 9);
          final orig = i + 1 < records.length ? records[++i] : null;
          files.add(FileChange(path: f.rest, originalPath: orig, index: f.xy[0], worktree: f.xy[1]));
        case 'u':
          // u XY sub m1 m2 m3 mW h1 h2 h3 path
          final f = _fields(r, 10);
          files.add(FileChange(path: f.rest, index: f.xy[0], worktree: f.xy[1], conflicted: true));
        case '?':
          files.add(FileChange(path: r.substring(2), index: '.', worktree: '?', untracked: true));
        default:
          break; // '!' 무시된 파일은 요청하지 않는다.
      }
    }
    return RepoStatus(
      head: head,
      oid: oid,
      upstream: upstream,
      ahead: ahead,
      behind: behind,
      upstreamGone: upstream != null && !hasAb,
      files: files,
    );
  }
}

/// 앞의 [count]개 필드(첫 글자 종류 포함)를 건너뛰고 나머지를 경로로 돌려준다.
/// 경로에는 공백이 들어갈 수 있어서 split을 쓰지 않는다.
({String xy, String rest}) _fields(String record, int count) {
  var pos = 0;
  for (var n = 0; n < count; n++) {
    pos = record.indexOf(' ', pos) + 1;
  }
  final xyStart = record.indexOf(' ') + 1;
  return (xy: record.substring(xyStart, xyStart + 2), rest: record.substring(pos));
}
