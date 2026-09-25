/// git·gh 명령 인자 만들기. 실행 전에 "실행될 명령"으로 그대로 보여 준다
/// (PLAN.md 핵심 원칙 1). 순수 함수라 테스트로 확인한다.
library;

import 'refs.dart';

enum PullMode { merge, rebase, fastForwardOnly }

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
}

enum RepoVisibility { public, private }

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
}
