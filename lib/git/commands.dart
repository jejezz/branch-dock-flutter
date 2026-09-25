/// git·gh 명령 인자 만들기. 실행 전에 "실행될 명령"으로 그대로 보여 준다
/// (PLAN.md 핵심 원칙 1). 순수 함수라 테스트로 확인한다.
library;

import 'commits.dart';
import 'refs.dart';
import 'tags.dart';

enum PullMode { merge, rebase, fastForwardOnly }

/// 다른 브랜치를 현재 브랜치로 합치는 방식 (PLAN.md 3.5).
enum MergeMode { fastForward, mergeCommit, squash }

abstract final class GitCommands {
  // --no-optional-locks: 상태를 읽을 때 index를 다시 쓰지 않는다. 쓰면
  // .git 감시가 그 변경을 보고 또 새로 고치는 순환이 생긴다.
  static const status = ['git', '--no-optional-locks', 'status', '--porcelain=v2', '--branch', '-z'];
  static const branches = ['git', 'for-each-ref', '--format=$branchFormat', 'refs/heads', 'refs/remotes'];
  static const remotes = ['git', 'remote', '-v'];
  static const topLevel = ['git', 'rev-parse', '--show-toplevel'];
  static const gitDir = ['git', 'rev-parse', '--absolute-git-dir'];
  static const version = ['git', '--version'];

  static List<String> stage(String path) => ['git', 'add', '-A', '--', path];
  static const stageAll = ['git', 'add', '-A'];

  /// 아직 커밋이 없는 저장소(unborn)에는 HEAD가 없어서 restore를 쓸 수 없다.
  static List<String> unstage(String path, {required bool unborn}) => unborn
      ? ['git', 'rm', '--cached', '-r', '-q', '--', path]
      : ['git', 'restore', '--staged', '--', path];
  static List<String> unstageAll({required bool unborn}) => unstage('.', unborn: unborn);

  static List<String> commit(String message) => ['git', 'commit', '-m', message];

  static List<String> fetch({String? remote}) =>
      remote == null ? ['git', 'fetch', '--all', '--prune'] : ['git', 'fetch', '--prune', remote];

  static List<String> pull(PullMode mode) => [
        'git',
        'pull',
        switch (mode) {
          PullMode.merge => '--no-rebase',
          PullMode.rebase => '--rebase',
          PullMode.fastForwardOnly => '--ff-only',
        },
      ];

  static const push = ['git', 'push'];

  /// 원격에 없는 브랜치를 올리고 추적 브랜치로 설정한다 (게시).
  static List<String> publish(String remote, String branch) => ['git', 'push', '-u', remote, branch];

  static List<String> switchTo(String branch) => ['git', 'switch', branch];

  /// 원격 브랜치를 골랐을 때: 같은 이름의 로컬 추적 브랜치를 만들어 전환한다.
  static List<String> switchTrack(String remoteBranch) => ['git', 'switch', '--track', remoteBranch];

  static List<String> createBranch(String name, {String? base, bool switchAfter = true}) => switchAfter
      ? ['git', 'switch', '-c', name, ?base]
      : ['git', 'branch', name, ?base];

  static List<String> renameBranch(String from, String to) => ['git', 'branch', '-m', from, to];
  static List<String> deleteBranch(String name, {bool force = false}) =>
      ['git', 'branch', force ? '-D' : '-d', name];
  static List<String> deleteRemoteBranch(String remote, String branch) =>
      ['git', 'push', remote, '--delete', branch];

  static List<String> remoteAdd(String name, String url) => ['git', 'remote', 'add', name, url];
  static List<String> remoteRename(String from, String to) => ['git', 'remote', 'rename', from, to];
  static List<String> remoteRemove(String name) => ['git', 'remote', 'remove', name];
  static List<String> remoteSetUrl(String name, String url) => ['git', 'remote', 'set-url', name, url];

  static const mergeAbort = ['git', 'merge', '--abort'];
  static const mergeContinue = ['git', 'commit', '--no-edit'];
  static const rebaseAbort = ['git', 'rebase', '--abort'];
  static const rebaseContinue = ['git', '-c', 'core.editor=true', 'rebase', '--continue'];

  static const init = ['git', 'init', '-b', 'main'];

  // --- 병합 (3.5) ---------------------------------------------------------

  /// [base]에 없는 [branch]의 커밋 (들어올 커밋).
  static List<String> incoming(String branch, {String base = 'HEAD'}) =>
      ['git', 'log', '--format=$commitFormat', '$base..$branch'];

  /// 종료 코드 0이면 [ancestor]가 [of]의 조상 — fast-forward 가능.
  static List<String> isAncestor(String ancestor, String of) =>
      ['git', 'merge-base', '--is-ancestor', ancestor, of];

  /// squash는 병합 결과를 스테이징만 하므로 커밋이 한 번 더 필요하다.
  static List<List<String>> merge(String branch, MergeMode mode, {String message = ''}) => switch (mode) {
        MergeMode.fastForward => [
            ['git', 'merge', '--ff-only', branch],
          ],
        MergeMode.mergeCommit => [
            ['git', 'merge', '--no-ff', if (message.isNotEmpty) ...['-m', message], '--no-edit', branch],
          ],
        MergeMode.squash => [
            ['git', 'merge', '--squash', branch],
            commit(message),
          ],
      };

  // --- 태그 (3.7) ---------------------------------------------------------

  static const tags = ['git', 'for-each-ref', '--format=$tagFormat', 'refs/tags'];
  static List<String> remoteTags(String remote) => ['git', 'ls-remote', '--tags', remote];

  static List<String> createTag(String name, {String? message, String? target}) => [
        'git',
        'tag',
        if (message != null) ...['-a', name, '-m', message] else name,
        ?target,
      ];

  static List<String> pushTags(String remote, List<String> names) =>
      ['git', 'push', remote, for (final n in names) 'refs/tags/$n'];
  static List<String> deleteTag(String name) => ['git', 'tag', '-d', name];
  static List<String> deleteRemoteTag(String remote, String name) =>
      ['git', 'push', remote, '--delete', 'refs/tags/$name'];

  // --- 릴리스 (3.8) -------------------------------------------------------

  /// 마지막 태그 (없으면 실패).
  static const lastTag = ['git', 'describe', '--tags', '--abbrev=0'];
  static List<String> log({String? since, String until = 'HEAD'}) =>
      ['git', 'log', '--format=$commitFormat', since == null ? until : '$since..$until'];
  static List<String> changedFiles(String since) => ['git', 'diff', '--name-only', '$since..HEAD'];

  /// 원격의 기본 브랜치 (`origin/main`).
  static List<String> remoteHead(String remote) => ['git', 'rev-parse', '--abbrev-ref', '$remote/HEAD'];
  static List<String> add(List<String> paths) => ['git', 'add', '--', ...paths];
  static const pullFastForward = ['git', 'pull', '--ff-only'];
}

enum RepoVisibility { public, private }

enum PrMergeMethod { merge, squash, rebase }

/// PR 목록 필터 (PLAN.md 3.9): 내가 만든 것 / 리뷰 요청받은 것 / 열린 것 전부.
enum PrFilter { mine, reviewRequested, open }

abstract final class GhCommands {
  static const version = ['gh', '--version'];
  static const authStatus = ['gh', 'auth', 'status', '--json', 'hosts'];

  /// 로컬 저장소를 GitHub에 새 저장소로 올린다 (PLAN.md 3.6).
  /// 커밋이 하나도 없으면 올릴 것이 없으므로 --push를 뺀다.
  static List<String> repoCreate({
    required String name,
    required RepoVisibility visibility,
    String description = '',
    String remote = 'origin',
    bool push = true,
  }) =>
      [
        'gh',
        'repo',
        'create',
        name,
        visibility == RepoVisibility.public ? '--public' : '--private',
        if (description.trim().isNotEmpty) ...['--description', description.trim()],
        '--source',
        '.',
        '--remote',
        remote,
        if (push) '--push',
      ];

  // --- PR (3.9) -----------------------------------------------------------

  /// 브랜치의 PR (열린 것 우선). 없으면 실패.
  static List<String> prView(String branchOrNumber, String fields) =>
      ['gh', 'pr', 'view', branchOrNumber, '--json', fields];

  /// 본문은 stdin으로 넘긴다 (--body-file -).
  static List<String> prCreate({required String base, required String head, required String title, bool draft = false}) =>
      ['gh', 'pr', 'create', '--base', base, '--head', head, '--title', title, '--body-file', '-', if (draft) '--draft'];

  static List<String> prList(PrFilter filter, String fields, {int limit = 30}) => [
        'gh', 'pr', 'list', '--state', 'open',
        ...switch (filter) {
          PrFilter.mine => ['--author', '@me'],
          PrFilter.reviewRequested => ['--search', 'review-requested:@me'],
          PrFilter.open => const <String>[],
        },
        '--json', fields, '-L', '$limit',
      ];

  /// PR 브랜치를 로컬로 가져와 전환한다.
  static List<String> prCheckout(int number) => ['gh', 'pr', 'checkout', '$number'];

  static List<String> prMerge(int number, PrMergeMethod method, {bool deleteBranch = true}) => [
        'gh',
        'pr',
        'merge',
        '$number',
        '--${method.name}',
        if (deleteBranch) '--delete-branch',
      ];

  // --- Actions·릴리스 (3.8.1, 3.8.5) --------------------------------------

  static List<String> runList({required String branch, String? workflow, String? event, int limit = 5}) => [
        'gh', 'run', 'list', '--branch', branch,
        if (workflow != null) ...['--workflow', workflow],
        if (event != null) ...['--event', event],
        '--json', 'databaseId,workflowName,status,conclusion,url,event,headBranch,createdAt,displayTitle',
        '-L', '$limit',
      ];
  static List<String> runView(int id) => [
        'gh', 'run', 'view', '$id', '--json',
        'databaseId,workflowName,status,conclusion,url,event,headBranch,createdAt,jobs,displayTitle',
      ];
  static List<String> runFailedLog(int id) => ['gh', 'run', 'view', '$id', '--log-failed'];
  static List<String> runRerunFailed(int id) => ['gh', 'run', 'rerun', '$id', '--failed'];
  static List<String> runRerun(int id) => ['gh', 'run', 'rerun', '$id'];
  static List<String> runCancel(int id) => ['gh', 'run', 'cancel', '$id'];
  static const workflowList = ['gh', 'workflow', 'list', '--json', 'id,name,path,state'];
  static List<String> workflowRun(String file, String ref) => ['gh', 'workflow', 'run', file, '--ref', ref];

  static List<String> releaseView(String tag) =>
      ['gh', 'release', 'view', tag, '--json', 'tagName,name,url,isPrerelease,isDraft,body,assets'];

  /// 노트는 stdin (--notes-file -).
  static List<String> releaseCreate(String tag, {required String title, bool prerelease = false}) =>
      ['gh', 'release', 'create', tag, '--title', title, '--notes-file', '-', '--verify-tag', if (prerelease) '--prerelease'];
  static List<String> releaseEditNotes(String tag) => ['gh', 'release', 'edit', tag, '--notes-file', '-'];

  // --- 릴리스 관리 (3.8.6) ------------------------------------------------

  static List<String> releaseList({int limit = 30}) =>
      ['gh', 'release', 'list', '--json', 'tagName,name,isLatest,isPrerelease,isDraft,publishedAt', '-L', '$limit'];
  static List<String> releaseSetPrerelease(String tag, bool prerelease) =>
      ['gh', 'release', 'edit', tag, '--prerelease=$prerelease'];
  static List<String> releasePublishDraft(String tag) => ['gh', 'release', 'edit', tag, '--draft=false'];

  /// [cleanupTag]면 태그도 함께 지운다 (로컬 태그는 남는다).
  static List<String> releaseDelete(String tag, {bool cleanupTag = false}) =>
      ['gh', 'release', 'delete', tag, '--yes', if (cleanupTag) '--cleanup-tag'];
}
