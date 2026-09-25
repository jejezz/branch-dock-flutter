/// 자주 나오는 git·gh 오류를 알아본다 (PLAN.md 3.12). 문구는 UI가
/// 언어별로 붙인다. git은 LC_ALL=C로 실행하므로 영어 원문을 기준으로 한다.
library;

enum GitErrorKind {
  /// push 거부: 원격에 내게 없는 커밋이 있다.
  pushRejected,

  /// 원격 인증 실패.
  authFailed,

  /// 충돌.
  conflict,

  /// 변경 사항 때문에 전환·pull이 막힘.
  localChangesWouldBeOverwritten,

  /// ff-only pull이 갈라진 기록 때문에 실패.
  notFastForward,

  /// 보호된 브랜치.
  protectedBranch,

  /// 병합되지 않은 브랜치 삭제 시도.
  branchNotMerged,

  /// 추적 브랜치가 없어 push/pull 대상이 없음.
  noUpstream,

  /// 이미 있는 이름.
  alreadyExists,

  /// 원격 저장소를 찾을 수 없음.
  repositoryNotFound,

  /// 네트워크.
  network,

  /// 실행 파일 없음.
  notInstalled,
}

GitErrorKind? classifyError(String output, {int? exitCode}) {
  final o = output.toLowerCase();
  if (exitCode == 127 || o.contains('no such file or directory') && o.contains('failed to find')) {
    return GitErrorKind.notInstalled;
  }
  if (o.contains('protected branch') || o.contains('gh006')) return GitErrorKind.protectedBranch;
  if (o.contains('[rejected]') && (o.contains('fetch first') || o.contains('non-fast-forward'))) {
    return GitErrorKind.pushRejected;
  }
  if (o.contains('updates were rejected')) return GitErrorKind.pushRejected;
  if (o.contains('not possible to fast-forward') || o.contains('diverging branches')) {
    return GitErrorKind.notFastForward;
  }
  if (o.contains('would be overwritten by') || o.contains('please commit your changes or stash them')) {
    return GitErrorKind.localChangesWouldBeOverwritten;
  }
  if (o.contains('conflict') && (o.contains('merge conflict') || o.contains('fix conflicts'))) {
    return GitErrorKind.conflict;
  }
  if (o.contains('is not fully merged')) return GitErrorKind.branchNotMerged;
  if (o.contains('has no upstream branch') || o.contains('no tracking information')) {
    return GitErrorKind.noUpstream;
  }
  if (o.contains('already exists')) return GitErrorKind.alreadyExists;
  if (o.contains('authentication failed') ||
      o.contains('could not read username') ||
      o.contains('permission denied (publickey)') ||
      o.contains('gh auth login')) {
    return GitErrorKind.authFailed;
  }
  if (o.contains('repository not found') || o.contains('does not appear to be a git repository')) {
    return GitErrorKind.repositoryNotFound;
  }
  if (o.contains('could not resolve host') || o.contains('unable to access') || o.contains('timed out')) {
    return GitErrorKind.network;
  }
  return null;
}
