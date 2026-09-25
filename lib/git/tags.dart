/// 태그 목록과 버전 비교 (PLAN.md 3.7).
library;

/// [tagListArgs]의 --format과 필드 순서가 같아야 한다.
/// 주석 태그는 objecttype=tag이고 가리키는 커밋은 *objectname이다.
const tagFormat = '%(refname:short)%00%(objecttype)%00%(*objectname)%00%(objectname)'
    '%00%(creatordate:unix)%00%(contents:subject)';

class Tag {
  const Tag({
    required this.name,
    required this.commit,
    required this.annotated,
    this.date,
    this.subject = '',
    this.pushed = false,
  });

  final String name;

  /// 태그가 가리키는 커밋.
  final String commit;
  final bool annotated;
  final DateTime? date;
  final String subject;

  /// 원격(기본 원격)에 같은 이름의 태그가 있는가.
  final bool pushed;

  SemVer? get version => SemVer.tryParse(name);
  bool get prerelease => version?.pre != null;

  Tag withPushed(bool value) =>
      Tag(name: name, commit: commit, annotated: annotated, date: date, subject: subject, pushed: value);

  static List<Tag> parse(String output) {
    final tags = <Tag>[];
    for (final line in output.split('\n')) {
      if (line.isEmpty) continue;
      final f = line.split('\x00');
      if (f.length < 6) continue;
      final annotated = f[1] == 'tag';
      final seconds = int.tryParse(f[4]);
      tags.add(Tag(
        name: f[0],
        annotated: annotated,
        commit: annotated && f[2].isNotEmpty ? f[2] : f[3],
        date: seconds == null ? null : DateTime.fromMillisecondsSinceEpoch(seconds * 1000),
        subject: annotated ? f[5] : '',
      ));
    }
    return sortTags(tags);
  }

  /// `git ls-remote --tags <remote>` → 태그 이름들 (`^{}` 줄은 같은 태그).
  static Set<String> parseRemote(String output) {
    final names = <String>{};
    for (final line in output.split('\n')) {
      final i = line.indexOf('refs/tags/');
      if (i < 0) continue;
      var name = line.substring(i + 10).trim();
      if (name.endsWith('^{}')) name = name.substring(0, name.length - 3);
      names.add(name);
    }
    return names;
  }
}

/// 버전 순(내림차순), 버전이 아닌 태그는 뒤에 이름 순.
List<Tag> sortTags(List<Tag> tags) {
  final list = [...tags];
  list.sort((a, b) {
    final va = a.version;
    final vb = b.version;
    if (va != null && vb != null) return vb.compareTo(va);
    if (va != null) return -1;
    if (vb != null) return 1;
    return a.name.compareTo(b.name);
  });
  return list;
}

/// MAJOR.MINOR.PATCH[-pre][+build]. 태그의 `v` 접두어는 허용한다.
class SemVer implements Comparable<SemVer> {
  const SemVer(this.major, this.minor, this.patch, {this.pre, this.build});

  final int major;
  final int minor;
  final int patch;
  final String? pre;
  final int? build;

  static final _re = RegExp(r'^v?(\d+)\.(\d+)\.(\d+)(?:-([0-9A-Za-z.-]+))?(?:\+(\d+))?$');

  static SemVer? tryParse(String s) {
    final m = _re.firstMatch(s.trim());
    if (m == null) return null;
    return SemVer(
      int.parse(m.group(1)!),
      int.parse(m.group(2)!),
      int.parse(m.group(3)!),
      pre: m.group(4),
      build: m.group(5) == null ? null : int.parse(m.group(5)!),
    );
  }

  /// `+build`를 뺀 이름 (태그와 비교하는 값, `tagging.md` §1).
  String get name => '$major.$minor.$patch${pre == null ? '' : '-$pre'}';
  String get tag => 'v$name';

  @override
  String toString() => build == null ? name : '$name+$build';

  @override
  int compareTo(SemVer o) {
    for (final (a, b) in [(major, o.major), (minor, o.minor), (patch, o.patch)]) {
      if (a != b) return a.compareTo(b);
    }
    // 프리릴리스는 정식보다 앞선다: 1.0.0-rc.1 < 1.0.0.
    if (pre == o.pre) return 0;
    if (pre == null) return 1;
    if (o.pre == null) return -1;
    return _comparePre(pre!, o.pre!);
  }

  static int _comparePre(String a, String b) {
    final pa = a.split('.');
    final pb = b.split('.');
    for (var i = 0; i < pa.length && i < pb.length; i++) {
      final na = int.tryParse(pa[i]);
      final nb = int.tryParse(pb[i]);
      final c = na != null && nb != null ? na.compareTo(nb) : pa[i].compareTo(pb[i]);
      if (c != 0) return c;
    }
    return pa.length.compareTo(pb.length);
  }

  @override
  bool operator ==(Object other) => other is SemVer && compareTo(other) == 0 && build == other.build;

  @override
  int get hashCode => Object.hash(major, minor, patch, pre, build);
}

/// 태그 이름 검사. SemVer가 아니어도 만들 수는 있지만 경고한다.
enum TagNameProblem { empty, invalid, notSemVer, missingV }

TagNameProblem? validateTagName(String name) {
  if (name.trim().isEmpty) return TagNameProblem.empty;
  if (name.contains(RegExp(r'[\s~^:?*\[\\\x00-\x1f\x7f]')) ||
      name.contains('..') ||
      name.startsWith('-') ||
      name.endsWith('.') ||
      name.endsWith('/') ||
      name.contains('@{')) {
    return TagNameProblem.invalid;
  }
  if (SemVer.tryParse(name) == null) return TagNameProblem.notSemVer;
  if (!name.startsWith('v')) return TagNameProblem.missingV;
  return null;
}
