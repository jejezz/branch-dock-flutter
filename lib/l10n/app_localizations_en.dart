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
}
