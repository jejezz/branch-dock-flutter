/// 버전 파일 감지와 버전 올리기 (PLAN.md 3.8.2).
///
/// conventions `scripts/bump-version.sh`와 같은 규칙:
/// - build number는 항상 +1, 되돌리지 않는다 (`versioning.md` §3).
/// - 프리릴리스에서 patch는 프리릴리스를 떼기만 한다 (1.5.0-rc.2 → 1.5.0).
library;

import 'dart:io';

import '../git/commits.dart';
import '../git/tags.dart';

enum VersionFileKind { pubspec, packageJson, cargo, pyproject }

class VersionFile {
  const VersionFile(this.kind, this.path, this.version);

  final VersionFileKind kind;

  /// 저장소 루트 기준 경로 (`/` 구분).
  final String path;
  final SemVer version;

  /// build number를 쓰는 파일은 pubspec뿐이다.
  bool get hasBuild => kind == VersionFileKind.pubspec;
}

/// 저장소 루트에서 버전 파일을 찾는다. pubspec은 한 단계 아래 폴더도 본다
/// (bump-version.sh와 같은 규칙: 루트, 없으면 하위 폴더 딱 하나).
List<VersionFile> detectVersionFiles(String root) {
  final result = <VersionFile>[];
  String? read(String rel) {
    final f = File('$root/$rel');
    return f.existsSync() ? f.readAsStringSync() : null;
  }

  var pubspec = 'pubspec.yaml';
  if (read(pubspec) == null) {
    final subs = Directory(root)
        .listSync()
        .whereType<Directory>()
        .map((d) => '${d.uri.pathSegments.where((s) => s.isNotEmpty).last}/pubspec.yaml')
        .where((p) => read(p) != null)
        .toList();
    pubspec = subs.length == 1 ? subs.first : '';
  }
  for (final (kind, rel) in [
    (VersionFileKind.pubspec, pubspec),
    (VersionFileKind.packageJson, 'package.json'),
    (VersionFileKind.cargo, 'Cargo.toml'),
    (VersionFileKind.pyproject, 'pyproject.toml'),
  ]) {
    if (rel.isEmpty) continue;
    final text = read(rel);
    if (text == null) continue;
    final v = readVersion(kind, text);
    if (v != null) result.add(VersionFile(kind, rel, v));
  }
  return result;
}

final _pubspecVersion = RegExp(r'^version:\s*(\S+)\s*$', multiLine: true);
final _jsonVersion = RegExp(r'"version"\s*:\s*"([^"]+)"');
final _tomlVersion = RegExp(r'^version\s*=\s*"([^"]+)"', multiLine: true);

SemVer? readVersion(VersionFileKind kind, String text) {
  final m = switch (kind) {
    VersionFileKind.pubspec => _pubspecVersion.firstMatch(text),
    VersionFileKind.packageJson => _jsonVersion.firstMatch(text),
    VersionFileKind.cargo || VersionFileKind.pyproject => _tomlVersion.firstMatch(text),
  };
  return m == null ? null : SemVer.tryParse(m.group(1)!);
}

/// 첫 번째 버전 줄만 바꾼다 (Cargo.toml의 [package] version, 의존성 버전은 그대로).
String writeVersion(VersionFileKind kind, String text, SemVer v) {
  String first(RegExp re, String Function(Match) f) {
    final m = re.firstMatch(text);
    if (m == null) return text;
    return text.replaceRange(m.start, m.end, f(m));
  }

  return switch (kind) {
    VersionFileKind.pubspec => first(_pubspecVersion, (_) => 'version: $v'),
    VersionFileKind.packageJson => first(_jsonVersion, (_) => '"version": "${v.name}"'),
    VersionFileKind.cargo || VersionFileKind.pyproject => first(_tomlVersion, (_) => 'version = "${v.name}"'),
  };
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
