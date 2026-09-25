/// 저장소의 릴리스 방식을 알아본다 (PLAN.md 3.8.1, 3.8.4).
library;

import 'dart:io';

import '../git/commits.dart';

/// `.github/workflows/*.yml`에서 찾은 릴리스 워크플로.
class ReleaseWorkflow {
  const ReleaseWorkflow({required this.file, required this.onTags, required this.dispatch});

  /// 파일 이름 (`release.yml`). `gh workflow run <file>`에 쓴다.
  final String file;

  /// `on: push: tags:` — 태그를 push하면 CI가 릴리스를 만든다.
  final bool onTags;

  /// `workflow_dispatch` — 수동 빌드 확인에 쓸 수 있다.
  final bool dispatch;
}

/// 태그 push로 도는 워크플로를 찾는다. YAML 전체를 해석하지 않고 `on:`
/// 블록 안의 `push:` 아래 `tags:`와 `workflow_dispatch`만 본다.
List<ReleaseWorkflow> detectReleaseWorkflows(String root) {
  final dir = Directory('$root/.github/workflows');
  if (!dir.existsSync()) return const [];
  final result = <ReleaseWorkflow>[];
  for (final f in dir.listSync().whereType<File>()) {
    final name = f.uri.pathSegments.last;
    if (!name.endsWith('.yml') && !name.endsWith('.yaml')) continue;
    final (tags, dispatch) = parseWorkflowTriggers(f.readAsStringSync());
    if (tags) result.add(ReleaseWorkflow(file: name, onTags: tags, dispatch: dispatch));
  }
  result.sort((a, b) => a.file.compareTo(b.file));
  return result;
}

(bool tags, bool dispatch) parseWorkflowTriggers(String yaml) {
  final lines = yaml.split('\n');
  var inOn = false;
  var onIndent = 0;
  var inPush = false;
  var pushIndent = 0;
  var tags = false;
  var dispatch = false;
  int indent(String l) => l.length - l.trimLeft().length;
  for (final raw in lines) {
    final line = raw.replaceFirst(RegExp(r'\s+#.*$'), '');
    if (line.trim().isEmpty || line.trimLeft().startsWith('#')) continue;
    final i = indent(line);
    final t = line.trim();
    if (!inOn) {
      if (RegExp(r'^"?on"?:').hasMatch(t) && i == 0) {
        inOn = true;
        onIndent = i;
        // on: [push, workflow_dispatch] 같은 한 줄 형식
        if (t.contains('workflow_dispatch')) dispatch = true;
      }
      continue;
    }
    if (i <= onIndent) break; // on 블록 끝
    if (t.startsWith('workflow_dispatch')) dispatch = true;
    if (t.startsWith('push:')) {
      inPush = true;
      pushIndent = i;
      continue;
    }
    if (inPush) {
      if (i <= pushIndent) {
        inPush = false;
      } else if (t.startsWith('tags:')) {
        tags = true;
      }
    }
  }
  return (tags, dispatch);
}

/// 태그 전 수동 빌드를 권할 변경 (PLAN.md 3.8.1): 워크플로, 의존성 잠금,
/// 플랫폼 폴더. [changedFiles]는 `git diff --name-only <마지막 태그>..HEAD`.
List<String> buildRiskFiles(List<String> changedFiles) => changedFiles
    .where((f) =>
        f.startsWith('.github/workflows/') ||
        f == 'pubspec.lock' ||
        f.endsWith('/pubspec.lock') ||
        f == 'Cargo.lock' ||
        RegExp(r'^(macos|windows|linux|ios|android)/').hasMatch(f) ||
        f.startsWith('installer/'))
    .toList();

/// 릴리스 노트 초안 (PLAN.md 3.8.4): 종류별로 묶은 목록.
/// 병합 커밋과 버전 올림 커밋은 뺀다.
String draftReleaseNotes(
  List<Commit> commits, {
  required String featuresTitle,
  required String fixesTitle,
  required String otherTitle,
}) {
  final features = <String>[];
  final fixes = <String>[];
  final other = <String>[];
  for (final c in commits) {
    if (c.isMerge || c.isRelease) continue;
    final line = '- ${c.description} (${c.shortHash})';
    switch (c.kind) {
      case CommitKind.feat:
        features.add(line);
      case CommitKind.fix || CommitKind.perf:
        fixes.add(line);
      default:
        other.add(line);
    }
  }
  final out = StringBuffer();
  for (final (title, items) in [(featuresTitle, features), (fixesTitle, fixes), (otherTitle, other)]) {
    if (items.isEmpty) continue;
    if (out.isNotEmpty) out.writeln();
    out
      ..writeln('## $title')
      ..writeln()
      ..writeAll(items, '\n')
      ..writeln();
  }
  return out.toString().trimRight();
}

/// 태그 메시지에 쓸 표시 이름 (`tagging.md` §2: `<표시 이름> <버전>`).
/// conventions 앱은 lib/app_identity.dart → AppInfo.xcconfig, 아니면 저장소 이름.
String displayNameFor(String root, String fallback) {
  final identity = File('$root/lib/app_identity.dart');
  if (identity.existsSync()) {
    final m = RegExp(r"displayName = '([^']+)'").firstMatch(identity.readAsStringSync());
    if (m != null && !m.group(1)!.startsWith('__')) return m.group(1)!;
  }
  final xc = File('$root/macos/Runner/Configs/AppInfo.xcconfig');
  if (xc.existsSync()) {
    final m = RegExp(r'^PRODUCT_NAME\s*=\s*(.+)$', multiLine: true).firstMatch(xc.readAsStringSync());
    if (m != null) return m.group(1)!.trim();
  }
  return fallback;
}
