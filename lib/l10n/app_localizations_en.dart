// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get aboutTooltip => 'About';

  @override
  String aboutVersion(String version, String build) {
    return 'Version $version (build $build)';
  }

  @override
  String get aboutOpenSourceLicenses => 'Open Source Licenses';

  @override
  String get aboutRepository => 'GitHub';

  @override
  String get commonClose => 'Close';

  @override
  String aboutMenuItem(String appName) {
    return 'About $appName';
  }

  @override
  String get themeMenuTooltip => 'Theme';

  @override
  String get themeSystem => 'Follow System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get languageMenuTooltip => 'Language';

  @override
  String get languageSystem => 'System / 시스템 설정 따르기';

  @override
  String get languageSystemShort => 'System';

  @override
  String get aboutTagline => 'A desktop companion for Git and the GitHub CLI';

  @override
  String get aboutDescription =>
      'Dock it beside your editor and handle branches, tags, merges, pull/push, remotes and releases with buttons that show the exact git and gh commands they run.';

  @override
  String get homeEmptyTitle => 'Choose a repository to get started';

  @override
  String get homeEmptyAction => 'Open repository';

  @override
  String get appBarRefresh => 'Refresh';

  @override
  String get appBarPin => 'Keep on top';

  @override
  String get appBarUnpin => 'Stop keeping on top';

  @override
  String get menuOpenFolder => 'Open another folder…';

  @override
  String get menuEditor => 'Editor for opening files…';

  @override
  String get menuEnvironment => 'Check git and gh';

  @override
  String get menuCloseRepo => 'Close repository';

  @override
  String get hostOther => 'Other git server';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonCopy => 'Copy';

  @override
  String get commonCopied => 'Copied';

  @override
  String get commonMore => 'More';

  @override
  String get commonSave => 'Save';

  @override
  String get commandPreviewLabel => 'Command to run';

  @override
  String get startDropHint =>
      'You can also drop a git repository folder on this window.';

  @override
  String get startRecent => 'Recent repositories';

  @override
  String get startRemoveRecent => 'Remove from list';

  @override
  String startNotARepository(String path) {
    return 'This folder isn\'t a git repository: $path';
  }

  @override
  String startNotFound(String path) {
    return 'Folder not found: $path';
  }

  @override
  String get envTitle => 'git and GitHub CLI';

  @override
  String get envGitRequired =>
      'Branch Dock runs the git installed on your computer. Install git first.';

  @override
  String get envGitOnlyNote =>
      'Branches, pull and push work without gh. Publishing to GitHub, pull requests and releases need gh and a login.';

  @override
  String envVersion(String version) {
    return 'Version $version';
  }

  @override
  String get envNotInstalled => 'Not installed, or not found';

  @override
  String get envLogin => 'GitHub login';

  @override
  String envLoggedInAs(String login) {
    return 'Logged in as $login';
  }

  @override
  String get envNotLoggedIn => 'Not logged in. Run this in a terminal.';

  @override
  String get envRecheck => 'Check again';

  @override
  String get envGhMissing =>
      'Needs the GitHub CLI (gh), which isn\'t installed. See Check git and gh in the menu.';

  @override
  String get envGhLoggedOut =>
      'Log in to gh first: run gh auth login in a terminal.';

  @override
  String get headerBranchTooltip => 'Show branches';

  @override
  String get headerDetached => 'Detached HEAD';

  @override
  String get headerNoUpstream => 'Not on remote';

  @override
  String get headerNoUpstreamTooltip =>
      'This branch isn\'t on the remote yet. Publish it to push it there.';

  @override
  String headerAheadTooltip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commits',
      one: '1 commit',
    );
    return '$_temp0 not on the remote yet';
  }

  @override
  String headerBehindTooltip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count remote commits',
      one: '1 remote commit',
    );
    return '$_temp0 you don\'t have yet';
  }

  @override
  String headerChanges(int count) {
    return '$count changed';
  }

  @override
  String get headerUpToDate => 'Up to date';

  @override
  String get headerNoCommits => 'No commits yet';

  @override
  String headerMerging(int count) {
    return 'Merging · $count conflicts';
  }

  @override
  String headerRebasing(int count) {
    return 'Rebasing · $count conflicts';
  }

  @override
  String get headerFetch => 'Fetch';

  @override
  String get headerPull => 'Pull';

  @override
  String get headerPush => 'Push';

  @override
  String get headerPublish => 'Publish';

  @override
  String get pullModeTooltip => 'Pull method';

  @override
  String get pullModeTitle => 'How to pull';

  @override
  String get pullModeMerge => 'Merge (default)';

  @override
  String get pullModeMergeWhen =>
      'If both sides have new commits, joins them with a merge commit. The safest choice.';

  @override
  String get pullModeRebase => 'Rebase';

  @override
  String get pullModeRebaseWhen =>
      'Moves your commits on top of the new ones to keep history in one line.';

  @override
  String get pullModeFastForward => 'Fast-forward only';

  @override
  String get pullModeFastForwardWhen =>
      'Only pulls when you have no commits of your own; stops and tells you if history has split.';

  @override
  String get operationAbort => 'Abort';

  @override
  String get operationContinue => 'Continue';

  @override
  String get operationContinueBlocked => 'Resolve every conflict to continue';

  @override
  String get operationAbortTitle => 'Abort the operation in progress?';

  @override
  String get operationAbortMergeMessage =>
      'Goes back to before the merge started. Any conflict resolutions you\'ve made are lost.';

  @override
  String get operationAbortRebaseMessage =>
      'Goes back to before the rebase started. Any conflict resolutions you\'ve made are lost.';

  @override
  String bannerConflicts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files have',
      one: '1 file has',
    );
    return '$_temp0 conflicts to resolve';
  }

  @override
  String bannerPull(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new commits',
      one: '1 new commit',
    );
    return '$_temp0 on the remote';
  }

  @override
  String get bannerPublish => 'This branch isn\'t on the remote yet';

  @override
  String bannerPush(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commits aren\'t',
      one: '1 commit isn\'t',
    );
    return '$_temp0 on the remote yet';
  }

  @override
  String get bannerNoRemote => 'This repository isn\'t on GitHub yet';

  @override
  String get bannerShow => 'Show';

  @override
  String bannerNotGitHub(String host) {
    return 'This is a $host repository. Branches, pull and push all work; pull requests, releases and Actions need a GitHub repository.';
  }

  @override
  String get tabChanges => 'Changes';

  @override
  String get tabBranches => 'Branches';

  @override
  String get tabRemotes => 'Remotes';

  @override
  String get changesMessageHint => 'Commit message';

  @override
  String get changesPrefixTooltip => 'Commit type prefix';

  @override
  String changesFirstLineLong(int length) {
    return 'The first line is $length characters. Keep it under 72 so it isn\'t cut off in lists.';
  }

  @override
  String changesCommitStaged(int count) {
    return 'Commit ($count staged)';
  }

  @override
  String get changesCommitAll => 'Stage all and commit';

  @override
  String get changesConflicts => 'Conflicts';

  @override
  String get changesStaged => 'Staged';

  @override
  String get changesUnstaged => 'Changed';

  @override
  String get changesUntracked => 'Untracked';

  @override
  String get changesStageAll => 'Stage all';

  @override
  String get changesUnstageAll => 'Unstage all';

  @override
  String get changesStage => 'Stage';

  @override
  String get changesUnstage => 'Unstage';

  @override
  String get changesOpenInEditor => 'Open in editor';

  @override
  String get changesMarkResolved => 'Resolved';

  @override
  String get changesCleanTitle => 'Nothing to commit';

  @override
  String get changesCleanMessage =>
      'Save a file in your editor and it shows up here.';

  @override
  String get branchesTitle => 'Branches';

  @override
  String get branchesNew => 'New branch';

  @override
  String get branchesCreate => 'Create';

  @override
  String get branchesSearchHint => 'Find a branch';

  @override
  String get branchesLocal => 'Local';

  @override
  String get branchesRemote => 'Remote';

  @override
  String get branchesSwitch => 'Switch to';

  @override
  String get branchesRename => 'Rename';

  @override
  String get branchesDelete => 'Delete';

  @override
  String get branchesDeleteRemote => 'Delete from remote';

  @override
  String get branchesUpstreamGone => 'Gone on remote';

  @override
  String get branchesUnbornTitle => 'No commits yet';

  @override
  String get branchesUnbornMessage =>
      'Make the first commit, then you can create branches.';

  @override
  String get branchesForceDeleteTitle => 'This branch isn\'t merged';

  @override
  String branchesForceDeleteMessage(String name) {
    return '$name has commits that aren\'t merged into another branch. Deleting it makes them hard to find.';
  }

  @override
  String get branchesDeleteRemoteTitle => 'Delete the remote branch?';

  @override
  String branchesDeleteRemoteMessage(String branch, String target) {
    return 'Deletes $branch from $target. Nobody else can fetch it after this.';
  }

  @override
  String get branchNameLabel => 'Branch name';

  @override
  String get branchNameExists => 'A branch with this name already exists';

  @override
  String get branchNameEmpty => 'Enter a name';

  @override
  String get branchNameInvalidCharacter =>
      'Spaces and ~ ^ : ? * [ \\ aren\'t allowed';

  @override
  String get branchNameStartsWithDash => 'Can\'t start with -';

  @override
  String get branchNameInvalidSequence =>
      'Can\'t contain .. or //, a part starting with ., or a part ending in .lock';

  @override
  String get branchNameInvalidEdge => 'Can\'t start with / or end with / or .';

  @override
  String get branchBaseLabel => 'Start from';

  @override
  String branchBaseCurrent(String name) {
    return 'Current branch ($name)';
  }

  @override
  String get branchSwitchAfter => 'Switch to it after creating';

  @override
  String branchRenameUpstreamNote(String upstream) {
    return '$upstream on the remote keeps its old name. Publish again under the new name.';
  }

  @override
  String get remotesTitle => 'Remotes';

  @override
  String get remotesAdd => 'Add remote';

  @override
  String get remotesRename => 'Rename';

  @override
  String get remotesSetUrl => 'Change URL';

  @override
  String get remotesRemove => 'Remove remote';

  @override
  String get remotesRemoveTitle => 'Remove this remote?';

  @override
  String remotesRemoveMessage(String name) {
    return 'Only removes the $name link from this repository. The repository on the server stays.';
  }

  @override
  String get remotesEmptyTitle => 'This repository isn\'t on GitHub yet';

  @override
  String get remotesEmptyMessage =>
      'Creates a new repository on GitHub and pushes your current branch.';

  @override
  String get remotesPublishToGitHub => 'Publish to GitHub';

  @override
  String get remotesPublishAlsoToGitHub =>
      'Also publish to GitHub (adds a remote)';

  @override
  String get remotesPublishConfirm => 'Create and publish';

  @override
  String get remotesNotGitHubNote =>
      'Not a GitHub repository, so pull requests, releases and Actions aren\'t available (gh is GitHub-only).';

  @override
  String get remotesNameLabel => 'Remote name';

  @override
  String get remotesNameTaken => 'A remote with this name already exists';

  @override
  String get remotesNameInvalid => 'No spaces or special characters';

  @override
  String get remotesUrlLabel => 'URL';

  @override
  String get remotesUseHttps => 'Use the HTTPS address';

  @override
  String get remotesUseSsh => 'Use the SSH address';

  @override
  String get publishNameLabel => 'Repository name';

  @override
  String get publishNameHelper =>
      'Use org/name to create it in an organization';

  @override
  String get publishNameInvalid => 'Letters, numbers, - _ . only';

  @override
  String get publishDescriptionLabel => 'Description (optional)';

  @override
  String get publishPrivate => 'Private';

  @override
  String get publishPublic => 'Public';

  @override
  String get publishNoCommitsNote =>
      'There are no commits yet, so this only creates the repository. Push after your first commit.';

  @override
  String get editorTitle => 'Editor for opening files';

  @override
  String get editorMessage =>
      'Enter an editor command to open files with it. Leave it empty to use the system default app.';

  @override
  String get editorLabel => 'Editor command';

  @override
  String get logTitle => 'Command log';

  @override
  String get logClear => 'Clear';

  @override
  String get logEmpty => 'No commands run yet';

  @override
  String get logToggleTooltip => 'Show or hide the command log';

  @override
  String get doneFetch => 'Fetched from the remote';

  @override
  String get donePull => 'Pulled';

  @override
  String get donePush => 'Pushed';

  @override
  String donePublish(String branch) {
    return 'Published $branch';
  }

  @override
  String get doneCommit => 'Committed';

  @override
  String doneSwitch(String name) {
    return 'Switched to $name';
  }

  @override
  String doneCreateBranch(String name) {
    return 'Created $name';
  }

  @override
  String doneRenameBranch(String name) {
    return 'Renamed to $name';
  }

  @override
  String doneDeleteBranch(String name) {
    return 'Deleted $name';
  }

  @override
  String doneAddRemote(String name) {
    return 'Added remote $name';
  }

  @override
  String doneRenameRemote(String name) {
    return 'Renamed the remote to $name';
  }

  @override
  String doneSetRemoteUrl(String name) {
    return 'Changed the URL of $name';
  }

  @override
  String doneRemoveRemote(String name) {
    return 'Removed remote $name';
  }

  @override
  String donePublishToGitHub(String name) {
    return 'Created $name on GitHub';
  }

  @override
  String get doneAbort => 'Aborted';

  @override
  String get doneContinue => 'Continued';

  @override
  String get errorGeneric => 'The command failed. See the output below.';

  @override
  String get errorPushRejected =>
      'Push was rejected because the remote has commits you don\'t have. Pull first.';

  @override
  String get errorAuthFailed =>
      'Authentication failed. Check that you\'re logged in with gh auth login, or that your SSH key is registered.';

  @override
  String get errorConflict =>
      'There are conflicts. Open the conflicted files from Changes, fix them, then mark them resolved.';

  @override
  String get errorLocalChanges =>
      'Stopped because uncommitted changes would be overwritten. Commit them first.';

  @override
  String get errorNotFastForward =>
      'History has split, so it can\'t fast-forward. Change the pull method to merge or rebase.';

  @override
  String get errorProtectedBranch =>
      'This branch is protected, so you can\'t push to it directly. Push a new branch and open a pull request.';

  @override
  String get errorBranchNotMerged => 'This branch has unmerged commits.';

  @override
  String get errorNoUpstream => 'No upstream branch. Publish it first.';

  @override
  String get errorAlreadyExists => 'That name already exists.';

  @override
  String get errorRepositoryNotFound =>
      'Remote repository not found. Check the URL and your access.';

  @override
  String get errorNetwork => 'Can\'t reach the server. Check your network.';

  @override
  String get errorNotInstalled =>
      'Program not found. See Check git and gh in the menu.';

  @override
  String get timeJustNow => 'just now';

  @override
  String timeMinutesAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n minutes ago',
      one: '1 minute ago',
    );
    return '$_temp0';
  }

  @override
  String timeHoursAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n hours ago',
      one: '1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String timeDaysAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n days ago',
      one: 'yesterday',
    );
    return '$_temp0';
  }

  @override
  String get helpTooltip => 'What\'s this?';

  @override
  String get helpSectionWord => 'The word';

  @override
  String get helpSectionInGit => 'In git';

  @override
  String get helpSectionWhy => 'Why and when';

  @override
  String get helpSectionLinks => 'Learn more';

  @override
  String get helpCaptionBefore => 'Before';

  @override
  String get helpCaptionAfter => 'After';

  @override
  String get helpCaptionAfterFetch => 'After fetch — your main hasn\'t moved';

  @override
  String get helpCaptionAfterPull => 'After pull — your main catches up';

  @override
  String get helpCaptionAheadOne =>
      'feature is one commit ahead of origin/feature (↑1)';

  @override
  String get helpLinkBranchingBasics => 'Pro Git — Basic Branching and Merging';

  @override
  String get helpLinkRemoteBranches => 'Pro Git — Remote Branches';

  @override
  String get helpLinkRebasing => 'Pro Git — Rebasing';

  @override
  String get helpFetchVsPullTitle => 'Fetch vs. pull';

  @override
  String get helpFetchVsPullWord =>
      'To fetch is to go and get something; to pull is to draw it toward you.';

  @override
  String get helpFetchVsPullInGit =>
      'Fetch downloads new commits from the remote (GitHub) and only moves the remote labels such as origin/main. Your branch and files stay as they are. Pull does a fetch and then joins those commits into your branch.';

  @override
  String get helpFetchVsPullWhy =>
      'Fetch when you want to see what changed first; it\'s always safe. Pull when you want to catch up right away. Pull can stop if you have uncommitted changes, so commit first.';

  @override
  String get helpUpstreamTitle => 'Upstream and origin';

  @override
  String get helpUpstreamWord =>
      'Upstream is the part of a river the water comes from. Origin is where something comes from.';

  @override
  String get helpUpstreamInGit =>
      'origin is the default name for the remote you cloned from, usually GitHub. The remote branch your branch is paired with (such as origin/feature) is its upstream. The ↑↓ numbers compare your branch with it.';

  @override
  String get helpUpstreamWhy =>
      'With an upstream, plain Push and Pull know where to go. A new branch has none, so the first push is a Publish (git push -u), which sets it.';

  @override
  String get helpFastForwardTitle => 'Fast-forward';

  @override
  String get helpFastForwardWord => 'Winding a tape or video quickly forward.';

  @override
  String get helpFastForwardInGit =>
      'When your branch is simply behind and hasn\'t split off, git makes no new commit; it just moves the branch label forward to the latest commit. It only winds forward along commits that already exist.';

  @override
  String get helpFastForwardWhy =>
      'History stays in one clean line and there\'s nothing to conflict. If both sides have different new commits (history has split) it can\'t wind forward, so fast-forward only stops and you need a merge or rebase. A push rejected as non-fast-forward fails for the same reason.';

  @override
  String get helpMergeCommitTitle => 'Merge commit';

  @override
  String get helpMergeCommitWord =>
      'To merge is to join; two roads becoming one.';

  @override
  String get helpMergeCommitInGit =>
      'Keeps both lines of history as they are and adds one new commit whose parents are both of them. The history shows exactly what was joined and when.';

  @override
  String get helpMergeCommitWhy =>
      'It never rewrites commits you\'ve already shared, so it\'s the safest. Good for branches you share with others. The trade-off is extra merge commits in the history.';

  @override
  String get helpRebaseTitle => 'Rebase';

  @override
  String get helpRebaseWord =>
      'Base is what something stands on; to rebase is to set it on a new base.';

  @override
  String get helpRebaseInGit =>
      'Takes your commits off and replays them one by one on top of the commits you just got. The changes are the same, but they become new commits (C\', D\') and the history is a single line.';

  @override
  String get helpRebaseWhy =>
      'Keeps history clean with no merge commits. Use it only on commits you haven\'t pushed yet: rebasing pushed commits makes your history differ from everyone else\'s and needs a force push.';

  @override
  String get tabTags => 'Tags';

  @override
  String get tabRelease => 'Release';

  @override
  String get tabPr => 'PRs';

  @override
  String branchesMergeInto(String head) {
    return 'Merge into $head';
  }

  @override
  String mergeTitle(String source, String into) {
    return 'Merge $source into $into';
  }

  @override
  String mergeNothing(String source, String into) {
    return '$source has nothing that $into doesn\'t already have';
  }

  @override
  String mergeIncoming(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count incoming commits',
      one: '1 incoming commit',
    );
    return '$_temp0';
  }

  @override
  String get mergeFastForward => 'Fast-forward';

  @override
  String get mergeFastForwardWhen =>
      'Just moves the label forward, no new commit. History stays in one line.';

  @override
  String get mergeFastForwardDisabled =>
      'Not possible: the current branch has its own new commits (history has split).';

  @override
  String get mergeMergeCommit => 'Merge commit';

  @override
  String get mergeMergeCommitWhen =>
      'Keeps both histories and joins them with a merge commit. The safest choice.';

  @override
  String get mergeSquash => 'Squash';

  @override
  String get mergeSquashWhen =>
      'Squashes the branch\'s commits into one. One feature, one commit.';

  @override
  String mergeSquashNote(String source) {
    return 'If you keep using $source after a squash, the same changes can conflict again. Delete the branch after merging.';
  }

  @override
  String get mergeMessageLabel => 'Commit message';

  @override
  String get mergeConfirm => 'Merge';

  @override
  String doneMerge(String source, String into) {
    return 'Merged $source into $into';
  }

  @override
  String get tagsTitle => 'Tags';

  @override
  String get tagsNew => 'New tag';

  @override
  String get tagsCreate => 'Create';

  @override
  String get tagsCreateAndPush => 'Create and push';

  @override
  String tagsPushAll(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tags',
      one: '1 tag',
    );
    return 'Push $_temp0 not on the remote';
  }

  @override
  String get tagsPushed => 'On the remote';

  @override
  String get tagsLocalOnly => 'Only on this computer';

  @override
  String get tagsLightweight => 'Lightweight';

  @override
  String get tagsAnnotated => 'Annotated';

  @override
  String get tagsPush => 'Push';

  @override
  String get tagsDelete => 'Delete';

  @override
  String get tagsDeleteRemote => 'Delete from remote';

  @override
  String get tagsDeleteRemoteTitle => 'Delete the remote tag?';

  @override
  String tagsDeleteRemoteMessage(String tag, String target) {
    return 'Deletes $tag from $target. Others may already have it, so use the next number instead of reusing the name.';
  }

  @override
  String get tagsEmptyTitle => 'No tags yet';

  @override
  String get tagsEmptyMessage =>
      'A tag is a name for a specific commit, usually a release version like v1.0.0.';

  @override
  String tagsPushAfter(String remote) {
    return 'Push to $remote after creating';
  }

  @override
  String get tagNameLabel => 'Tag name';

  @override
  String get tagNameExists => 'A tag with this name already exists';

  @override
  String get tagNameInvalid => 'No spaces, .., or ~ ^ : ? * [ \\';

  @override
  String get tagNameNotSemVer =>
      'Not a version (v1.2.3). Allowed, but releases should use versions.';

  @override
  String get tagNameMissingV => 'Release tags usually start with v (v1.2.3).';

  @override
  String get tagMessageLabel => 'Message';

  @override
  String get tagTargetLabel => 'Tag which commit';

  @override
  String tagTargetHead(String name) {
    return 'Current position ($name)';
  }

  @override
  String doneCreateTag(String name) {
    return 'Created tag $name';
  }

  @override
  String donePushTags(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tags',
      one: '1 tag',
    );
    return 'Pushed $_temp0';
  }

  @override
  String doneDeleteTag(String name) {
    return 'Deleted tag $name';
  }

  @override
  String doneDeleteRemoteTag(String name) {
    return 'Deleted tag $name from the remote';
  }

  @override
  String get prTitle => 'Pull request';

  @override
  String get prCreate => 'Create pull request';

  @override
  String get prPublishAndCreate => 'Publish and create';

  @override
  String get prTitleLabel => 'Title';

  @override
  String get prBodyLabel => 'Description';

  @override
  String get prBodyChanges => 'Changes';

  @override
  String get prDraft => 'Create as draft';

  @override
  String get prNotGitHubTitle => 'Not a GitHub repository';

  @override
  String get prNotGitHubMessage =>
      'Pull requests need a GitHub repository — gh only works with GitHub.';

  @override
  String get prGhRequiredTitle => 'Needs gh';

  @override
  String get prDetached => 'Not on a branch';

  @override
  String get prOnDefaultTitle => 'You\'re on the default branch';

  @override
  String get prOnDefaultMessage =>
      'Pull requests come from a work branch. Create one in Branches.';

  @override
  String prNoneTitle(String head) {
    return '$head has no pull request yet';
  }

  @override
  String prNoneMessage(String base) {
    return 'Open a pull request into $base to review, check and merge it on GitHub.';
  }

  @override
  String get prOpenOnGitHub => 'Open on GitHub';

  @override
  String get prStateOpen => 'Open';

  @override
  String get prStateDraft => 'Draft';

  @override
  String get prStateMerged => 'Merged';

  @override
  String get prStateClosed => 'Closed';

  @override
  String get prNoChecks => 'No checks';

  @override
  String prChecksPassed(int n) {
    return '$n passed';
  }

  @override
  String prChecksFailed(int n) {
    return '$n failed';
  }

  @override
  String prChecksPending(int n) {
    return '$n running';
  }

  @override
  String get prApproved => 'Approved';

  @override
  String get prReviewRequired => 'Review required';

  @override
  String get prBlockedDraft =>
      'Draft pull requests can\'t be merged. Mark it ready for review on GitHub.';

  @override
  String get prBlockedConflict =>
      'It conflicts with the base branch. Merge the base branch in and resolve the conflicts.';

  @override
  String prBlockedChecks(String names) {
    return 'Some checks failed: $names';
  }

  @override
  String prBlockedPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count checks are',
      one: '1 check is',
    );
    return '$_temp0 still running.';
  }

  @override
  String get prBlockedReview =>
      'A review may be required. If merging is refused, check on GitHub.';

  @override
  String get prMethodMerge => 'Merge commit';

  @override
  String get prMethodSquash => 'Squash and merge';

  @override
  String get prMethodRebase => 'Rebase and merge';

  @override
  String get prDeleteBranch => 'Delete the branch after merging';

  @override
  String get prMerge => 'Merge';

  @override
  String get donePrCreated => 'Pull request created';

  @override
  String donePrMerged(int number) {
    return 'Merged pull request #$number';
  }

  @override
  String get releaseTitle => 'Release';

  @override
  String releaseLatest(String tag) {
    return 'Latest release $tag';
  }

  @override
  String get releaseNoTags => 'No releases yet';

  @override
  String get releaseIntro =>
      'Walks you through version bump → PR → merge → tag → CI.';

  @override
  String get releaseNeedsGitHub =>
      'The release wizard needs a GitHub repository. You can still create tags in Tags.';

  @override
  String get releaseStart => 'New release';

  @override
  String get releaseNew => 'New release';

  @override
  String releaseNewVersion(String tag) {
    return 'New release $tag';
  }

  @override
  String get releaseCancel => 'Stop';

  @override
  String get releaseCancelTitle => 'Stop this release?';

  @override
  String releaseCancelMessage(String branch) {
    return 'The $branch branch and pull request made so far stay. Delete them yourself if you don\'t need them.';
  }

  @override
  String get releaseCancelAfterTag =>
      'The tag is already pushed. This only closes the wizard; check CI and the release on GitHub.';

  @override
  String releaseDone(String tag) {
    return '$tag is released';
  }

  @override
  String get releasePrerelease => 'Pre-release';

  @override
  String get releasePushAndPr => 'Push and create PR';

  @override
  String get stepCheck => 'Check';

  @override
  String get stepVersion => 'Version';

  @override
  String get stepPr => 'Pull request';

  @override
  String get stepMerge => 'Merge';

  @override
  String get stepTag => 'Tag';

  @override
  String get stepNotes => 'Release notes';

  @override
  String get stepNotesCi => 'Notes (after CI release)';

  @override
  String get stepNotesCiSummary => 'CI creates the release';

  @override
  String get stepCi => 'CI';

  @override
  String get stepNext => 'Next';

  @override
  String get stepCheckDone => 'All passed';

  @override
  String stepMergeDone(int number) {
    return 'PR #$number merged';
  }

  @override
  String get checkCleanTree => 'No uncommitted changes';

  @override
  String get checkShowChanges => 'Show changes';

  @override
  String checkOnDefault(String branch) {
    return 'On the default branch ($branch)';
  }

  @override
  String get checkSynced => 'In sync with the remote';

  @override
  String get checkGitHub => 'GitHub remote and gh login';

  @override
  String checkChangesSince(int count, String tag) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commits',
      one: '1 commit',
    );
    return '$_temp0 since $tag';
  }

  @override
  String get checkFirstRelease => 'This is the first release';

  @override
  String get checkNoWorkflow =>
      'No workflow runs on tags, so the app creates the GitHub release.';

  @override
  String checkWorkflowCi(String file) {
    return '$file creates the release when a tag is pushed. The app tags and then watches CI.';
  }

  @override
  String checkWorkflowOther(String file) {
    return '$file runs when a tag is pushed.';
  }

  @override
  String get manualBuildTitle => 'Build check before tagging (recommended)';

  @override
  String get manualBuildWhy =>
      'Files that affect the build changed since the last release. Check that every platform builds before tagging. A manual run never publishes.';

  @override
  String get manualBuildStart => 'Run build check';

  @override
  String manualBuildShort(String state) {
    return 'build check $state';
  }

  @override
  String get doneManualBuildStarted => 'Build check started';

  @override
  String versionCurrent(String version, String source) {
    return 'Current $version ($source)';
  }

  @override
  String get versionFromTag => 'last tag';

  @override
  String get versionRecommended => 'Suggested';

  @override
  String versionReason(int feats, int fixes, int breaking) {
    return '$feats features · $fixes fixes · $breaking breaking';
  }

  @override
  String get versionCustom => 'Custom version';

  @override
  String get versionFiles => 'Files to change';

  @override
  String get versionNoFiles => 'No version file, so only the tag is created.';

  @override
  String get versionCommit => 'Create release branch and commit';

  @override
  String get bumpFinal => 'Final';

  @override
  String get bumpPrerelease => 'Pre-release';

  @override
  String doneReleaseCommit(String tag) {
    return 'Committed the $tag version bump';
  }

  @override
  String mergeWaiting(int number) {
    return 'Waiting for PR #$number to merge — merging on GitHub works too';
  }

  @override
  String tagCheckPrMerged(int number) {
    return 'PR #$number is merged';
  }

  @override
  String tagCheckSynced(String branch) {
    return 'On $branch and in sync with the remote';
  }

  @override
  String tagCheckVersion(String tag) {
    return 'Version files match $tag';
  }

  @override
  String tagCheckVersionWrong(String version) {
    return 'The version is $version. The version bump PR may not be merged yet.';
  }

  @override
  String tagCheckFree(String tag) {
    return '$tag doesn\'t exist yet';
  }

  @override
  String tagConfirmTitle(String tag) {
    return 'Push tag $tag?';
  }

  @override
  String tagConfirmMessage(String tag, String branch) {
    return 'Tags the merge commit on $branch as $tag. Pushing publishes the release, and tags aren\'t moved or deleted afterwards.';
  }

  @override
  String get tagConfirmPush => 'Tag and push';

  @override
  String doneTagPushed(String tag) {
    return 'Pushed $tag';
  }

  @override
  String get notesLabel => 'Release notes (Markdown)';

  @override
  String get notesFeatures => 'New features';

  @override
  String get notesFixes => 'Bug fixes';

  @override
  String get notesOther => 'Other changes';

  @override
  String get notesCreateRelease => 'Create GitHub release';

  @override
  String get notesEdit => 'Edit notes';

  @override
  String get doneReleaseCreated => 'GitHub release created';

  @override
  String get doneNotesSaved => 'Release notes saved';

  @override
  String ciWaitingForRun(String tag) {
    return 'Looking for the workflow run for $tag';
  }

  @override
  String get ciOpenInBrowser => 'Open in browser';

  @override
  String get ciRerunFailed => 'Re-run failed jobs';

  @override
  String get doneRerun => 'Re-running failed jobs';

  @override
  String get runQueued => 'queued';

  @override
  String get runRunning => 'running';

  @override
  String get runSuccess => 'succeeded';

  @override
  String get runFailure => 'failed';

  @override
  String get runCancelled => 'cancelled';

  @override
  String get runSkipped => 'skipped';

  @override
  String get helpCaptionAfterSquash =>
      'After a squash merge — one new commit S on main';

  @override
  String get helpCaptionTag =>
      'v1.0.0 and v1.1.0 stay put; main keeps moving forward';

  @override
  String get helpLinkGitHubMergeMethods => 'GitHub — About merge methods';

  @override
  String get helpLinkTagging => 'Pro Git — Tagging';

  @override
  String get helpSquashTitle => 'Squash';

  @override
  String get helpSquashWord => 'To press something flat.';

  @override
  String get helpSquashInGit =>
      'Presses the branch\'s commits into a single commit on the target branch. The changes are the same; only the number of commits becomes one.';

  @override
  String get helpSquashWhy =>
      'Keeps work-in-progress commits like \'fix typo\' out of the main history: one feature, one commit. Common when merging pull requests. The original commits don\'t reach the default branch, so delete the merged branch instead of reusing it.';

  @override
  String get helpTagTitle => 'Tags (annotated and lightweight)';

  @override
  String get helpTagWord => 'A tag is a label you attach to something.';

  @override
  String get helpTagInGit =>
      'A name attached to one commit. A branch label moves forward with new commits; a tag stays on its commit. An annotated tag also stores who made it, when, and a message; a lightweight tag stores only the name.';

  @override
  String get helpTagWhy =>
      'Use annotated tags for release versions (v1.2.0): the release is recorded, and GitHub releases and CI run from the tag. Don\'t move or delete a pushed tag; if it\'s wrong, tag the next number.';

  @override
  String get headerMergedAndGone => 'Merged · deleted on remote';

  @override
  String get headerMergedAndGoneTooltip =>
      'This branch is already merged into the default branch and was deleted on the remote. Publishing it again would bring the deleted branch back.';

  @override
  String bannerMergedAndGone(String branch) {
    return 'This branch was merged and deleted on the remote. Go back to $branch';
  }

  @override
  String bannerSwitchTo(String branch) {
    return 'Switch to $branch';
  }

  @override
  String bannerCreatePr(String branch) {
    return '$branch is pushed but has no pull request yet';
  }

  @override
  String get prBaseLabel => 'Base branch';

  @override
  String prBaseNotDefault(String base) {
    return 'Merges into a branch other than the default ($base) — for a PR stacked on another feature branch.';
  }

  @override
  String get tabCi => 'CI';

  @override
  String get ciTitle => 'Workflow runs';

  @override
  String get ciNotGitHubMessage =>
      'Actions need a GitHub repository — gh only works with GitHub.';

  @override
  String ciEmptyTitle(String branch) {
    return 'No runs on $branch yet';
  }

  @override
  String get ciEmptyMessage =>
      'Runs triggered by pushes, pull requests or tags show up here.';

  @override
  String get ciRerun => 'Re-run';

  @override
  String get ciCancel => 'Cancel run';

  @override
  String get ciDispatch => 'Run workflow';

  @override
  String get ciDispatchNeedsPush =>
      'Manual runs need a branch that\'s on the remote. Publish it first.';

  @override
  String ciDispatchTitle(String file) {
    return 'Run $file';
  }

  @override
  String ciDispatchMessage(String branch) {
    return 'Runs the workflow on $branch. For workflows that need inputs, run them in the browser.';
  }

  @override
  String get ciDispatchConfirm => 'Run';

  @override
  String doneDispatched(String file) {
    return 'Started $file';
  }

  @override
  String get doneRunCancelled => 'Run cancelled';

  @override
  String notifyRunTitle(String name, String state) {
    return '$name $state';
  }

  @override
  String notifyReleaseRun(String tag, String state) {
    return '$tag release CI $state';
  }

  @override
  String notifyManualBuild(String state) {
    return 'Build check $state';
  }

  @override
  String get prFilterMine => 'Mine';

  @override
  String get prFilterReview => 'To review';

  @override
  String get prFilterOpen => 'All open';

  @override
  String get prListEmpty => 'No open pull requests';

  @override
  String get prCurrentBranch => 'Current branch';

  @override
  String get prCheckout => 'Check out this PR';

  @override
  String get prCheckoutWhy =>
      'Fetches the PR\'s branch and switches to it — to try it out or fix something.';

  @override
  String donePrCheckout(int number, String branch) {
    return 'Switched to $branch from PR #$number';
  }

  @override
  String get releasesTitle => 'Releases';

  @override
  String get releasesEmpty => 'No GitHub releases';

  @override
  String get releasesLoadFailed => 'Couldn\'t load releases';

  @override
  String get releaseLatestPill => 'Latest';

  @override
  String get releaseDraft => 'Draft';

  @override
  String get releaseMakeFinal => 'Mark as full release';

  @override
  String get releaseMakePrerelease => 'Mark as pre-release';

  @override
  String get releasePublishDraft => 'Publish draft';

  @override
  String get releaseDelete => 'Delete release';

  @override
  String releaseDeleteTitle(String tag) {
    return 'Delete the $tag release?';
  }

  @override
  String get releaseDeleteMessage =>
      'The GitHub release and its files are removed. People may have downloaded them already.';

  @override
  String releaseDeleteTagToo(String tag) {
    return 'Also delete the $tag tag on GitHub (the local tag stays)';
  }

  @override
  String doneReleaseDeleted(String tag) {
    return 'Deleted the $tag release';
  }

  @override
  String doneReleaseMadeFinal(String tag) {
    return '$tag is now a full release';
  }

  @override
  String doneReleaseMadePrerelease(String tag) {
    return '$tag is now a pre-release';
  }

  @override
  String doneReleasePublished(String tag) {
    return 'Published the $tag draft';
  }

  @override
  String get notesEditTab => 'Edit';

  @override
  String get notesPreviewTab => 'Preview';

  @override
  String get notesEmpty => 'Nothing to preview';

  @override
  String tagVersionMismatch(String file, String version, String tag) {
    return '$file says $version, but the tag is $tag.';
  }

  @override
  String get tagVersionMismatchWhy =>
      'A release tag goes on the commit that bumps the version — the release wizard does the bump PR through the tag in order.';

  @override
  String get tagVersionMismatchCi =>
      'In this repository pushing a tag makes CI build the release, and CI stops when the versions differ.';

  @override
  String get tagVersionMismatchBlocked =>
      'So pushing is blocked. Turn off push to create it only locally.';

  @override
  String get tagOpenReleaseWizard => 'Open the release wizard';

  @override
  String get tabHistory => 'History';

  @override
  String get menuAutoFetch => 'Auto fetch (every 5 min and on return)';

  @override
  String get changesAmendToggle => 'Amend the last commit';

  @override
  String get changesAmend => 'Amend';

  @override
  String get changesAmendPushedWarning =>
      'This commit is already on the remote. Amending splits the history and needs a force push (force-with-lease).';

  @override
  String get doneAmend => 'Amended the last commit';

  @override
  String get changesDiscard => 'Discard changes';

  @override
  String changesDiscardMessage(String path) {
    return 'Throws away the uncommitted changes in $path and goes back to the last staged (or committed) version. This can\'t be undone.';
  }

  @override
  String get changesDeleteUntracked => 'Delete file';

  @override
  String changesDeleteUntrackedMessage(String path) {
    return 'Deletes $path, which git doesn\'t track. It doesn\'t go to the trash.';
  }

  @override
  String get conflictUseMine => 'Use mine';

  @override
  String get conflictUseIncoming => 'Use incoming';

  @override
  String doneFileAction(String name) {
    return '$name: done';
  }

  @override
  String get stashTitle => 'Stashes';

  @override
  String get stashSave => 'Stash changes';

  @override
  String stashWhy(int count) {
    return 'Puts your $count changes aside without committing, including untracked files. Bring them back later with Apply.';
  }

  @override
  String get stashMessageLabel => 'Note (optional)';

  @override
  String get stashPop => 'Apply and remove (pop)';

  @override
  String get stashApply => 'Apply and keep (apply)';

  @override
  String get stashDrop => 'Delete';

  @override
  String get stashDropTitle => 'Delete this stash?';

  @override
  String stashDropMessage(String text) {
    return 'The changes saved in \'$text\' will be lost.';
  }

  @override
  String get stashAndRetry => 'Stash and retry';

  @override
  String get stashAutoMessage => 'Branch Dock: auto stash';

  @override
  String get doneStashSaved => 'Stashed';

  @override
  String get doneStashApplied => 'Stash applied';

  @override
  String get doneStashDropped => 'Stash deleted';

  @override
  String get doneStashAndRetry =>
      'Stashed your changes and ran it again. Restore them from Stashes in Changes.';

  @override
  String get pushOptionsTooltip => 'Push options';

  @override
  String get pushOptionsTitle => 'Push options';

  @override
  String get pushFollowTags => 'Push tags too (--follow-tags)';

  @override
  String get pushFollowTagsWhy =>
      'Also pushes annotated tags on the commits you push. Applies to this repository only.';

  @override
  String get pushForceTitle => 'Force push (force-with-lease)';

  @override
  String get pushForceWhy =>
      'Only after amending or rebasing commits you already pushed. git refuses if the remote has commits you haven\'t seen, so nobody else\'s work is overwritten.';

  @override
  String pushForceBlockedDefault(String branch) {
    return 'Force push is blocked on the default branch ($branch) — it could overwrite other people\'s history.';
  }

  @override
  String get pushForce => 'Force push';

  @override
  String pushForceConfirmTitle(String branch) {
    return 'Force push $branch?';
  }

  @override
  String pushForceConfirmMessage(String branch, String upstream) {
    return 'Replaces $upstream with your $branch. If someone pushed since your last fetch, git refuses.';
  }

  @override
  String get operationSkip => 'Skip';

  @override
  String get operationSkipTooltip =>
      'Drops the conflicting commit and continues the rebase';

  @override
  String get doneSkip => 'Skipped the commit';

  @override
  String get branchesSetUpstream => 'Set upstream';

  @override
  String branchesSetUpstreamWhy(String branch) {
    return 'Chooses the remote branch $branch pushes to and pulls from.';
  }

  @override
  String get branchesUpstreamLabel => 'Remote branch';

  @override
  String doneSetUpstream(String branch, String upstream) {
    return '$branch now tracks $upstream';
  }

  @override
  String get branchesCleanup => 'Clean up merged branches';

  @override
  String cleanupWhy(String base) {
    return 'Local branches already merged into $base, or deleted on the remote. Remote branches aren\'t touched.';
  }

  @override
  String get cleanupMerged => 'Merged';

  @override
  String get cleanupGoneNotMerged =>
      'Gone on remote · not merged — its commits get hard to find';

  @override
  String cleanupConfirm(int count) {
    return 'Delete $count';
  }

  @override
  String cleanupNothing(String base) {
    return 'Nothing to clean up (no branches merged into $base)';
  }

  @override
  String doneCleanup(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count branches',
      one: '1 branch',
    );
    return 'Cleaned up $_temp0';
  }

  @override
  String get tagsCommitsSince => 'Commits since previous tag';

  @override
  String tagsCommitsBetween(String from, String to) {
    return '$from → $to';
  }

  @override
  String tagsCommitsUpTo(String tag) {
    return 'Up to $tag';
  }

  @override
  String tagsCommitsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commits',
      one: '1 commit',
    );
    return '$_temp0';
  }

  @override
  String get tagsCheckout => 'Check out this tag';

  @override
  String tagsCheckoutTitle(String tag) {
    return 'Check out $tag?';
  }

  @override
  String get tagsCheckoutMessage =>
      'You\'ll see the files exactly as they were at the tag. You won\'t be on any branch (\'detached HEAD\'), so create a branch before committing here.';

  @override
  String doneCheckoutTag(String tag) {
    return 'Checked out $tag';
  }

  @override
  String get bannerDetached =>
      'You\'re not on a branch. Create one before committing here';

  @override
  String get historyTitle => 'History';

  @override
  String historyUnpushed(int count) {
    return '↑ $count not pushed';
  }

  @override
  String get historyNotPushed => 'not pushed';

  @override
  String get historyCopyHash => 'Copy hash';

  @override
  String get historyBranchHere => 'Create branch here';

  @override
  String get historyTagHere => 'Tag this commit';

  @override
  String get helpLinkStashing => 'Pro Git — Stashing and Cleaning';

  @override
  String get helpCaptionStash =>
      'Uncommitted changes W put aside at the top of the stash list — main is unchanged';

  @override
  String get helpStashTitle => 'Stash';

  @override
  String get helpStashWord =>
      'To stash is to put something away for later, like into a drawer.';

  @override
  String get helpStashInGit =>
      'Saves your uncommitted changes outside the branch history and resets the working tree to clean. Stashes pile up in a list (newest on top) and can be applied later on any branch.';

  @override
  String get helpStashWhy =>
      'Use it when it\'s too early to commit but you need to switch branches or pull. \'pop\' applies and removes it; \'apply\' keeps it in the list. Add a note — old stashes are easy to forget.';

  @override
  String get helpCaptionDetached =>
      'HEAD points straight at the v1.0.0 commit, not at a branch';

  @override
  String get helpDetachedTitle => 'Detached HEAD';

  @override
  String get helpDetachedWord =>
      'Detached means separated. HEAD means \'where you are now\'.';

  @override
  String get helpDetachedInGit =>
      'Normally HEAD points at a branch label, and committing moves that label forward. Checking out a tag or commit makes HEAD point straight at the commit, detached from any branch.';

  @override
  String get helpDetachedWhy =>
      'Safe for trying out or comparing an old version. Commits made here belong to no branch and are hard to find once you move away — create a branch first if you want to commit.';

  @override
  String get helpForceTitle => 'Force push (force-with-lease)';

  @override
  String get helpForceWord =>
      'Force means by force; a lease is an agreement — here, \'only if it\'s still how I last saw it\'.';

  @override
  String get helpForceInGit =>
      'After amending or rebasing commits you already pushed, your history has split from the remote and a normal push is rejected. A force push replaces the remote branch with yours. --force-with-lease only does so if the remote is exactly as you last fetched it, and refuses if someone pushed in between.';

  @override
  String get helpForceWhy =>
      'Only on a work branch you use alone, after tidying its history. Never on shared branches, especially main. This app doesn\'t offer plain --force, and blocks force push on the default branch.';

  @override
  String get menuBrowse => 'Open repository in browser';

  @override
  String get menuSnapRight => 'Snap to right edge';

  @override
  String get menuSnapLeft => 'Snap to left edge';

  @override
  String get startInitRepository => 'Make this folder a git repository';

  @override
  String get cloneTitle => 'Clone from GitHub';

  @override
  String get cloneSearch => 'Find one of your repositories';

  @override
  String get cloneEmpty => 'No repositories';

  @override
  String get cloneNoFolder => 'Choose where to clone';

  @override
  String get cloneChooseFolder => 'Choose folder';

  @override
  String cloneExists(String path) {
    return 'That folder already exists: $path';
  }

  @override
  String get cloneConfirm => 'Clone and open';

  @override
  String get cloneRunning => 'Cloning…';

  @override
  String get loginTitle => 'Log in to GitHub';

  @override
  String get loginSsh => 'SSH';

  @override
  String get loginHttps => 'HTTPS';

  @override
  String get loginSshRecommended => 'SSH recommended';

  @override
  String get loginSshWhy =>
      'With an SSH remote or an SSH session, logging in over HTTPS can leave git push authenticating separately.';

  @override
  String get loginStepKey => 'Check for an SSH key';

  @override
  String get loginStepKeyFound => 'This key will be added to GitHub';

  @override
  String get loginStepKeyMissing =>
      'No key found. Create one in a terminal with the command below (a passphrase is recommended). The app never handles keys or passphrases.';

  @override
  String get loginStepLogin => 'Log in';

  @override
  String get loginStepLoginWhy =>
      'Log in to GitHub in the browser and enter a one-time code.';

  @override
  String get loginLoggedIn => 'You\'re logged in';

  @override
  String get loginStart => 'Log in with browser';

  @override
  String get loginDeviceHowTo =>
      'If no browser opens, or you\'re on a remote server, open this address on any device and enter the code.';

  @override
  String get loginStepUpload => 'Add the public key';

  @override
  String get loginStepUploadWhy =>
      'Registers the chosen public key with your GitHub account. Skipped if it\'s already there.';

  @override
  String get loginUploadKey => 'Add key';

  @override
  String get loginNeedsKeyScope =>
      'Missing permission to add keys. Add it with the command below in a terminal, then try again.';

  @override
  String get loginStepTest => 'Test the connection';

  @override
  String get loginStepTestWhy =>
      'Connects to GitHub over SSH. The first time, github.com\'s host key is added to known_hosts.';

  @override
  String get loginSshFailed =>
      'Couldn\'t connect. Check that the key is added to GitHub and loaded in ssh-agent.';

  @override
  String get loginTest => 'Test';

  @override
  String get loginChecking => 'Checking…';

  @override
  String get loginStepProtocol => 'Use SSH for git';

  @override
  String get loginStepProtocolWhy =>
      'gh will use SSH addresses from now on. Switch existing HTTPS remotes in Remotes → Change URL.';

  @override
  String get loginUseSshProtocol => 'Use SSH';

  @override
  String get loginAgentTip =>
      'To avoid typing the passphrase every time, use ssh-add --apple-use-keychain on macOS, or ssh-agent elsewhere.';

  @override
  String get doneProtocolSsh => 'gh now uses SSH for git';

  @override
  String forkTitle(String parent) {
    return 'Fork of $parent';
  }

  @override
  String get forkAddWhy =>
      'Add the original repository as the upstream remote to bring in its new commits.';

  @override
  String get forkSyncWhy =>
      'Fetches new commits from the original (upstream) and merges them into your current branch.';

  @override
  String get forkAddUpstream => 'Add upstream';

  @override
  String get forkSync => 'Sync from upstream';

  @override
  String get remotesGhDefault => 'Repository gh uses (PRs, releases, CI)';

  @override
  String get remotesGhDefaultNone => 'Not set';

  @override
  String doneGhDefault(String repo) {
    return 'gh now uses $repo';
  }

  @override
  String get releaseNeedsRemote =>
      'No remote to release to. Publish it from Remotes first.';

  @override
  String get releaseDirectOnlyNotGitHub =>
      'Not a GitHub repository, so this uses direct commit (check → version → tag). Do PRs, release notes and CI on your host\'s website.';

  @override
  String get releaseDirectOnly =>
      'Without gh, only direct commit is available.';

  @override
  String get releaseDirectMode => 'Direct commit';

  @override
  String releaseDirectModeWhy(String branch) {
    return 'Commits the version bump straight to $branch and pushes it with the tag, no PR. Only for repositories you work on alone — protected branches reject the push.';
  }

  @override
  String tagCheckSyncedDirect(String branch) {
    return 'On $branch with no remote commits you\'re missing';
  }

  @override
  String get versionUsesScript =>
      'Uses the repository\'s scripts/bump-version.sh (lock files included, same result as the conventions).';

  @override
  String versionLockFiles(String files) {
    return 'Lock files updated too: $files';
  }

  @override
  String get versionFileChoose => 'Change version file';

  @override
  String versionFileCustom(String path) {
    return 'Version file: $path (custom)';
  }

  @override
  String get versionFileTitle => 'Version file';

  @override
  String get versionFileWhy =>
      'For when the version file isn\'t found or is the wrong one. The first group in the pattern is the version. Applies to this repository only.';

  @override
  String get versionFilePath => 'File (path in the repository)';

  @override
  String get versionFilePattern => 'Version line pattern';

  @override
  String versionFileFound(String version) {
    return 'Found: $version';
  }

  @override
  String get versionFileNotFound =>
      'File missing, or no version matches the pattern';

  @override
  String get versionFileAuto => 'Back to auto-detect';

  @override
  String get rollbackTitle => 'Roll back release';

  @override
  String rollbackConfirmTitle(String tag) {
    return 'Roll back $tag?';
  }

  @override
  String rollbackMessage(String next) {
    return 'Deletes the GitHub release, the remote tag and the local tag. People may already have it, so don\'t reuse the number — release the next one ($next) instead.';
  }

  @override
  String doneRollback(String tag) {
    return 'Rolled back $tag';
  }

  @override
  String get diffBinary => 'Binary file — no text diff';

  @override
  String get diffEmpty => 'No differences';

  @override
  String diffTruncated(int count) {
    return 'Showing the first $count lines only. Open it in your editor for the rest.';
  }

  @override
  String headerCherryPicking(int count) {
    return 'Cherry-picking · $count conflicts';
  }

  @override
  String headerReverting(int count) {
    return 'Reverting · $count conflicts';
  }

  @override
  String get operationAbortPickMessage =>
      'Goes back to before it started. Any conflict resolutions you\'ve made are lost.';

  @override
  String get historyBranchLabel => 'Branch';

  @override
  String historyOtherBranchHint(String head) {
    return 'Another branch\'s history. Use \'Bring into\' in a commit\'s menu to copy it onto $head.';
  }

  @override
  String get historyViewChanges => 'View changes';

  @override
  String historyFilesChanged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files changed',
      one: '1 file changed',
    );
    return '$_temp0';
  }

  @override
  String get historyMergeNote => 'merge commit — changes it brought in';

  @override
  String get historyRevert => 'Revert this commit';

  @override
  String historyRevertTitle(String hash) {
    return 'Revert $hash?';
  }

  @override
  String get historyRevertMessage =>
      'Makes a new commit that undoes this one. History isn\'t rewritten, so it\'s safe even for commits you\'ve pushed.';

  @override
  String get historyRevertUnpushed =>
      'Makes a new commit that undoes this one. Since it isn\'t pushed yet, you could also amend or fix it in a new commit.';

  @override
  String get historyCherryPick => 'Bring in';

  @override
  String historyCherryPickMenu(String head) {
    return 'Bring into $head (cherry-pick)';
  }

  @override
  String historyCherryPickTitle(String hash, String head) {
    return 'Bring $hash into $head?';
  }

  @override
  String get historyCherryPickMessage =>
      'Copies the same change onto your current branch as a new commit — for taking just one commit without merging the whole branch.';

  @override
  String doneRevert(String hash) {
    return 'Reverted $hash';
  }

  @override
  String doneCherryPick(String hash) {
    return 'Brought in $hash';
  }

  @override
  String get menuPalette => 'Command palette';

  @override
  String get paletteHint => 'What do you want to do? (e.g. push, branch, tag)';

  @override
  String get paletteEmpty => 'No matching commands';

  @override
  String get paletteGroupActions => 'Action';

  @override
  String get paletteGroupTabs => 'Tab';

  @override
  String get paletteGroupBranches => 'Branch';

  @override
  String get paletteGroupRepos => 'Repository';

  @override
  String paletteGoToTab(String name) {
    return 'Go to $name';
  }

  @override
  String paletteSwitchTo(String branch) {
    return 'Switch to $branch';
  }

  @override
  String get helpCaptionAfterRevert => 'C stays; a new commit C⁻ undoes it';

  @override
  String get helpCaptionAfterCherryPick =>
      'The change from feature\'s D is copied onto main as a new commit D\'';

  @override
  String get helpRevertTitle => 'Revert';

  @override
  String get helpRevertWord => 'To revert is to go back to how something was.';

  @override
  String get helpRevertInGit =>
      'Doesn\'t delete the commit — it adds a new commit that applies the opposite change. Both the original and the revert stay in history.';

  @override
  String get helpRevertWhy =>
      'Use it when a commit you\'ve already pushed causes trouble. History isn\'t rewritten, so nobody else is affected and no force push is needed. For commits not yet pushed, amending is cleaner.';

  @override
  String get helpCherryPickTitle => 'Cherry-pick';

  @override
  String get helpCherryPickWord =>
      'To cherry-pick is to pick only the best cherries — take just what you want.';

  @override
  String get helpCherryPickInGit =>
      'Copies the change from one commit on another branch onto your current branch as a new commit. Same change, but a new commit (D\') with a different hash.';

  @override
  String get helpCherryPickWhy =>
      'Handy for pulling one urgent fix from another branch. If you merge that branch later the same change arrives twice and can conflict — merging is still the default.';

  @override
  String confirmTypeToContinue(String text) {
    return 'This can\'t be undone. Type $text to continue.';
  }

  @override
  String tagsDeleteRemoteReleaseDraft(String tag) {
    return '⚠️ $tag has a GitHub release. Deleting the tag makes GitHub turn that release into a draft (hidden) — the files stay but nobody can see them. To clean up the release too, use \'Roll back release\' in the tag menu.';
  }

  @override
  String tagsPushCiTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'these $count tags',
      one: 'this tag',
    );
    return 'Pushing $_temp0 creates releases';
  }

  @override
  String tagsPushCiMessage(String workflow, String tags) {
    return 'In this repository, pushing a tag makes $workflow build it and create a GitHub release: $tags. Old releases you deleted on purpose would come back. To remove them locally instead, use \'Delete\' in the tag menu.';
  }

  @override
  String get tagsPushAnyway => 'Push anyway';
}
