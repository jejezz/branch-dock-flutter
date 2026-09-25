/// 버전 파일 감지와 버전 올리기 (PLAN.md 3.8.2, 3.8.2a).
///
/// conventions `scripts/bump-version.sh`와 같은 규칙:
/// - build number는 항상 +1, 되돌리지 않는다 (`versioning.md` §3).
/// - 프리릴리스에서 patch는 프리릴리스를 떼기만 한다 (1.5.0-rc.2 → 1.5.0).
///
/// 각 형식은 "버전 문자열이 파일의 어디에 있는가"(범위)만 알면 읽기와 쓰기를
/// 같은 규칙으로 할 수 있다. TOML·INI는 표([package], [project] …) 안에서만 찾는다.
library;

import 'dart:io';

import '../git/commits.dart';
import '../git/tags.dart';

enum VersionFileKind { pubspec, packageJson, cargo, pyproject, gradle, csproj, pom, setupCfg, setupPy, plain, custom }

class VersionFile {
  const VersionFile(this.kind, this.path, this.version, {this.pattern, this.versionCode});

  final VersionFileKind kind;

  /// 저장소 루트 기준 경로 (`/` 구분).
  final String path;
  final SemVer version;

  /// [VersionFileKind.custom]의 정규식 (캡처 그룹 1이 버전).
  final String? pattern;

  /// Android `versionCode` (build.gradle). 있으면 버전을 올릴 때 +1.
  final int? versionCode;

  /// 버전 문자열 안에 build number(`+N`)를 쓰는 형식은 pubspec뿐이다.
  bool get hasBuild => kind == VersionFileKind.pubspec;
}

/// 저장소별로 사용자가 정한 버전 파일 (PLAN.md 3.8.2a).
class CustomVersionFile {
  const CustomVersionFile(this.path, this.pattern);

  final String path;
  final String pattern;
}

/// 저장소 루트에서 버전 파일을 찾는다. [custom]이 있으면 그것만 쓴다.
/// pubspec은 한 단계 아래 폴더도 본다 (bump-version.sh와 같은 규칙).
List<VersionFile> detectVersionFiles(String root, {CustomVersionFile? custom}) {
  String? read(String rel) {
    final f = File('$root/$rel');
    return f.existsSync() ? f.readAsStringSync() : null;
  }

  if (custom != null) {
    final text = read(custom.path);
    final v = text == null ? null : readVersion(VersionFileKind.custom, text, pattern: custom.pattern);
    return v == null ? const [] : [VersionFile(VersionFileKind.custom, custom.path, v, pattern: custom.pattern)];
  }

  List<String> subdirs() {
    try {
      return Directory(root)
          .listSync()
          .whereType<Directory>()
          .map((d) => d.uri.pathSegments.where((s) => s.isNotEmpty).last)
          .where((n) => !n.startsWith('.'))
          .toList();
    } on FileSystemException {
      return const [];
    }
  }

  var pubspec = 'pubspec.yaml';
  if (read(pubspec) == null) {
    final subs = subdirs().map((d) => '$d/pubspec.yaml').where((p) => read(p) != null).toList();
    pubspec = subs.length == 1 ? subs.first : '';
  }
  final gradle = [
    'app/build.gradle.kts',
    'app/build.gradle',
    'build.gradle.kts',
    'build.gradle',
  ].where((p) => read(p) != null && _span(VersionFileKind.gradle, read(p)!) != null).firstOrNull;
  final csproj = () {
    try {
      return Directory(root)
          .listSync()
          .whereType<File>()
          .map((f) => f.uri.pathSegments.last)
          .where((n) => n.endsWith('.csproj'))
          .firstOrNull;
    } on FileSystemException {
      return null;
    }
  }();

  final result = <VersionFile>[];
  for (final (kind, rel) in [
    (VersionFileKind.pubspec, pubspec),
    (VersionFileKind.packageJson, 'package.json'),
    (VersionFileKind.cargo, 'Cargo.toml'),
    (VersionFileKind.pyproject, 'pyproject.toml'),
    (VersionFileKind.gradle, gradle ?? ''),
    (VersionFileKind.csproj, csproj ?? ''),
    (VersionFileKind.pom, 'pom.xml'),
    (VersionFileKind.setupCfg, 'setup.cfg'),
    (VersionFileKind.setupPy, 'setup.py'),
    (VersionFileKind.plain, 'VERSION'),
    (VersionFileKind.plain, 'version.txt'),
  ]) {
    if (rel.isEmpty) continue;
    final text = read(rel);
    if (text == null) continue;
    final v = readVersion(kind, text);
    if (v == null) continue;
    final code = kind == VersionFileKind.gradle ? _versionCode.firstMatch(text)?.group(1) : null;
    result.add(VersionFile(kind, rel, v, versionCode: code == null ? null : int.parse(code)));
  }
  return result;
}

final _versionCode = RegExp(r'\bversionCode\s*=?\s*(\d+)');

/// TOML·INI의 `[name]` 표 본문 범위. 없으면 null.
({int start, int end})? _table(String text, String name) {
  final header = RegExp('^\\[${RegExp.escape(name)}\\][ \\t]*\$', multiLine: true).firstMatch(text);
  if (header == null) return null;
  final next = RegExp(r'^\[', multiLine: true).allMatches(text).where((m) => m.start > header.end).firstOrNull;
  return (start: header.end, end: next?.start ?? text.length);
}

/// [re]의 캡처 그룹 1 범위를 [from, to) 안에서 찾는다.
({int start, int end})? _group(RegExp re, String text, [int from = 0, int? to]) {
  final end = to ?? text.length;
  for (final m in re.allMatches(text, from)) {
    if (m.start >= end) break;
    final g = m.group(1);
    if (g == null) continue;
    final s = m.start + m.group(0)!.indexOf(g);
    return (start: s, end: s + g.length);
  }
  return null;
}

final _tomlVersionLine = RegExp(r'^version[ \t]*=[ \t]*"([^"]+)"', multiLine: true);

/// 파일에서 버전 문자열의 위치.
({int start, int end})? _span(VersionFileKind kind, String text, {String? pattern}) {
  switch (kind) {
    case VersionFileKind.pubspec:
      return _group(RegExp(r'^version:[ \t]*(\S+)', multiLine: true), text);
    case VersionFileKind.packageJson:
      return _group(RegExp(r'"version"\s*:\s*"([^"]+)"'), text);
    case VersionFileKind.cargo:
      for (final table in ['package', 'workspace.package']) {
        final t = _table(text, table);
        final s = t == null ? null : _group(_tomlVersionLine, text, t.start, t.end);
        if (s != null) return s;
      }
      return null;
    case VersionFileKind.pyproject:
      // [project] 먼저, 없으면 [tool.poetry]. 다른 표의 version은 건드리지 않는다.
      for (final table in ['project', 'tool.poetry']) {
        final t = _table(text, table);
        final s = t == null ? null : _group(_tomlVersionLine, text, t.start, t.end);
        if (s != null) return s;
      }
      return null;
    case VersionFileKind.gradle:
      return _group(RegExp(r'''\bversionName\s*=?\s*["']([^"']+)["']'''), text);
    case VersionFileKind.csproj:
      return _group(RegExp(r'<Version>\s*([^<\s]+)\s*</Version>'), text);
    case VersionFileKind.pom:
      // <parent>의 version과 의존성의 version을 피해서, 프로젝트 자신의 version.
      final parent = RegExp(r'<parent>[\s\S]*?</parent>').firstMatch(text);
      final stop = RegExp(r'<(dependencies|dependencyManagement|build|profiles)>').firstMatch(text)?.start;
      final re = RegExp(r'<version>\s*([^<\s]+)\s*</version>');
      for (final m in re.allMatches(text)) {
        if (stop != null && m.start > stop) break;
        if (parent != null && m.start >= parent.start && m.end <= parent.end) continue;
        final s = m.start + m.group(0)!.indexOf(m.group(1)!);
        return (start: s, end: s + m.group(1)!.length);
      }
      return null;
    case VersionFileKind.setupCfg:
      final t = _table(text, 'metadata');
      return t == null ? null : _group(RegExp(r'^version[ \t]*=[ \t]*(\S+)', multiLine: true), text, t.start, t.end);
    case VersionFileKind.setupPy:
      return _group(RegExp(r'''\bversion\s*=\s*["']([^"']+)["']'''), text);
    case VersionFileKind.plain:
      return _group(RegExp(r'^\s*(\S+)\s*$'), text);
    case VersionFileKind.custom:
      if (pattern == null) return null;
      try {
        return _group(RegExp(pattern, multiLine: true), text);
      } on FormatException {
        return null;
      }
  }
}

SemVer? readVersion(VersionFileKind kind, String text, {String? pattern}) {
  final s = _span(kind, text, pattern: pattern);
  return s == null ? null : SemVer.tryParse(text.substring(s.start, s.end));
}

/// 버전 문자열만 바꾼다 (주변 형식은 그대로). pubspec 외에는 build number 없이.
String writeVersion(VersionFileKind kind, String text, SemVer v, {String? pattern}) {
  final s = _span(kind, text, pattern: pattern);
  if (s == null) return text;
  return text.replaceRange(s.start, s.end, kind == VersionFileKind.pubspec ? v.toString() : v.name);
}

/// [VersionFile] 하나를 [next]로 올린 내용. gradle은 versionCode도 +1.
String bumpFile(VersionFile f, String text, SemVer next) {
  var out = writeVersion(f.kind, text, next, pattern: f.pattern);
  if (f.kind == VersionFileKind.gradle) {
    final m = _versionCode.firstMatch(out);
    if (m != null) {
      final code = int.parse(m.group(1)!) + 1;
      final s = m.start + m.group(0)!.lastIndexOf(m.group(1)!);
      out = out.replaceRange(s, s + m.group(1)!.length, '$code');
    }
  }
  return out;
}

/// 버전 파일과 함께 맞춰야 하는 lock 파일 (PLAN.md 3.8.2a). 안 맞추면 CI의
/// `cargo build --locked`나 `npm ci`가 실패할 수 있다. 바꾼 파일 경로를 돌려준다.
List<String> bumpLockFiles(String root, List<VersionFile> files, SemVer next) {
  final changed = <String>[];
  for (final f in files) {
    final dir = f.path.contains('/') ? f.path.substring(0, f.path.lastIndexOf('/') + 1) : '';
    if (f.kind == VersionFileKind.cargo) {
      final lock = File('$root/${dir}Cargo.lock');
      final name = RegExp(r'^name[ \t]*=[ \t]*"([^"]+)"', multiLine: true)
          .firstMatch(File('$root/${f.path}').readAsStringSync())
          ?.group(1);
      if (lock.existsSync() && name != null) {
        final text = lock.readAsStringSync();
        final re = RegExp('(\\[\\[package\\]\\]\\nname = "${RegExp.escape(name)}"\\nversion = ")([^"]+)(")');
        final updated = text.replaceFirstMapped(re, (m) => '${m[1]}${next.name}${m[3]}');
        if (updated != text) {
          lock.writeAsStringSync(updated);
          changed.add('${dir}Cargo.lock');
        }
      }
    }
    if (f.kind == VersionFileKind.packageJson) {
      final lock = File('$root/${dir}package-lock.json');
      if (lock.existsSync()) {
        final text = lock.readAsStringSync();
        final old = f.version.name;
        var updated = text;
        // 맨 위 "version"
        final top = RegExp('"version":\\s*"${RegExp.escape(old)}"').firstMatch(updated);
        if (top != null) updated = updated.replaceRange(top.start, top.end, '"version": "${next.name}"');
        // "packages": { "": { ... "version": ... } } (lockfileVersion 2·3)
        final root_ = RegExp(r'"packages"\s*:\s*\{\s*""\s*:\s*\{').firstMatch(updated);
        if (root_ != null) {
          final inner = RegExp('"version":\\s*"${RegExp.escape(old)}"').firstMatch(updated.substring(root_.end));
          final close = updated.indexOf('}', root_.end);
          if (inner != null && root_.end + inner.start < close) {
            updated = updated.replaceRange(root_.end + inner.start, root_.end + inner.end, '"version": "${next.name}"');
          }
        }
        if (updated != text) {
          lock.writeAsStringSync(updated);
          changed.add('${dir}package-lock.json');
        }
      }
    }
  }
  return changed;
}

enum BumpKind { patch, minor, major, prerelease }

/// 다음 버전. [current]의 build number가 있으면 +1 한다.
SemVer bump(SemVer current, BumpKind kind) {
  final build = current.build == null ? null : current.build! + 1;
  final pre = current.pre;
  return switch (kind) {
    BumpKind.major => SemVer(current.major + 1, 0, 0, build: build),
    BumpKind.minor => SemVer(current.major, current.minor + 1, 0, build: build),
    BumpKind.patch => pre != null
        ? SemVer(current.major, current.minor, current.patch, build: build)
        : SemVer(current.major, current.minor, current.patch + 1, build: build),
    // rc.N → rc.N+1, 정식이면 다음 patch의 rc.1.
    BumpKind.prerelease => () {
        final m = pre == null ? null : RegExp(r'^(.*?)(\d+)$').firstMatch(pre);
        if (m != null) {
          return SemVer(current.major, current.minor, current.patch,
              pre: '${m.group(1)}${int.parse(m.group(2)!) + 1}', build: build);
        }
        return SemVer(current.major, current.minor, current.patch + 1, pre: 'rc.1', build: build);
      }(),
  };
}

/// 직접 입력한 버전에 build number를 붙인다.
SemVer withNextBuild(SemVer current, SemVer chosen) =>
    SemVer(chosen.major, chosen.minor, chosen.patch, pre: chosen.pre, build: current.build == null ? null : current.build! + 1);

/// 마지막 태그 이후 커밋으로 다음 버전 종류를 제안한다 (PLAN.md 3.8.2).
/// 1.0.0 이전에는 호환이 깨지는 변경도 minor (`versioning.md` §2).
({BumpKind kind, int feats, int fixes, int breaking}) suggestBump(SemVer current, List<Commit> commits) {
  final relevant = commits.where((c) => !c.isMerge && !c.isRelease);
  final breaking = relevant.where((c) => c.breaking).length;
  final feats = relevant.where((c) => c.kind == CommitKind.feat).length;
  final fixes = relevant.where((c) => c.kind == CommitKind.fix || c.kind == CommitKind.perf).length;
  final BumpKind kind;
  if (current.pre != null) {
    kind = BumpKind.patch; // 프리릴리스 → 정식
  } else if (breaking > 0) {
    kind = current.major == 0 ? BumpKind.minor : BumpKind.major;
  } else if (feats > 0) {
    kind = BumpKind.minor;
  } else {
    kind = BumpKind.patch;
  }
  return (kind: kind, feats: feats, fixes: fixes, breaking: breaking);
}
