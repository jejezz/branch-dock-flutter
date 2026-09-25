import 'package:branch_dock/core/command_log.dart';
import 'package:branch_dock/git/commands.dart';
import 'package:branch_dock/git/error_hints.dart';
import 'package:branch_dock/git/refs.dart';
import 'package:branch_dock/git/remotes.dart';
import 'package:branch_dock/git/status.dart';
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

  test('environment parsing', () {
    expect(EnvironmentStatus.parseVersion('git version 2.50.1 (Apple Git-155)'), '2.50.1');
    expect(
      EnvironmentStatus.parseAuthHosts('{"hosts":{"github.com":[{"state":"success","active":true,"login":"me"}]}}'),
      {'github.com': 'me'},
    );
    expect(EnvironmentStatus.parseAuthHosts('not json'), isEmpty);
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
  });
}
