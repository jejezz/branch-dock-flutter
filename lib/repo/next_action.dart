import '../git/remotes.dart';
import '../git/status.dart';

/// 추천 행동 배너 (UI_UX.md §3 C). 우선순위 순서대로 하나만 고른다.
enum NextActionKind { resolveConflicts, pull, publish, push, publishToGitHub }

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

NextAction? suggestNextAction({required RepoStatus status, required List<Remote> remotes}) {
  final conflicts = status.conflicts.length;
  if (conflicts > 0) return NextAction(NextActionKind.resolveConflicts, conflicts);
  if (status.behind > 0) return NextAction(NextActionKind.pull, status.behind);
  if (remotes.isEmpty) {
    return status.unborn ? null : const NextAction(NextActionKind.publishToGitHub);
  }
  if (!status.detached && status.upstream == null && !status.unborn) {
    return const NextAction(NextActionKind.publish);
  }
  if (status.ahead > 0) return NextAction(NextActionKind.push, status.ahead);
  return null;
}
