import 'package:branch_dock/core/command_log.dart';
import 'package:branch_dock/git/commands.dart';
import 'package:branch_dock/git/error_hints.dart';
import 'package:branch_dock/git/refs.dart';
import 'package:branch_dock/git/remotes.dart';
import 'package:branch_dock/git/status.dart';
import 'package:branch_dock/git/worktrees.dart';
import 'package:branch_dock/repo/environment.dart';
import 'package:branch_dock/repo/next_action.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RepoStatus.parse', () {
    test('branch headers and every entry type', () {
      const out = '# branch.oid 1234abcd\x00'
          '# branch.head feature/login\x00'
          '# branch.upstream origin/feature/login\x00'
          '# branch.ab +2 -3\x00'
          '1 M. N... 100644 100644 100644 aaa bbb lib/main.dart\x00'
          '1 .M N... 100644 100644 100644 aaa bbb docs/a b.md\x00'
          '2 R. N... 100644 100644 100644 aaa bbb R100 lib/new name.dart\x00lib/old.dart\x00'
          'u UU N... 100644 100644 100644 100644 a b c pubspec.yaml\x00'
          '? notes.txt\x00';
      final s = RepoStatus.parse(out);
      expect(s.head, 'feature/login');
      expect(s.oid, '1234abcd');
      expect(s.upstream, 'origin/feature/login');
      expect((s.ahead, s.behind), (2, 3));
      expect(s.files, hasLength(5));
      expect(s.staged.map((f) => f.path), ['lib/main.dart', 'lib/new name.dart']);
      expect(s.unstaged.single.path, 'docs/a b.md');
      expect(s.files[2].originalPath, 'lib/old.dart');
      expect(s.files[2].stagedKind, ChangeKind.renamed);
      expect(s.conflicts.single.path, 'pubspec.yaml');
      expect(s.untracked.single.fileName, 'notes.txt');
      expect(s.files[1].directory, 'docs/');
    });

    test('unborn and detached', () {
      expect(RepoStatus.parse('# branch.oid (initial)\x00# branch.head main\x00').unborn, isTrue);
      final d = RepoStatus.parse('# branch.oid abc\x00# branch.head (detached)\x00');
      expect(d.detached, isTrue);
      final gone = RepoStatus.parse('# branch.oid abc\x00# branch.head main\x00# branch.upstream origin/main\x00');
      expect((gone.upstreamGone, gone.hasUpstream), (true, false));
      expect(d.clean, isTrue);
    });
  });

  test('Branch.parse local, remote, gone, symbolic HEAD skipped', () {
    const out = 'refs/heads/main\x00main\x00origin/main\x00[ahead 1, behind 2]\x001700000000\x00init\x00*\n'
        'refs/heads/old\x00old\x00origin/old\x00[gone]\x001700000000\x00x\x00 \n'
        'refs/remotes/origin/HEAD\x00origin\x00\x00\x001700000000\x00init\x00 \n'
        'refs/remotes/origin/feature/a\x00origin/feature/a\x00\x00\x001700000000\x00feat\x00 \n';
    final b = Branch.parse(out);
    expect(b, hasLength(3));
    expect(b[0].current, isTrue);
    expect((b[0].ahead, b[0].behind), (1, 2));
    expect(b[1].upstreamGone, isTrue);
    expect(b[2].remote, isTrue);
    expect(b[2].remoteName, 'origin');
    expect(b[2].shortName, 'feature/a');
  });

  test('validateBranchName', () {
    expect(validateBranchName('feature/login'), isNull);
    expect(validateBranchName(''), BranchNameProblem.empty);
    expect(validateBranchName('a b'), BranchNameProblem.invalidCharacter);
    expect(validateBranchName('a..b'), BranchNameProblem.invalidSequence);
    expect(validateBranchName('-x'), BranchNameProblem.startsWithDash);
    expect(validateBranchName('x/'), BranchNameProblem.invalidEdge);
    expect(validateBranchName('x.lock'), BranchNameProblem.invalidSequence);
  });

  group('remotes', () {
    test('parse git remote -v', () {
      final r = Remote.parse('origin\thttps://github.com/a/b.git (fetch)\n'
          'origin\thttps://github.com/a/b.git (push)\n'
          'lab\tgit@gitlab.com:a/b.git (fetch)\n'
          'lab\tgit@gitlab.com:a/b.git (push)\n');
      expect(r.map((e) => e.name), ['origin', 'lab']);
      expect(r[0].isGitHub, isTrue);
      expect(r[1].host, RemoteHost.gitlab);
    });

    test('RemoteLocation formats', () {
      final https = RemoteLocation.parse('https://github.com/jejezz/branch-dock-flutter.git')!;
      expect((https.host, https.path, https.ssh), ('github.com', 'jejezz/branch-dock-flutter', false));
      final scp = RemoteLocation.parse('git@github.com:jejezz/x.git')!;
      expect((scp.host, scp.path, scp.ssh), ('github.com', 'jejezz/x', true));
      final ssh = RemoteLocation.parse('ssh://git@bitbucket.org:22/team/x')!;
      expect((ssh.kind, ssh.path), (RemoteHost.bitbucket, 'team/x'));
      expect(RemoteLocation.parse('/srv/git/x.git'), isNull);
      expect(RemoteLocation.parse(r'C:\repos\x'), isNull);
      expect(scp.httpsUrl, 'https://github.com/jejezz/x.git');
    });
  });

  test('commands', () {
    expect(GitCommands.pull(PullMode.fastForwardOnly), ['git', 'pull', '--ff-only']);
    expect(GitCommands.publish('origin', 'x'), ['git', 'push', '-u', 'origin', 'x']);
    expect(GitCommands.unstage('a', unborn: true), ['git', 'rm', '--cached', '-r', '-q', '--', 'a']);
    expect(GitCommands.createBranch('x', base: 'main', switchAfter: false), ['git', 'branch', 'x', 'main']);
    expect(
      GhCommands.repoCreate(name: 'x', visibility: RepoVisibility.private, push: false),
      ['gh', 'repo', 'create', 'x', '--private', '--source', '.', '--remote', 'origin'],
    );
    expect(formatCommandLine(GitCommands.commit("feat: it's done")), "git commit -m 'feat: it'\\''s done'");
  });

  test('classifyError', () {
    expect(
      classifyError(' ! [rejected]        main -> main (fetch first)\nerror: failed to push some refs'),
      GitErrorKind.pushRejected,
    );
    expect(classifyError('fatal: Not possible to fast-forward, aborting.'), GitErrorKind.notFastForward);
    expect(classifyError("error: The branch 'x' is not fully merged."), GitErrorKind.branchNotMerged);
    expect(classifyError('fatal: could not read Username for'), GitErrorKind.authFailed);
    expect(classifyError('whatever'), isNull);
  });

  test('classifyError: branch checked out in another worktree', () {
    const current = "fatal: 'claude/fix-9eae90' is already used by worktree at '/Users/me/repo/.claude/worktrees/fix'";
    const older = "fatal: 'main' is already checked out at '/tmp/other wt'";
    expect(classifyError(current), GitErrorKind.branchInOtherWorktree);
    expect(worktreePathFromError(current), '/Users/me/repo/.claude/worktrees/fix');
    expect(classifyError(older), GitErrorKind.branchInOtherWorktree);
    expect(worktreePathFromError(older), '/tmp/other wt');
    expect(worktreePathFromError('fatal: something else'), isNull);
  });

  test('environment parsing', () {
    expect(EnvironmentStatus.parseVersion('git version 2.50.1 (Apple Git-155)'), '2.50.1');
    expect(
      EnvironmentStatus.parseAuthHosts('{"hosts":{"github.com":[{"state":"success","active":true,"login":"me"}]}}'),
      {'github.com': 'me'},
    );
    expect(EnvironmentStatus.parseAuthHosts('not json'), isEmpty);
  });

  test('environment: minimum versions and diagnostics', () {
    expect(EnvironmentStatus.compareVersions('2.9.1', '2.30.0'), -1);
    expect(EnvironmentStatus.compareVersions('2.30', '2.30.0'), 0);
    expect(EnvironmentStatus.compareVersions('2.101.0', '2.81.0'), 1);
    const old = EnvironmentStatus(gitVersion: '2.25.1', ghVersion: '2.45.0', checked: true);
    expect((old.gitTooOld, old.ghTooOld), (true, true));
    const env = EnvironmentStatus(
      gitVersion: '2.50.1',
      ghVersion: '2.81.0',
      ghLogins: {'github.com': 'me'},
      checked: true,
      gitPath: '/opt/git/bin/git',
      gitCustom: true,
      searchPath: '/usr/bin:/bin',
    );
    expect((env.gitTooOld, env.ghTooOld), (false, false));
    final text = env.diagnostics(appVersion: '0.9.0+15', os: 'macos 26');
    expect(text, contains('Branch Dock 0.9.0+15'));
    expect(text, contains('OS: macos 26'));
    expect(text, contains('git: 2.50.1 — /opt/git/bin/git [custom]'));
    expect(text, contains('gh: 2.81.0 — -'));
    expect(text, contains('gh login: github.com (me)'));
    expect(old.diagnostics(appVersion: '?'), contains('git: 2.25.1 (below 2.30.0)'));
  });

  test('suggestNextAction priority', () {
    const origin = Remote(name: 'origin', fetchUrl: 'https://github.com/a/b', pushUrl: 'https://github.com/a/b');
    NextAction? s(RepoStatus st, [List<Remote> r = const [origin]]) => suggestNextAction(status: st, remotes: r);
    expect(s(const RepoStatus(oid: 'a', head: 'main', upstream: 'origin/main', behind: 2, ahead: 1))!.kind,
        NextActionKind.pull);
    expect(s(const RepoStatus(oid: 'a', head: 'x'))!.kind, NextActionKind.publish);
    expect(s(const RepoStatus(oid: 'a', head: 'main', upstream: 'origin/main', ahead: 2)),
        const NextAction(NextActionKind.push, 2));
    expect(s(const RepoStatus(oid: 'a', head: 'main'), const [])!.kind, NextActionKind.publishToGitHub);
    expect(s(const RepoStatus(oid: 'a', head: 'main', upstream: 'origin/main')), isNull);
    // 병합되어 원격에서 지워진 브랜치: 게시가 아니라 기본 브랜치로 전환.
    expect(
      suggestNextAction(
        status: const RepoStatus(oid: 'a', head: 'feat/x', upstream: 'origin/feat/x', upstreamGone: true),
        remotes: const [origin],
        headMergedAndGone: true,
      )!.kind,
      NextActionKind.switchToDefault,
    );
    // 다 올렸는데 PR이 없으면 PR 만들기. 올릴 커밋이 남아 있으면 Push가 먼저.
    const pushed = RepoStatus(oid: 'a', head: 'feat/y', upstream: 'origin/feat/y');
    expect(suggestNextAction(status: pushed, remotes: const [origin], suggestPr: true)!.kind, NextActionKind.createPr);
    expect(
      suggestNextAction(
        status: const RepoStatus(oid: 'a', head: 'feat/y', upstream: 'origin/feat/y', ahead: 1),
        remotes: const [origin],
        suggestPr: true,
      )!.kind,
      NextActionKind.push,
    );
    expect(suggestNextAction(status: pushed, remotes: const [origin]), isNull);
  });

  test('Worktree.parse: main, branch, detached, locked, prunable, Claude folder', () {
    const out = 'worktree /r\nHEAD aaa\nbranch refs/heads/main\n\n'
        'worktree /r/.claude/worktrees/x\nHEAD bbb\nbranch refs/heads/claude/x\nlocked\n\n'
        'worktree /r/.claude/worktrees/y\nHEAD ccc\ndetached\n\n'
        'worktree /gone\nHEAD ddd\nbranch refs/heads/old\nprunable gitdir file points to non-existent location\n';
    final w = Worktree.parse(out);
    expect(w.map((e) => e.path), ['/r', '/r/.claude/worktrees/x', '/r/.claude/worktrees/y', '/gone']);
    expect(w.map((e) => e.main), [true, false, false, false]);
    expect(w.map((e) => e.branch), ['main', 'claude/x', null, 'old']);
    expect((w[1].locked, w[1].byClaude, w[1].name), (true, true, 'x'));
    expect((w[2].detached, w[3].prunable, w[0].byClaude), (true, true, false));
  });
}
