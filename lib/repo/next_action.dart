import '../git/remotes.dart';
import '../git/status.dart';

/// 추천 행동 배너 (UI_UX.md §3 C). 우선순위 순서대로 하나만 고른다.
enum NextActionKind { resolveConflicts, detached, pull, switchToDefault, publish, push, createPr, publishToGitHub }

class NextAction {
  const NextAction(this.kind, [this.count = 0]);

  final NextActionKind kind;
  final int count;

  /// 닫은 배너를 상태가 바뀔 때까지 다시 보이지 않게 하는 키.
  String get key => '${kind.name}:$count';

  @override
  bool operator ==(Object other) => other is NextAction && other.kind == kind && other.count == count;

  @override
  int get hashCode => Object.hash(kind, count);
}

NextAction? suggestNextAction({
  required RepoStatus status,
  required List<Remote> remotes,
  bool headMergedAndGone = false,
  bool suggestPr = false,
}) {
  final conflicts = status.conflicts.length;
  if (conflicts > 0) return NextAction(NextActionKind.resolveConflicts, conflicts);
  // 분리된 HEAD: 여기서 커밋하면 어느 브랜치에도 속하지 않는다 (PLAN.md 3.7 P1).
  if (status.detached && !status.unborn) return const NextAction(NextActionKind.detached);
  if (status.behind > 0) return NextAction(NextActionKind.pull, status.behind);
  // 병합되어 원격에서 지워진 브랜치: 게시하면 지운 브랜치가 되살아난다.
  if (headMergedAndGone) return const NextAction(NextActionKind.switchToDefault);
  if (remotes.isEmpty) {
    return status.unborn ? null : const NextAction(NextActionKind.publishToGitHub);
  }
  if (!status.detached && !status.hasUpstream && !status.unborn) {
    return const NextAction(NextActionKind.publish);
  }
  if (status.ahead > 0) return NextAction(NextActionKind.push, status.ahead);
  // 올릴 것을 다 올렸는데 PR이 없는 작업 브랜치 (UI_UX.md §3 C 6번).
  if (suggestPr) return const NextAction(NextActionKind.createPr);
  return null;
}
