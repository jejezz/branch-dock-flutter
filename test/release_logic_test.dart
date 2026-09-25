import 'package:branch_dock/git/commands.dart';
import 'package:branch_dock/git/commits.dart';
import 'package:branch_dock/git/tags.dart';
import 'package:branch_dock/github/models.dart';
import 'package:branch_dock/release/repo_release_info.dart';
import 'package:branch_dock/release/version_files.dart';
import 'package:flutter_test/flutter_test.dart';

Commit c(String subject, {String body = ''}) => Commit(hash: 'h', shortHash: 'abc1234', subject: subject, body: body);

void main() {
  group('SemVer', () {
    test('parse and compare', () {
      final v = SemVer.tryParse('v1.4.2-rc.1+37')!;
      expect((v.major, v.minor, v.patch, v.pre, v.build), (1, 4, 2, 'rc.1', 37));
      expect(v.name, '1.4.2-rc.1');
      expect(v.tag, 'v1.4.2-rc.1');
      expect(SemVer.tryParse('1.0.0-rc.2')!.compareTo(SemVer.tryParse('1.0.0-rc.10')!), lessThan(0));
      expect(SemVer.tryParse('1.0.0-rc.9')!.compareTo(SemVer.tryParse('1.0.0')!), lessThan(0));
      expect(SemVer.tryParse('release-1'), isNull);
    });

    test('tags sort by version, newest first', () {
      final tags = [
        for (final n in ['v0.1.0-rc.1', 'v0.1.0', 'old', 'v0.1.0-rc.2', 'v0.10.0', 'v0.2.0'])
          Tag(name: n, commit: 'x', annotated: true),
      ];
      expect(sortTags(tags).map((t) => t.name), ['v0.10.0', 'v0.2.0', 'v0.1.0', 'v0.1.0-rc.2', 'v0.1.0-rc.1', 'old']);
    });

    test('validateTagName', () {
      expect(validateTagName('v1.2.3'), isNull);
      expect(validateTagName('1.2.3'), TagNameProblem.missingV);
      expect(validateTagName('release'), TagNameProblem.notSemVer);
      expect(validateTagName('v 1'), TagNameProblem.invalid);
      expect(validateTagName(''), TagNameProblem.empty);
    });
  });

  test('Tag.parse annotated and lightweight, parseRemote', () {
    const out = 'v0.2.0\x00tag\x00c0ffee\x00t4g\x001700000000\x00Branch Dock 0.2.0\n'
        'light\x00commit\x00\x00beef\x001700000000\x00subject of commit\n';
    final t = Tag.parse(out);
    expect(t.first.name, 'v0.2.0');
    expect((t.first.annotated, t.first.commit, t.first.subject), (true, 'c0ffee', 'Branch Dock 0.2.0'));
    expect((t.last.annotated, t.last.commit, t.last.subject), (false, 'beef', ''));
    expect(Tag.parseRemote('a\trefs/tags/v1.0.0\nb\trefs/tags/v1.0.0^{}\nc\trefs/tags/x\n'), {'v1.0.0', 'x'});
  });

  test('Commit kinds, breaking, parse', () {
    expect(c('feat(ui): add').kind, CommitKind.feat);
    expect(c('fix: x').description, 'x');
    expect(c('feat!: drop api').breaking, isTrue);
    expect(c('refactor: y', body: 'BREAKING CHANGE: z').breaking, isTrue);
    expect(c('Update readme').kind, CommitKind.other);
    expect(c('Merge pull request #3 from a/b').isMerge, isTrue);
    final parsed = Commit.parse('H1\x00h1\x00feat: a\x00body\x001700000000\x1e\nH2\x00h2\x00fix: b\x00\x001700000001\x1e');
    expect(parsed.map((e) => e.subject), ['feat: a', 'fix: b']);
  });

  group('version bump', () {
    final v = SemVer.tryParse('0.1.0+3')!;
    test('kinds and build number', () {
      expect(bump(v, BumpKind.patch).toString(), '0.1.1+4');
      expect(bump(v, BumpKind.minor).toString(), '0.2.0+4');
      expect(bump(v, BumpKind.major).toString(), '1.0.0+4');
      expect(bump(v, BumpKind.prerelease).toString(), '0.1.1-rc.1+4');
      final rc = SemVer.tryParse('0.2.0-rc.2+5')!;
      expect(bump(rc, BumpKind.patch).toString(), '0.2.0+6'); // 프리릴리스 → 정식
      expect(bump(rc, BumpKind.prerelease).toString(), '0.2.0-rc.3+6');
      expect(bump(SemVer.tryParse('1.2.3')!, BumpKind.minor).toString(), '1.3.0'); // build 없음
    });

    test('suggestion from commits', () {
      expect(suggestBump(v, [c('fix: a'), c('docs: b')]).kind, BumpKind.patch);
      expect(suggestBump(v, [c('feat: a'), c('fix: b')]).kind, BumpKind.minor);
      expect(suggestBump(v, [c('feat!: a')]).kind, BumpKind.minor); // 0.y.z
      expect(suggestBump(SemVer.tryParse('1.0.0')!, [c('feat!: a')]).kind, BumpKind.major);
      final s = suggestBump(v, [c('feat: a'), c('feat: b'), c('fix: c'), c('Merge pull request #1')]);
      expect((s.feats, s.fixes), (2, 1));
    });

    test('read and write each file kind', () {
      const pub = 'name: x\nversion: 0.1.0+3\ndependencies:\n  foo: ^1.0.0\n';
      expect(readVersion(VersionFileKind.pubspec, pub).toString(), '0.1.0+3');
      expect(writeVersion(VersionFileKind.pubspec, pub, SemVer.tryParse('0.2.0+4')!), contains('version: 0.2.0+4\n'));
      const cargo = '[package]\nname = "x"\nversion = "0.1.0"\n\n[dependencies]\nserde = { version = "1.0" }\n';
      final w = writeVersion(VersionFileKind.cargo, cargo, SemVer.tryParse('0.2.0')!);
      expect(w, contains('version = "0.2.0"'));
      expect(w, contains('serde = { version = "1.0" }'));
      const pkg = '{\n  "name": "x",\n  "version": "1.0.0"\n}\n';
      expect(writeVersion(VersionFileKind.packageJson, pkg, SemVer.tryParse('1.1.0')!), contains('"version": "1.1.0"'));
    });
  });

  test('workflow triggers', () {
    const release = 'name: Release\non:\n  push:\n    tags:\n      - "v*"\n  workflow_dispatch:\n\njobs:\n  a:\n    runs-on: x\n';
    expect(parseWorkflowTriggers(release), (true, true));
    const ci = 'on:\n  push:\n    branches: [main]\n  pull_request:\njobs: {}\n';
    expect(parseWorkflowTriggers(ci), (false, false));
    expect(parseWorkflowTriggers('on: [push, workflow_dispatch]\n'), (false, true));
  });

  test('buildRiskFiles and release notes draft', () {
    expect(buildRiskFiles(['lib/a.dart', 'pubspec.lock', 'macos/Runner/Release.entitlements', '.github/workflows/r.yml']),
        ['pubspec.lock', 'macos/Runner/Release.entitlements', '.github/workflows/r.yml']);
    final notes = draftReleaseNotes(
      [c('feat: 태그 탭'), c('fix: 정렬'), c('docs: README'), c('chore(release): v0.2.0'), c('Merge pull request #9')],
      featuresTitle: 'New',
      fixesTitle: 'Fixes',
      otherTitle: 'Other',
    );
    expect(notes, '## New\n\n- 태그 탭 (abc1234)\n\n## Fixes\n\n- 정렬 (abc1234)\n\n## Other\n\n- README (abc1234)');
  });

  test('gh models', () {
    final pr = PullRequest.parse('{"number":4,"title":"t","url":"u","state":"OPEN","isDraft":false,'
        '"mergeable":"MERGEABLE","mergeStateStatus":"CLEAN","reviewDecision":"",'
        '"statusCheckRollup":[{"__typename":"CheckRun","name":"test","status":"COMPLETED","conclusion":"SUCCESS"},'
        '{"__typename":"CheckRun","name":"lint","status":"COMPLETED","conclusion":"FAILURE"},'
        '{"__typename":"StatusContext","context":"ci","state":"PENDING"}],'
        '"headRefName":"release/v0.2.0","baseRefName":"main","mergeCommit":null}')!;
    expect((pr.checks.passed, pr.checks.failed, pr.checks.pending), (1, 1, 1));
    expect(pr.checks.failedNames, ['lint']);
    expect(pr.canMerge, isFalse);
    expect(PullRequest.parse('{"number":4,"state":"MERGED","mergeCommit":{"oid":"abc"}}')!.merged, isTrue);

    final run = WorkflowRun.parse('{"databaseId":1,"workflowName":"Release","status":"completed","conclusion":"failure",'
        '"url":"u","jobs":[{"name":"build-macos","status":"completed","conclusion":"failure",'
        '"startedAt":"2026-09-25T03:38:38Z","completedAt":"2026-09-25T03:41:00Z",'
        '"steps":[{"name":"Build","conclusion":"success"},{"name":"Sign app","conclusion":"failure"}]},'
        '{"name":"release","status":"completed","conclusion":"skipped","startedAt":"0001-01-01T00:00:00Z"}]}')!;
    expect(run.state, RunState.failure);
    expect(run.jobs.first.failedStep, 'Sign app');
    expect(run.jobs.first.duration, const Duration(minutes: 2, seconds: 22));
    expect(run.jobs.last.state, RunState.skipped);
    expect(WorkflowRun.parseList('[{"databaseId":2,"status":"in_progress","conclusion":""}]').single.state,
        RunState.running);
  });

  test('commands', () {
    expect(GitCommands.merge('feature', MergeMode.squash, message: 'feat: x'),
        [['git', 'merge', '--squash', 'feature'], ['git', 'commit', '-m', 'feat: x']]);
    expect(GitCommands.createTag('v1.0.0', message: 'App 1.0.0'), ['git', 'tag', '-a', 'v1.0.0', '-m', 'App 1.0.0']);
    expect(GitCommands.createTag('light', target: 'abc'), ['git', 'tag', 'light', 'abc']);
    expect(GitCommands.pushTags('origin', ['v1', 'v2']), ['git', 'push', 'origin', 'refs/tags/v1', 'refs/tags/v2']);
    expect(GhCommands.prMerge(4, PrMergeMethod.merge), ['gh', 'pr', 'merge', '4', '--merge', '--delete-branch']);
  });
}
