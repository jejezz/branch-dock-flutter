// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get aboutTooltip => '정보';

  @override
  String aboutVersion(String version, String build) {
    return '버전 $version (빌드 $build)';
  }

  @override
  String get aboutOpenSourceLicenses => '오픈소스 라이선스';

  @override
  String get aboutRepository => 'GitHub';

  @override
  String get commonClose => '닫기';

  @override
  String aboutMenuItem(String appName) {
    return '$appName 정보';
  }

  @override
  String get themeMenuTooltip => '테마';

  @override
  String get themeSystem => '시스템 설정 따르기';

  @override
  String get themeLight => '라이트';

  @override
  String get themeDark => '다크';

  @override
  String get languageMenuTooltip => '언어';

  @override
  String get languageSystem => '시스템 설정 따르기 / System';

  @override
  String get languageSystemShort => '시스템';

  @override
  String get aboutTagline => 'Git과 GitHub CLI를 위한 데스크톱 도우미';

  @override
  String get aboutDescription =>
      '편집기 옆에 세워 두고 브랜치, 태그, 병합, Pull/Push, 원격, 릴리스를 버튼으로 다룹니다. 버튼마다 실제로 실행되는 git·gh 명령을 보여 줍니다.';

  @override
  String get homeEmptyTitle => '시작하려면 저장소를 선택하세요';

  @override
  String get homeEmptyAction => '저장소 열기';

  @override
  String get appBarRefresh => '새로 고침';

  @override
  String get appBarPin => '항상 위에 표시';

  @override
  String get appBarUnpin => '항상 위에 표시 끄기';

  @override
  String get menuOpenFolder => '다른 폴더 열기…';

  @override
  String get menuEditor => '파일을 열 편집기…';

  @override
  String get menuEnvironment => '환경 점검';

  @override
  String get menuCloseRepo => '저장소 닫기';

  @override
  String get hostOther => '기타 git 서버';

  @override
  String get commonCancel => '취소';

  @override
  String get commonCopy => '복사';

  @override
  String get commonCopied => '복사했습니다';

  @override
  String get commonMore => '더 보기';

  @override
  String get commonSave => '저장';

  @override
  String get commandPreviewLabel => '실행될 명령';

  @override
  String get startDropHint => 'git 저장소 폴더를 창에 끌어다 놓아도 됩니다.';

  @override
  String get startRecent => '최근 저장소';

  @override
  String get startRemoveRecent => '목록에서 빼기';

  @override
  String startNotARepository(String path) {
    return '이 폴더는 git 저장소가 아닙니다: $path';
  }

  @override
  String startNotFound(String path) {
    return '폴더를 찾을 수 없습니다: $path';
  }

  @override
  String get envTitle => '환경 점검';

  @override
  String get envGitRequired => 'Branch Dock은 설치된 git을 실행합니다. git을 먼저 설치하세요.';

  @override
  String get envGitOnlyNote =>
      'gh가 없거나 로그인하지 않아도 브랜치·태그·Pull·Push는 쓸 수 있습니다. GitHub에 올리기, PR, 릴리스에는 gh 로그인이 필요합니다.';

  @override
  String envVersion(String version) {
    return '버전 $version';
  }

  @override
  String get envNotInstalled => '설치되지 않았거나 찾을 수 없습니다';

  @override
  String get envLogin => 'GitHub 로그인';

  @override
  String envLoggedInAs(String login) {
    return '$login 계정으로 로그인됨';
  }

  @override
  String get envNotLoggedIn => '로그인하지 않았습니다. 터미널에서 아래 명령을 실행하세요.';

  @override
  String get envRecheck => '다시 확인';

  @override
  String get envGhMissing =>
      'GitHub CLI(gh)가 설치되지 않아 쓸 수 없습니다. 메뉴의 환경 점검을 확인하세요.';

  @override
  String get envGhLoggedOut =>
      'gh에 로그인해야 쓸 수 있습니다. 터미널에서 gh auth login을 실행하세요.';

  @override
  String get headerBranchTooltip => '브랜치 목록 보기';

  @override
  String get headerDetached => '분리된 HEAD';

  @override
  String get headerNoUpstream => '원격에 없음';

  @override
  String get headerNoUpstreamTooltip =>
      '이 브랜치는 아직 원격에 올라가지 않았습니다. 게시(Publish)하면 올라갑니다.';

  @override
  String headerAheadTooltip(int count) {
    return '원격에 아직 없는 내 커밋 $count개';
  }

  @override
  String headerBehindTooltip(int count) {
    return '내 컴퓨터에 아직 없는 원격 커밋 $count개';
  }

  @override
  String headerChanges(int count) {
    return '변경 $count';
  }

  @override
  String get headerUpToDate => '최신';

  @override
  String get headerNoCommits => '아직 커밋 없음';

  @override
  String headerMerging(int count) {
    return '병합 중 · 충돌 $count';
  }

  @override
  String headerRebasing(int count) {
    return 'rebase 중 · 충돌 $count';
  }

  @override
  String get headerFetch => 'Fetch';

  @override
  String get headerPull => 'Pull';

  @override
  String get headerPush => 'Push';

  @override
  String get headerPublish => '게시';

  @override
  String get pullModeTooltip => 'Pull 방식';

  @override
  String get pullModeTitle => 'Pull 방식';

  @override
  String get pullModeMerge => '병합 (기본)';

  @override
  String get pullModeMergeWhen => '양쪽에 새 커밋이 있으면 병합 커밋으로 합칩니다. 가장 안전합니다.';

  @override
  String get pullModeRebase => 'Rebase';

  @override
  String get pullModeRebaseWhen => '내 커밋을 받아온 커밋 뒤로 옮겨 기록을 한 줄로 유지합니다.';

  @override
  String get pullModeFastForward => 'Fast-forward만';

  @override
  String get pullModeFastForwardWhen => '내 커밋이 없을 때만 받아옵니다. 갈라졌으면 멈추고 알려 줍니다.';

  @override
  String get operationAbort => '중단';

  @override
  String get operationContinue => '계속';

  @override
  String get operationContinueBlocked => '충돌을 모두 해결해야 계속할 수 있습니다';

  @override
  String get operationAbortTitle => '진행 중인 작업을 중단할까요?';

  @override
  String get operationAbortMergeMessage =>
      '병합을 시작하기 전 상태로 되돌립니다. 충돌을 해결하던 내용은 사라집니다.';

  @override
  String get operationAbortRebaseMessage =>
      'rebase를 시작하기 전 상태로 되돌립니다. 충돌을 해결하던 내용은 사라집니다.';

  @override
  String bannerConflicts(int count) {
    return '충돌 파일 $count개를 해결해야 합니다';
  }

  @override
  String bannerPull(int count) {
    return '원격에 새 커밋 $count개가 있습니다';
  }

  @override
  String get bannerPublish => '이 브랜치는 아직 원격에 없습니다';

  @override
  String bannerPush(int count) {
    return '커밋 $count개가 아직 원격에 없습니다';
  }

  @override
  String get bannerNoRemote => '이 저장소는 아직 GitHub에 없습니다';

  @override
  String get bannerShow => '보기';

  @override
  String bannerNotGitHub(String host) {
    return '$host 저장소입니다. 브랜치·Pull·Push는 모두 쓸 수 있고, PR·릴리스·Actions는 GitHub 저장소에서만 쓸 수 있습니다.';
  }

  @override
  String get tabChanges => '변경';

  @override
  String get tabBranches => '브랜치';

  @override
  String get tabRemotes => '원격';

  @override
  String get changesMessageHint => '커밋 메시지';

  @override
  String get changesPrefixTooltip => '커밋 종류 접두어';

  @override
  String changesFirstLineLong(int length) {
    return '첫 줄이 $length자입니다. 72자 안으로 줄이면 목록에서 잘리지 않습니다.';
  }

  @override
  String changesCommitStaged(int count) {
    return '커밋 (스테이징 $count)';
  }

  @override
  String get changesCommitAll => '모두 스테이징하고 커밋';

  @override
  String get changesConflicts => '충돌';

  @override
  String get changesStaged => '스테이징됨';

  @override
  String get changesUnstaged => '변경됨';

  @override
  String get changesUntracked => '추적 안 됨';

  @override
  String get changesStageAll => '모두 스테이징';

  @override
  String get changesUnstageAll => '모두 해제';

  @override
  String get changesStage => '스테이징';

  @override
  String get changesUnstage => '스테이징 해제';

  @override
  String get changesOpenInEditor => '편집기로 열기';

  @override
  String get changesMarkResolved => '해결됨';

  @override
  String get changesCleanTitle => '커밋할 변경이 없습니다';

  @override
  String get changesCleanMessage => '편집기에서 파일을 저장하면 여기에 바로 나타납니다.';

  @override
  String get branchesTitle => '브랜치';

  @override
  String get branchesNew => '새 브랜치';

  @override
  String get branchesCreate => '만들기';

  @override
  String get branchesSearchHint => '브랜치 찾기';

  @override
  String get branchesLocal => '로컬';

  @override
  String get branchesRemote => '원격';

  @override
  String get branchesSwitch => '전환';

  @override
  String get branchesRename => '이름 바꾸기';

  @override
  String get branchesDelete => '삭제';

  @override
  String get branchesDeleteRemote => '원격에서 삭제';

  @override
  String get branchesUpstreamGone => '원격 삭제됨';

  @override
  String get branchesUnbornTitle => '아직 커밋이 없습니다';

  @override
  String get branchesUnbornMessage => '첫 커밋을 만들면 브랜치를 만들 수 있습니다.';

  @override
  String get branchesForceDeleteTitle => '병합되지 않은 브랜치입니다';

  @override
  String branchesForceDeleteMessage(String name) {
    return '$name에는 다른 브랜치에 병합되지 않은 커밋이 있습니다. 삭제하면 그 커밋을 찾기 어려워집니다.';
  }

  @override
  String get branchesDeleteRemoteTitle => '원격 브랜치를 삭제할까요?';

  @override
  String branchesDeleteRemoteMessage(String branch, String target) {
    return '$target에서 $branch 브랜치를 삭제합니다. 다른 사람도 더 이상 이 브랜치를 받을 수 없습니다.';
  }

  @override
  String get branchNameLabel => '브랜치 이름';

  @override
  String get branchNameExists => '같은 이름의 브랜치가 이미 있습니다';

  @override
  String get branchNameEmpty => '이름을 입력하세요';

  @override
  String get branchNameInvalidCharacter => '공백과 ~ ^ : ? * [ \\ 는 쓸 수 없습니다';

  @override
  String get branchNameStartsWithDash => '-로 시작할 수 없습니다';

  @override
  String get branchNameInvalidSequence =>
      '.. 이나 //, .으로 시작하는 부분, .lock으로 끝나는 부분은 쓸 수 없습니다';

  @override
  String get branchNameInvalidEdge => '/ 로 시작하거나 / 또는 . 으로 끝날 수 없습니다';

  @override
  String get branchBaseLabel => '어디서 시작할까요';

  @override
  String branchBaseCurrent(String name) {
    return '현재 브랜치 ($name)';
  }

  @override
  String get branchSwitchAfter => '만든 뒤 바로 전환';

  @override
  String branchRenameUpstreamNote(String upstream) {
    return '원격의 $upstream은 그대로 남습니다. 새 이름으로 다시 게시하세요.';
  }

  @override
  String get remotesTitle => '원격';

  @override
  String get remotesAdd => '원격 추가';

  @override
  String get remotesRename => '이름 바꾸기';

  @override
  String get remotesSetUrl => 'URL 바꾸기';

  @override
  String get remotesRemove => '원격 삭제';

  @override
  String get remotesRemoveTitle => '원격을 삭제할까요?';

  @override
  String remotesRemoveMessage(String name) {
    return '이 저장소에서 $name 연결만 지웁니다. 서버의 저장소는 그대로 남습니다.';
  }

  @override
  String get remotesEmptyTitle => '이 저장소는 아직 GitHub에 없습니다';

  @override
  String get remotesEmptyMessage => 'GitHub에 새 저장소를 만들고 지금 브랜치를 올립니다.';

  @override
  String get remotesPublishToGitHub => 'GitHub에 올리기';

  @override
  String get remotesPublishAlsoToGitHub => 'GitHub에도 올리기 (원격 추가)';

  @override
  String get remotesPublishConfirm => '만들고 올리기';

  @override
  String get remotesNotGitHubNote =>
      'GitHub 저장소가 아니라서 PR·릴리스·Actions는 쓸 수 없습니다 (gh는 GitHub 전용).';

  @override
  String get remotesNameLabel => '원격 이름';

  @override
  String get remotesNameTaken => '같은 이름의 원격이 이미 있습니다';

  @override
  String get remotesNameInvalid => '공백과 특수 문자는 쓸 수 없습니다';

  @override
  String get remotesUrlLabel => 'URL';

  @override
  String get remotesUseHttps => 'HTTPS 주소로 바꾸기';

  @override
  String get remotesUseSsh => 'SSH 주소로 바꾸기';

  @override
  String get publishNameLabel => '저장소 이름';

  @override
  String get publishNameHelper => '조직에 만들려면 조직/이름';

  @override
  String get publishNameInvalid => '영문, 숫자, - _ . 만 쓸 수 있습니다';

  @override
  String get publishDescriptionLabel => '설명 (선택)';

  @override
  String get publishPrivate => '비공개';

  @override
  String get publishPublic => '공개';

  @override
  String get publishNoCommitsNote => '아직 커밋이 없어서 저장소만 만듭니다. 첫 커밋 뒤에 Push하세요.';

  @override
  String get editorTitle => '파일을 열 편집기';

  @override
  String get editorMessage =>
      '편집기 명령을 적으면 파일을 그 편집기로 엽니다. 비워 두면 OS 기본 앱으로 엽니다.';

  @override
  String get editorLabel => '편집기 명령';

  @override
  String get logTitle => '명령 기록';

  @override
  String get logClear => '지우기';

  @override
  String get logEmpty => '아직 실행한 명령이 없습니다';

  @override
  String get logToggleTooltip => '명령 기록 펼치기/접기';

  @override
  String get doneFetch => '원격 정보를 가져왔습니다';

  @override
  String get donePull => 'Pull을 마쳤습니다';

  @override
  String get donePush => 'Push를 마쳤습니다';

  @override
  String donePublish(String branch) {
    return '$branch 브랜치를 게시했습니다';
  }

  @override
  String get doneCommit => '커밋했습니다';

  @override
  String doneSwitch(String name) {
    return '$name(으)로 전환했습니다';
  }

  @override
  String doneCreateBranch(String name) {
    return '$name 브랜치를 만들었습니다';
  }

  @override
  String doneRenameBranch(String name) {
    return '이름을 $name(으)로 바꿨습니다';
  }

  @override
  String doneDeleteBranch(String name) {
    return '$name 브랜치를 삭제했습니다';
  }

  @override
  String doneAddRemote(String name) {
    return '$name 원격을 추가했습니다';
  }

  @override
  String doneRenameRemote(String name) {
    return '원격 이름을 $name(으)로 바꿨습니다';
  }

  @override
  String doneSetRemoteUrl(String name) {
    return '$name의 URL을 바꿨습니다';
  }

  @override
  String doneRemoveRemote(String name) {
    return '$name 원격을 삭제했습니다';
  }

  @override
  String donePublishToGitHub(String name) {
    return 'GitHub에 $name 저장소를 만들었습니다';
  }

  @override
  String get doneAbort => '중단했습니다';

  @override
  String get doneContinue => '계속 진행했습니다';

  @override
  String get errorGeneric => '명령이 실패했습니다. 아래 원문을 확인하세요.';

  @override
  String get errorPushRejected =>
      'Push가 거부됐습니다. 원격에 내게 없는 커밋이 있어서입니다. 먼저 Pull 하세요.';

  @override
  String get errorAuthFailed =>
      '인증에 실패했습니다. gh auth login으로 로그인했는지, SSH 키가 등록됐는지 확인하세요.';

  @override
  String get errorConflict => '충돌이 났습니다. 변경 탭에서 충돌 파일을 편집기로 열어 고친 뒤 해결됨을 누르세요.';

  @override
  String get errorLocalChanges => '커밋하지 않은 변경이 덮어써질 수 있어서 멈췄습니다. 먼저 커밋하세요.';

  @override
  String get errorNotFastForward =>
      '기록이 갈라져서 fast-forward로 받을 수 없습니다. Pull 방식을 병합이나 rebase로 바꾸세요.';

  @override
  String get errorProtectedBranch =>
      '보호된 브랜치라서 직접 Push할 수 없습니다. 새 브랜치로 올리고 PR을 만드세요.';

  @override
  String get errorBranchNotMerged => '병합되지 않은 커밋이 있는 브랜치입니다.';

  @override
  String get errorNoUpstream => '추적 브랜치가 없습니다. 먼저 게시(Publish)하세요.';

  @override
  String get errorAlreadyExists => '같은 이름이 이미 있습니다.';

  @override
  String get errorRepositoryNotFound => '원격 저장소를 찾을 수 없습니다. URL과 접근 권한을 확인하세요.';

  @override
  String get errorNetwork => '서버에 연결할 수 없습니다. 네트워크를 확인하세요.';

  @override
  String get errorNotInstalled => '프로그램을 찾을 수 없습니다. 메뉴의 환경 점검을 확인하세요.';

  @override
  String get timeJustNow => '방금';

  @override
  String timeMinutesAgo(int n) {
    return '$n분 전';
  }

  @override
  String timeHoursAgo(int n) {
    return '$n시간 전';
  }

  @override
  String timeDaysAgo(int n) {
    return '$n일 전';
  }

  @override
  String get helpTooltip => '이게 뭔가요?';

  @override
  String get helpSectionWord => '낱말 뜻';

  @override
  String get helpSectionInGit => 'git에서는';

  @override
  String get helpSectionWhy => '왜 · 언제 쓰나';

  @override
  String get helpSectionLinks => '더 알아보기';

  @override
  String get helpCaptionBefore => '전';

  @override
  String get helpCaptionAfter => '후';

  @override
  String get helpCaptionAfterFetch => 'Fetch 후 — 내 main은 그대로';

  @override
  String get helpCaptionAfterPull => 'Pull 후 — 내 main도 따라감';

  @override
  String get helpCaptionAheadOne => 'feature가 origin/feature보다 커밋 하나 앞섬 (↑1)';

  @override
  String get helpLinkBranchingBasics => 'Pro Git — 브랜치와 Merge의 기초';

  @override
  String get helpLinkRemoteBranches => 'Pro Git — 리모트 브랜치';

  @override
  String get helpLinkRebasing => 'Pro Git — Rebase 하기';

  @override
  String get helpFetchVsPullTitle => 'Fetch와 Pull';

  @override
  String get helpFetchVsPullWord => 'fetch는 \'가서 가져오다\', pull은 \'끌어당기다\'.';

  @override
  String get helpFetchVsPullInGit =>
      'Fetch는 원격(GitHub)에 새로 생긴 커밋을 내 컴퓨터로 가져와 origin/main 같은 \'원격 이름표\'만 옮깁니다. 내 브랜치와 파일은 건드리지 않습니다. Pull은 Fetch를 한 뒤, 가져온 커밋을 내 브랜치에 합칩니다.';

  @override
  String get helpFetchVsPullWhy =>
      '무엇이 바뀌었는지 먼저 보고 싶으면 Fetch — 안전하고 언제 해도 됩니다. 바로 최신으로 맞추려면 Pull. 커밋하지 않은 변경이 있으면 Pull이 멈출 수 있으니 먼저 커밋하세요.';

  @override
  String get helpUpstreamTitle => '추적 브랜치 (upstream)와 origin';

  @override
  String get helpUpstreamWord =>
      'upstream은 \'상류\'. 물이 흘러오는 쪽입니다. origin은 \'출처, 기원\'.';

  @override
  String get helpUpstreamInGit =>
      'origin은 저장소를 받아 온 원격(대개 GitHub)에 붙는 기본 이름입니다. 내 브랜치가 짝지어 둔 원격 브랜치(예: origin/feature)를 추적 브랜치, 곧 upstream이라고 합니다. ↑↓ 숫자는 이 짝과 비교한 것입니다.';

  @override
  String get helpUpstreamWhy =>
      '짝이 있어야 그냥 Push, Pull만 눌러도 어디로 보내고 어디서 받을지 압니다. 새 브랜치에는 짝이 없어서 처음 한 번은 \'게시\'(git push -u)로 짝을 지어 줍니다.';

  @override
  String get helpFastForwardTitle => 'Fast-forward (빨리 감기)';

  @override
  String get helpFastForwardWord => '테이프나 영상을 앞으로 빨리 감는 것.';

  @override
  String get helpFastForwardInGit =>
      '내 브랜치가 갈라진 적 없이 뒤처져 있기만 할 때, 새 커밋을 만들지 않고 브랜치 이름표를 최신 커밋 위치로 앞으로 옮기기만 합니다. 이미 있는 커밋을 따라 \'앞으로 감기\'만 하므로 이렇게 부릅니다.';

  @override
  String get helpFastForwardWhy =>
      '기록이 한 줄로 깔끔하고 합칠 것이 없으니 충돌도 없습니다. 양쪽에 서로 다른 새 커밋이 있으면(갈라졌으면) 빨리 감을 수 없어서, \'Fast-forward만\'은 멈추고 병합이나 rebase가 필요합니다. Push가 non-fast-forward로 거부되는 것도 같은 이유입니다.';

  @override
  String get helpMergeCommitTitle => '병합 커밋 (merge commit)';

  @override
  String get helpMergeCommitWord => 'merge는 \'합치다\', 두 길이 하나로 합류하는 것.';

  @override
  String get helpMergeCommitInGit =>
      '갈라진 두 기록을 그대로 두고, 둘을 부모로 가진 새 커밋(병합 커밋)을 하나 만들어 합칩니다. 누가 언제 무엇을 합쳤는지 기록에 그대로 남습니다.';

  @override
  String get helpMergeCommitWhy =>
      '이미 올린 커밋을 바꾸지 않아 가장 안전합니다. 다른 사람과 같이 쓰는 브랜치에 알맞습니다. 대신 기록에 병합 커밋이 늘어 조금 복잡해 보입니다.';

  @override
  String get helpRebaseTitle => 'Rebase';

  @override
  String get helpRebaseWord => 'base는 \'밑받침\', rebase는 \'밑받침을 다시 놓다\'.';

  @override
  String get helpRebaseInGit =>
      '내 커밋들을 떼어 내서, 새로 받아온 커밋 뒤에 차례로 다시 붙입니다. 내용은 같지만 새 커밋(C\', D\')으로 다시 만들어지고, 기록은 한 줄이 됩니다.';

  @override
  String get helpRebaseWhy =>
      '병합 커밋 없이 기록이 깔끔합니다. 아직 Push하지 않은 내 커밋에만 쓰세요. 이미 올린 커밋을 rebase하면 다른 사람의 기록과 어긋나서 강제 Push가 필요해집니다.';
}
