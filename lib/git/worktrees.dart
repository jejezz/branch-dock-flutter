/// worktree 목록 — `git worktree list --porcelain` 파싱 (PLAN.md 3.4a).
/// https://git-scm.com/docs/git-worktree#_porcelain_format
library;

import 'dart:io';

class Worktree {
  const Worktree({
    required this.path,
    this.head,
    this.branch,
    this.bare = false,
    this.locked = false,
    this.prunable = false,
    this.main = false,
  });

  /// 폴더 경로 (이 OS의 구분자).
  final String path;

  /// 체크아웃된 커밋. bare면 null.
  final String? head;

  /// 체크아웃된 브랜치 이름 (`refs/heads/`를 뗀 것). 분리된 HEAD면 null.
  final String? branch;
  final bool bare;

  /// `git worktree lock`으로 잠김 — 지우려면 먼저 풀어야 한다.
  final bool locked;

  /// 폴더가 사라져 `git worktree prune`으로 정리할 수 있다.
  final bool prunable;

  /// 저장소를 처음 만든(복제한) 작업 폴더. 목록의 첫 항목이고 지울 수 없다.
  final bool main;

  bool get detached => !bare && branch == null;

  /// Claude Code가 작업마다 만드는 폴더 (`<저장소>/.claude/worktrees/<이름>`).
  /// 지우면 그 세션이 깨질 수 있어 경고를 붙인다.
  bool get byClaude => path.replaceAll(r'\', '/').contains('/.claude/worktrees/');

  /// 폴더 이름.
  String get name => path.split(RegExp(r'[/\\]')).where((s) => s.isNotEmpty).last;

  static List<Worktree> parse(String output) {
    final result = <Worktree>[];
    // 항목은 빈 줄로 나뉜다.
    for (final block in output.split(RegExp(r'\n\s*\n'))) {
      String? path;
      String? head;
      String? branch;
      var bare = false, locked = false, prunable = false;
      for (final line in block.split('\n')) {
        if (line.startsWith('worktree ')) {
          path = _nativePath(line.substring('worktree '.length));
        } else if (line.startsWith('HEAD ')) {
          head = line.substring('HEAD '.length);
        } else if (line.startsWith('branch ')) {
          final ref = line.substring('branch '.length);
          branch = ref.startsWith('refs/heads/') ? ref.substring('refs/heads/'.length) : ref;
        } else if (line == 'bare') {
          bare = true;
        } else if (line == 'locked' || line.startsWith('locked ')) {
          locked = true;
        } else if (line == 'prunable' || line.startsWith('prunable ')) {
          prunable = true;
        }
      }
      if (path == null) continue;
      result.add(Worktree(
        path: path,
        head: head,
        branch: branch,
        bare: bare,
        locked: locked,
        prunable: prunable,
        main: result.isEmpty,
      ));
    }
    return result;
  }

  /// Windows의 git은 `C:/a/b`로 돌려준다.
  static String _nativePath(String p) => Platform.isWindows ? p.replaceAll('/', r'\') : p;
}
