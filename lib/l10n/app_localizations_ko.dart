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

  @override
  String get tabTags => '태그';

  @override
  String get tabRelease => '릴리스';

  @override
  String get tabPr => 'PR';

  @override
  String branchesMergeInto(String head) {
    return '$head(으)로 병합해 오기';
  }

  @override
  String mergeTitle(String source, String into) {
    return '$source → $into 병합';
  }

  @override
  String mergeNothing(String source, String into) {
    return '$source에는 $into에 없는 커밋이 없습니다';
  }

  @override
  String mergeIncoming(int count) {
    return '들어올 커밋 $count개';
  }

  @override
  String get mergeFastForward => 'Fast-forward';

  @override
  String get mergeFastForwardWhen => '새 커밋 없이 이름표만 앞으로 옮깁니다. 기록이 한 줄로 남습니다.';

  @override
  String get mergeFastForwardDisabled => '현재 브랜치에도 새 커밋이 있어서(갈라져서) 쓸 수 없습니다.';

  @override
  String get mergeMergeCommit => '병합 커밋';

  @override
  String get mergeMergeCommitWhen => '두 기록을 그대로 두고 병합 커밋으로 합칩니다. 가장 안전합니다.';

  @override
  String get mergeSquash => 'Squash';

  @override
  String get mergeSquashWhen => '브랜치의 커밋을 하나로 눌러 합칩니다. 기능 하나 = 커밋 하나.';

  @override
  String mergeSquashNote(String source) {
    return 'squash 뒤 $source를 계속 쓰면 같은 변경이 다시 충돌할 수 있습니다. 병합 후 브랜치를 지우는 것을 권합니다.';
  }

  @override
  String get mergeMessageLabel => '커밋 메시지';

  @override
  String get mergeConfirm => '병합';

  @override
  String doneMerge(String source, String into) {
    return '$source을(를) $into(으)로 병합했습니다';
  }

  @override
  String get tagsTitle => '태그';

  @override
  String get tagsNew => '새 태그';

  @override
  String get tagsCreate => '만들기';

  @override
  String get tagsCreateAndPush => '만들고 push';

  @override
  String tagsPushAll(int count) {
    return '원격에 없는 태그 $count개 push';
  }

  @override
  String get tagsPushed => '원격에 있음';

  @override
  String get tagsLocalOnly => '내 컴퓨터에만 있음';

  @override
  String get tagsLightweight => '가벼운 태그';

  @override
  String get tagsAnnotated => '주석 태그';

  @override
  String get tagsPush => 'Push';

  @override
  String get tagsDelete => '삭제';

  @override
  String get tagsDeleteRemote => '원격에서 삭제';

  @override
  String get tagsDeleteRemoteTitle => '원격 태그를 삭제할까요?';

  @override
  String tagsDeleteRemoteMessage(String tag, String target) {
    return '$target에서 $tag 태그를 삭제합니다. 이미 받아 간 사람이 있을 수 있으니, 같은 이름을 다시 쓰기보다 다음 번호를 쓰세요.';
  }

  @override
  String get tagsEmptyTitle => '아직 태그가 없습니다';

  @override
  String get tagsEmptyMessage =>
      '태그는 특정 커밋에 붙이는 이름표입니다. 보통 v1.0.0처럼 릴리스 버전에 씁니다.';

  @override
  String tagsPushAfter(String remote) {
    return '만든 뒤 $remote에 push';
  }

  @override
  String get tagNameLabel => '태그 이름';

  @override
  String get tagNameExists => '같은 이름의 태그가 이미 있습니다';

  @override
  String get tagNameInvalid => '공백, .., ~ ^ : ? * [ \\ 는 쓸 수 없습니다';

  @override
  String get tagNameNotSemVer =>
      '버전 형식(v1.2.3)이 아닙니다. 만들 수는 있지만 릴리스에는 버전 형식을 권합니다.';

  @override
  String get tagNameMissingV => '릴리스 태그는 v를 붙이는 것이 관례입니다 (v1.2.3).';

  @override
  String get tagMessageLabel => '메시지';

  @override
  String get tagTargetLabel => '어느 커밋에 달까요';

  @override
  String tagTargetHead(String name) {
    return '현재 위치 ($name)';
  }

  @override
  String doneCreateTag(String name) {
    return '$name 태그를 만들었습니다';
  }

  @override
  String donePushTags(int count) {
    return '태그 $count개를 push했습니다';
  }

  @override
  String doneDeleteTag(String name) {
    return '$name 태그를 삭제했습니다';
  }

  @override
  String doneDeleteRemoteTag(String name) {
    return '원격에서 $name 태그를 삭제했습니다';
  }

  @override
  String get prTitle => 'Pull Request';

  @override
  String get prCreate => 'PR 만들기';

  @override
  String get prPublishAndCreate => '게시하고 PR 만들기';

  @override
  String get prTitleLabel => '제목';

  @override
  String get prBodyLabel => '본문';

  @override
  String get prBodyChanges => '변경 내용';

  @override
  String get prDraft => '초안으로 만들기';

  @override
  String get prNotGitHubTitle => 'GitHub 저장소가 아닙니다';

  @override
  String get prNotGitHubMessage =>
      'Pull Request는 GitHub 저장소에서만 쓸 수 있습니다 — gh는 GitHub 전용 도구입니다.';

  @override
  String get prGhRequiredTitle => 'gh가 필요합니다';

  @override
  String get prDetached => '브랜치에 있지 않습니다';

  @override
  String get prOnDefaultTitle => '기본 브랜치에 있습니다';

  @override
  String get prOnDefaultMessage => 'PR은 작업 브랜치에서 만듭니다. 브랜치 탭에서 새 브랜치를 만드세요.';

  @override
  String prNoneTitle(String head) {
    return '$head에는 아직 PR이 없습니다';
  }

  @override
  String prNoneMessage(String base) {
    return '$base(으)로 합칠 PR을 만들면 GitHub에서 검토와 검사를 거쳐 병합합니다.';
  }

  @override
  String get prOpenOnGitHub => 'GitHub에서 보기';

  @override
  String get prStateOpen => '열림';

  @override
  String get prStateDraft => '초안';

  @override
  String get prStateMerged => '병합됨';

  @override
  String get prStateClosed => '닫힘';

  @override
  String get prNoChecks => '검사 없음';

  @override
  String prChecksPassed(int n) {
    return '통과 $n';
  }

  @override
  String prChecksFailed(int n) {
    return '실패 $n';
  }

  @override
  String prChecksPending(int n) {
    return '진행 중 $n';
  }

  @override
  String get prApproved => '승인됨';

  @override
  String get prReviewRequired => '리뷰 필요';

  @override
  String get prBlockedDraft =>
      '초안 PR은 병합할 수 없습니다. GitHub에서 \'검토 준비 완료\'로 바꾸세요.';

  @override
  String get prBlockedConflict => '기준 브랜치와 충돌이 있습니다. 기준 브랜치를 병합해 와서 충돌을 해결하세요.';

  @override
  String prBlockedChecks(String names) {
    return '실패한 검사가 있습니다: $names';
  }

  @override
  String prBlockedPending(int count) {
    return '검사 $count개가 아직 진행 중입니다.';
  }

  @override
  String get prBlockedReview => '리뷰 승인이 필요할 수 있습니다. 병합이 거부되면 GitHub에서 확인하세요.';

  @override
  String get prMethodMerge => '병합 커밋 (merge)';

  @override
  String get prMethodSquash => 'Squash 후 병합';

  @override
  String get prMethodRebase => 'Rebase 후 병합';

  @override
  String get prDeleteBranch => '병합 후 브랜치 삭제';

  @override
  String get prMerge => '병합하기';

  @override
  String get donePrCreated => 'PR을 만들었습니다';

  @override
  String donePrMerged(int number) {
    return 'PR #$number을(를) 병합했습니다';
  }

  @override
  String get releaseTitle => '릴리스';

  @override
  String releaseLatest(String tag) {
    return '마지막 릴리스 $tag';
  }

  @override
  String get releaseNoTags => '아직 릴리스가 없습니다';

  @override
  String get releaseIntro => '버전 올리기 → PR → 병합 → 태그 → CI 확인을 차례로 안내합니다.';

  @override
  String get releaseNeedsGitHub =>
      '릴리스 마법사는 GitHub 저장소에서 쓸 수 있습니다. 태그는 태그 탭에서 만들 수 있습니다.';

  @override
  String get releaseStart => '새 릴리스';

  @override
  String get releaseNew => '새 릴리스';

  @override
  String releaseNewVersion(String tag) {
    return '새 릴리스 $tag';
  }

  @override
  String get releaseCancel => '그만두기';

  @override
  String get releaseCancelTitle => '릴리스를 그만둘까요?';

  @override
  String releaseCancelMessage(String branch) {
    return '지금까지 만든 $branch 브랜치와 PR은 그대로 남습니다. 필요 없으면 직접 지우세요.';
  }

  @override
  String get releaseCancelAfterTag =>
      '태그는 이미 push되었습니다. 마법사만 닫고, CI와 릴리스는 GitHub에서 확인하세요.';

  @override
  String releaseDone(String tag) {
    return '$tag 릴리스를 마쳤습니다';
  }

  @override
  String get releasePrerelease => '프리릴리스';

  @override
  String get releasePushAndPr => 'push하고 PR 만들기';

  @override
  String get stepCheck => '점검';

  @override
  String get stepVersion => '버전';

  @override
  String get stepPr => 'PR';

  @override
  String get stepMerge => '병합';

  @override
  String get stepTag => '태그';

  @override
  String get stepNotes => '릴리스 노트';

  @override
  String get stepNotesCi => '노트 (CI 릴리스 후)';

  @override
  String get stepNotesCiSummary => 'CI가 릴리스를 만듭니다';

  @override
  String get stepCi => 'CI 확인';

  @override
  String get stepNext => '다음';

  @override
  String get stepCheckDone => '모두 통과';

  @override
  String stepMergeDone(int number) {
    return 'PR #$number 병합됨';
  }

  @override
  String get checkCleanTree => '커밋하지 않은 변경이 없다';

  @override
  String get checkShowChanges => '변경 보기';

  @override
  String checkOnDefault(String branch) {
    return '기본 브랜치($branch)에 있다';
  }

  @override
  String get checkSynced => '원격과 같다';

  @override
  String get checkGitHub => 'GitHub 원격과 gh 로그인';

  @override
  String checkChangesSince(int count, String tag) {
    return '$tag 이후 커밋 $count개';
  }

  @override
  String get checkFirstRelease => '첫 릴리스입니다';

  @override
  String get checkNoWorkflow => '태그로 도는 워크플로가 없습니다. 앱이 GitHub 릴리스를 만듭니다.';

  @override
  String checkWorkflowCi(String file) {
    return '$file이(가) 태그 push로 릴리스를 만듭니다. 앱은 태그까지 달고 CI를 지켜봅니다.';
  }

  @override
  String checkWorkflowOther(String file) {
    return '$file이(가) 태그 push로 돕니다.';
  }

  @override
  String get manualBuildTitle => '태그 전 수동 빌드 (권장)';

  @override
  String get manualBuildWhy =>
      '지난 릴리스 이후 빌드에 영향을 주는 파일이 바뀌었습니다. 태그 전에 모든 플랫폼이 빌드되는지 확인하세요. 수동 실행은 릴리스를 만들지 않습니다.';

  @override
  String get manualBuildStart => '빌드만 확인';

  @override
  String manualBuildShort(String state) {
    return '수동 빌드 $state';
  }

  @override
  String get doneManualBuildStarted => '수동 빌드를 시작했습니다';

  @override
  String versionCurrent(String version, String source) {
    return '현재 $version ($source)';
  }

  @override
  String get versionFromTag => '마지막 태그';

  @override
  String get versionRecommended => '추천';

  @override
  String versionReason(int feats, int fixes, int breaking) {
    return '새 기능 $feats · 버그 수정 $fixes · 호환 깨짐 $breaking';
  }

  @override
  String get versionCustom => '직접 입력';

  @override
  String get versionFiles => '바뀌는 파일';

  @override
  String get versionNoFiles => '버전 파일이 없어서 태그만 만듭니다.';

  @override
  String get versionCommit => '릴리스 브랜치 만들고 커밋';

  @override
  String get bumpFinal => '정식';

  @override
  String get bumpPrerelease => '프리릴리스';

  @override
  String doneReleaseCommit(String tag) {
    return '$tag 버전 올림을 커밋했습니다';
  }

  @override
  String mergeWaiting(int number) {
    return 'PR #$number 병합을 기다리는 중 — GitHub에서 병합해도 알아챕니다';
  }

  @override
  String tagCheckPrMerged(int number) {
    return 'PR #$number이(가) 병합됐다';
  }

  @override
  String tagCheckSynced(String branch) {
    return '$branch에 있고 원격과 같다';
  }

  @override
  String tagCheckVersion(String tag) {
    return '버전 파일이 $tag와 같다';
  }

  @override
  String tagCheckVersionWrong(String version) {
    return '지금 버전은 $version입니다. 버전 올림 PR이 아직 병합되지 않았을 수 있습니다.';
  }

  @override
  String tagCheckFree(String tag) {
    return '$tag 태그가 아직 없다';
  }

  @override
  String tagConfirmTitle(String tag) {
    return '$tag 태그를 push할까요?';
  }

  @override
  String tagConfirmMessage(String tag, String branch) {
    return '$branch의 병합 커밋에 $tag를 답니다. push하면 릴리스가 공개되고, 태그는 옮기거나 지우지 않는 것이 규칙입니다.';
  }

  @override
  String get tagConfirmPush => '태그 달고 push';

  @override
  String doneTagPushed(String tag) {
    return '$tag 태그를 push했습니다';
  }

  @override
  String get notesLabel => '릴리스 노트 (마크다운)';

  @override
  String get notesFeatures => '새 기능';

  @override
  String get notesFixes => '버그 수정';

  @override
  String get notesOther => '기타';

  @override
  String get notesCreateRelease => 'GitHub 릴리스 만들기';

  @override
  String get notesEdit => '노트 고치기';

  @override
  String get doneReleaseCreated => 'GitHub 릴리스를 만들었습니다';

  @override
  String get doneNotesSaved => '릴리스 노트를 저장했습니다';

  @override
  String ciWaitingForRun(String tag) {
    return '$tag(으)로 시작된 워크플로를 찾는 중';
  }

  @override
  String get ciOpenInBrowser => '브라우저에서 보기';

  @override
  String get ciRerunFailed => '실패한 잡 다시 실행';

  @override
  String get doneRerun => '실패한 잡을 다시 실행했습니다';

  @override
  String get runQueued => '대기 중';

  @override
  String get runRunning => '진행 중';

  @override
  String get runSuccess => '성공';

  @override
  String get runFailure => '실패';

  @override
  String get runCancelled => '취소됨';

  @override
  String get runSkipped => '건너뜀';

  @override
  String get helpCaptionAfterSquash => 'squash 병합 후 — main에 새 커밋 S 하나';

  @override
  String get helpCaptionTag =>
      'v1.0.0과 v1.1.0은 옮겨지지 않는 이름표, main은 앞으로 나아가는 이름표';

  @override
  String get helpLinkGitHubMergeMethods => 'GitHub — 병합 방법 정보';

  @override
  String get helpLinkTagging => 'Pro Git — 태그';

  @override
  String get helpSquashTitle => 'Squash (눌러 합치기)';

  @override
  String get helpSquashWord => '눌러서 납작하게 만들다, 찌그러뜨리다.';

  @override
  String get helpSquashInGit =>
      '브랜치의 여러 커밋을 눌러 커밋 하나로 합친 뒤 대상 브랜치에 올립니다. 변경 내용은 그대로이고 커밋 개수만 하나가 됩니다.';

  @override
  String get helpSquashWhy =>
      '\'오타 수정\', \'다시 시도\' 같은 작업 중 커밋을 기본 브랜치 기록에 남기지 않고, 기능 하나 = 커밋 하나로 정리합니다. PR을 병합할 때 많이 씁니다. 원래 커밋들은 기본 브랜치에 남지 않으니, 병합한 브랜치를 계속 쓰지 말고 지우세요.';

  @override
  String get helpTagTitle => '태그 (주석 태그와 가벼운 태그)';

  @override
  String get helpTagWord => 'tag는 \'꼬리표, 이름표\'.';

  @override
  String get helpTagInGit =>
      '특정 커밋에 붙이는 이름표입니다. 브랜치 이름표는 새 커밋을 따라 앞으로 가지만, 태그는 한 번 붙이면 그 커밋에 머뭅니다. 주석 태그는 만든 사람·날짜·메시지를 함께 저장하고, 가벼운 태그는 이름만 저장합니다.';

  @override
  String get helpTagWhy =>
      '릴리스 버전(v1.2.0)에는 주석 태그를 씁니다 — 릴리스 기록이 남고, GitHub 릴리스와 CI가 태그를 기준으로 돕니다. 이미 push한 태그는 옮기거나 지우지 말고, 잘못됐으면 다음 번호로 새로 다세요.';

  @override
  String get headerMergedAndGone => '병합됨 · 원격 삭제됨';

  @override
  String get headerMergedAndGoneTooltip =>
      '이 브랜치는 이미 기본 브랜치에 병합되었고 원격에서 삭제되었습니다. 다시 게시하면 지운 브랜치가 되살아납니다.';

  @override
  String bannerMergedAndGone(String branch) {
    return '이 브랜치는 병합되어 원격에서 삭제되었습니다. $branch(으)로 돌아가세요';
  }

  @override
  String bannerSwitchTo(String branch) {
    return '$branch(으)로 전환';
  }

  @override
  String bannerCreatePr(String branch) {
    return '$branch을(를) 올렸지만 아직 PR이 없습니다';
  }

  @override
  String get prBaseLabel => '기준 브랜치';

  @override
  String prBaseNotDefault(String base) {
    return '기본 브랜치($base)가 아닌 곳으로 합칩니다. 다른 기능 브랜치 위에 쌓는 PR일 때 씁니다.';
  }

  @override
  String get tabCi => 'CI';

  @override
  String get ciTitle => 'CI 실행';

  @override
  String get ciNotGitHubMessage =>
      'Actions는 GitHub 저장소에서만 쓸 수 있습니다 — gh는 GitHub 전용 도구입니다.';

  @override
  String ciEmptyTitle(String branch) {
    return '$branch에는 아직 실행이 없습니다';
  }

  @override
  String get ciEmptyMessage => 'push나 PR, 태그로 워크플로가 돌면 여기에 나옵니다.';

  @override
  String get ciRerun => '다시 실행';

  @override
  String get ciCancel => '취소';

  @override
  String get ciDispatch => '수동 실행';

  @override
  String get ciDispatchNeedsPush => '수동 실행은 원격에 있는 브랜치에서만 할 수 있습니다. 먼저 게시하세요.';

  @override
  String ciDispatchTitle(String file) {
    return '$file 수동 실행';
  }

  @override
  String ciDispatchMessage(String branch) {
    return '$branch 브랜치로 워크플로를 실행합니다. 입력이 필요한 워크플로는 브라우저에서 실행하세요.';
  }

  @override
  String get ciDispatchConfirm => '실행';

  @override
  String doneDispatched(String file) {
    return '$file을(를) 실행했습니다';
  }

  @override
  String get doneRunCancelled => '실행을 취소했습니다';

  @override
  String notifyRunTitle(String name, String state) {
    return '$name $state';
  }

  @override
  String notifyReleaseRun(String tag, String state) {
    return '$tag 릴리스 CI $state';
  }

  @override
  String notifyManualBuild(String state) {
    return '태그 전 수동 빌드 $state';
  }

  @override
  String get prFilterMine => '내 PR';

  @override
  String get prFilterReview => '리뷰 요청';

  @override
  String get prFilterOpen => '전체';

  @override
  String get prListEmpty => '열린 PR이 없습니다';

  @override
  String get prCurrentBranch => '현재 브랜치';

  @override
  String get prCheckout => '이 PR 브랜치로 체크아웃';

  @override
  String get prCheckoutWhy => 'PR 브랜치를 내 컴퓨터로 가져와 전환합니다. 직접 실행해 보거나 고칠 때 씁니다.';

  @override
  String donePrCheckout(int number, String branch) {
    return 'PR #$number의 $branch(으)로 전환했습니다';
  }

  @override
  String get releasesTitle => '릴리스';

  @override
  String get releasesEmpty => 'GitHub 릴리스가 없습니다';

  @override
  String get releasesLoadFailed => '릴리스 목록을 불러오지 못했습니다';

  @override
  String get releaseLatestPill => '최신';

  @override
  String get releaseDraft => '초안';

  @override
  String get releaseMakeFinal => '정식 릴리스로 바꾸기';

  @override
  String get releaseMakePrerelease => '프리릴리스로 바꾸기';

  @override
  String get releasePublishDraft => '초안 게시';

  @override
  String get releaseDelete => '릴리스 삭제';

  @override
  String releaseDeleteTitle(String tag) {
    return '$tag 릴리스를 삭제할까요?';
  }

  @override
  String get releaseDeleteMessage =>
      'GitHub 릴리스와 올라간 파일이 사라집니다. 이미 받아 간 사람이 있을 수 있습니다.';

  @override
  String releaseDeleteTagToo(String tag) {
    return 'GitHub의 $tag 태그도 삭제 (로컬 태그는 남음)';
  }

  @override
  String doneReleaseDeleted(String tag) {
    return '$tag 릴리스를 삭제했습니다';
  }

  @override
  String doneReleaseMadeFinal(String tag) {
    return '$tag을(를) 정식 릴리스로 바꿨습니다';
  }

  @override
  String doneReleaseMadePrerelease(String tag) {
    return '$tag을(를) 프리릴리스로 바꿨습니다';
  }

  @override
  String doneReleasePublished(String tag) {
    return '$tag 초안을 게시했습니다';
  }

  @override
  String get notesEditTab => '편집';

  @override
  String get notesPreviewTab => '미리 보기';

  @override
  String get notesEmpty => '내용이 없습니다';

  @override
  String tagVersionMismatch(String file, String version, String tag) {
    return '$file의 버전은 $version인데 태그는 $tag입니다.';
  }

  @override
  String get tagVersionMismatchWhy =>
      '릴리스 태그는 버전을 먼저 올린 커밋에 달아야 합니다 — 릴리스 마법사가 버전 올림 PR부터 태그까지 차례로 합니다.';

  @override
  String get tagVersionMismatchCi =>
      '이 저장소는 태그를 push하면 CI가 릴리스를 만드는데, 버전이 다르면 CI가 멈춥니다.';

  @override
  String get tagVersionMismatchBlocked =>
      '그래서 push는 막았습니다. 로컬에만 만들려면 push를 끄세요.';

  @override
  String get tagOpenReleaseWizard => '릴리스 마법사 열기';

  @override
  String get tabHistory => '기록';

  @override
  String get menuAutoFetch => '자동 fetch (5분마다·돌아올 때)';

  @override
  String get changesAmendToggle => '직전 커밋 고치기';

  @override
  String get changesAmend => '직전 커밋 고치기';

  @override
  String get changesAmendPushedWarning =>
      '이미 원격에 올린 커밋입니다. 고치면 기록이 갈라져 강제 push(force-with-lease)가 필요합니다.';

  @override
  String get doneAmend => '직전 커밋을 고쳤습니다';

  @override
  String get changesDiscard => '변경 취소';

  @override
  String changesDiscardMessage(String path) {
    return '$path의 커밋하지 않은 변경을 버리고 마지막으로 스테이징(또는 커밋)한 상태로 되돌립니다. 되돌릴 수 없습니다.';
  }

  @override
  String get changesDeleteUntracked => '파일 삭제';

  @override
  String changesDeleteUntrackedMessage(String path) {
    return 'git이 추적하지 않는 $path을(를) 지웁니다. 휴지통으로 가지 않습니다.';
  }

  @override
  String get conflictUseMine => '내 것 사용';

  @override
  String get conflictUseIncoming => '들어오는 것 사용';

  @override
  String doneFileAction(String name) {
    return '$name: 완료';
  }

  @override
  String get stashTitle => '임시 저장 (stash)';

  @override
  String get stashSave => '임시 저장';

  @override
  String stashWhy(int count) {
    return '변경 $count개를 커밋하지 않고 따로 치워 둡니다. 추적하지 않는 파일도 함께 저장합니다. 나중에 \'다시 적용\'으로 되살립니다.';
  }

  @override
  String get stashMessageLabel => '메모 (선택)';

  @override
  String get stashPop => '적용하고 지우기 (pop)';

  @override
  String get stashApply => '적용만 하기 (apply)';

  @override
  String get stashDrop => '삭제';

  @override
  String get stashDropTitle => '임시 저장을 삭제할까요?';

  @override
  String stashDropMessage(String text) {
    return '\'$text\'에 저장한 변경이 사라집니다.';
  }

  @override
  String get stashAndRetry => '임시 저장하고 다시';

  @override
  String get stashAutoMessage => 'Branch Dock: 자동 임시 저장';

  @override
  String get doneStashSaved => '임시 저장했습니다';

  @override
  String get doneStashApplied => '임시 저장을 적용했습니다';

  @override
  String get doneStashDropped => '임시 저장을 삭제했습니다';

  @override
  String get doneStashAndRetry =>
      '변경을 임시 저장하고 다시 실행했습니다. 변경 탭의 임시 저장에서 되살릴 수 있습니다.';

  @override
  String get pushOptionsTooltip => 'Push 옵션';

  @override
  String get pushOptionsTitle => 'Push 옵션';

  @override
  String get pushFollowTags => '태그도 함께 push (--follow-tags)';

  @override
  String get pushFollowTagsWhy => '올리는 커밋에 달린 주석 태그를 함께 올립니다. 이 저장소에만 적용됩니다.';

  @override
  String get pushForceTitle => '강제 push (force-with-lease)';

  @override
  String get pushForceWhy =>
      'amend나 rebase로 이미 올린 커밋을 고쳤을 때만 씁니다. 내가 모르는 원격 커밋이 있으면 git이 거부해서 다른 사람의 작업을 덮어쓰지 않습니다.';

  @override
  String pushForceBlockedDefault(String branch) {
    return '기본 브랜치($branch)에서는 강제 push를 막았습니다 — 다른 사람의 기록을 덮어쓸 수 있습니다.';
  }

  @override
  String get pushForce => '강제 push';

  @override
  String pushForceConfirmTitle(String branch) {
    return '$branch을(를) 강제 push할까요?';
  }

  @override
  String pushForceConfirmMessage(String branch, String upstream) {
    return '$upstream의 기록을 내 $branch로 바꿉니다. 내가 fetch한 뒤 누가 push했다면 git이 거부합니다.';
  }

  @override
  String get operationSkip => '건너뛰기';

  @override
  String get operationSkipTooltip => '충돌 난 이 커밋을 빼고 rebase를 계속합니다';

  @override
  String get doneSkip => '커밋을 건너뛰었습니다';

  @override
  String get branchesSetUpstream => '추적 브랜치 설정';

  @override
  String branchesSetUpstreamWhy(String branch) {
    return '$branch이(가) Push·Pull할 원격 브랜치를 정합니다.';
  }

  @override
  String get branchesUpstreamLabel => '원격 브랜치';

  @override
  String doneSetUpstream(String branch, String upstream) {
    return '$branch의 추적 브랜치를 $upstream(으)로 정했습니다';
  }

  @override
  String get branchesCleanup => '병합된 브랜치 정리';

  @override
  String cleanupWhy(String base) {
    return '$base에 이미 병합됐거나 원격에서 지워진 로컬 브랜치입니다. 원격 브랜치는 건드리지 않습니다.';
  }

  @override
  String get cleanupMerged => '병합됨';

  @override
  String get cleanupGoneNotMerged => '원격에서 삭제됨 · 병합 안 됨 — 지우면 커밋을 찾기 어려워집니다';

  @override
  String cleanupConfirm(int count) {
    return '$count개 삭제';
  }

  @override
  String cleanupNothing(String base) {
    return '정리할 브랜치가 없습니다 ($base에 병합된 브랜치 없음)';
  }

  @override
  String doneCleanup(int count) {
    return '브랜치 $count개를 정리했습니다';
  }

  @override
  String get tagsCommitsSince => '이전 태그 이후 커밋';

  @override
  String tagsCommitsBetween(String from, String to) {
    return '$from → $to';
  }

  @override
  String tagsCommitsUpTo(String tag) {
    return '$tag까지';
  }

  @override
  String tagsCommitsCount(int count) {
    return '커밋 $count개';
  }

  @override
  String get tagsCheckout => '이 태그로 이동';

  @override
  String tagsCheckoutTitle(String tag) {
    return '$tag(으)로 이동할까요?';
  }

  @override
  String get tagsCheckoutMessage =>
      '태그 위치의 파일을 그대로 볼 수 있습니다. 이때는 어느 브랜치에도 있지 않은 \'분리된 HEAD\' 상태라, 여기서 커밋하려면 먼저 브랜치를 만드세요.';

  @override
  String doneCheckoutTag(String tag) {
    return '$tag(으)로 이동했습니다';
  }

  @override
  String get bannerDetached => '어느 브랜치에도 있지 않습니다. 여기서 커밋하려면 브랜치를 만드세요';

  @override
  String get historyTitle => '기록';

  @override
  String historyUnpushed(int count) {
    return '↑ 올리지 않은 커밋 $count';
  }

  @override
  String get historyNotPushed => '아직 올리지 않음';

  @override
  String get historyCopyHash => '해시 복사';

  @override
  String get historyBranchHere => '여기서 브랜치 만들기';

  @override
  String get historyTagHere => '여기에 태그 달기';

  @override
  String get helpLinkStashing => 'Pro Git — Stashing과 Cleaning';

  @override
  String get helpCaptionStash => '커밋하지 않은 변경 W를 stash 목록 맨 위에 치워 둠 — main은 그대로';

  @override
  String get helpStashTitle => 'Stash (임시 저장)';

  @override
  String get helpStashWord => 'stash는 \'넣어 두다, 숨겨 두다\'. 잠깐 서랍에 치워 두는 것.';

  @override
  String get helpStashInGit =>
      '커밋하지 않은 변경을 브랜치 기록에 남기지 않고 따로 저장한 뒤, 작업 트리를 깨끗하게 되돌립니다. 저장한 변경은 목록에 쌓이고(가장 최근 것이 맨 위), 나중에 어느 브랜치에서든 다시 적용할 수 있습니다.';

  @override
  String get helpStashWhy =>
      '하던 일을 커밋하기엔 이른데 브랜치를 바꾸거나 Pull해야 할 때 씁니다. \'pop\'은 적용하고 목록에서 지우고, \'apply\'는 목록에 남겨 둡니다. 오래 두면 무엇이었는지 잊기 쉬우니 메모를 남기세요.';

  @override
  String get helpCaptionDetached => 'HEAD가 브랜치가 아니라 v1.0.0 커밋을 직접 가리킴';

  @override
  String get helpDetachedTitle => '분리된 HEAD (detached HEAD)';

  @override
  String get helpDetachedWord =>
      'detached는 \'떨어진, 분리된\'. HEAD는 \'지금 보고 있는 곳\'.';

  @override
  String get helpDetachedInGit =>
      '보통 HEAD는 브랜치 이름표를 가리키고, 커밋하면 그 이름표가 앞으로 갑니다. 태그나 커밋으로 직접 이동하면 HEAD가 브랜치에서 떨어져 커밋을 직접 가리킵니다.';

  @override
  String get helpDetachedWhy =>
      '옛 버전을 실행해 보거나 비교할 때 안전하게 쓸 수 있습니다. 여기서 커밋하면 어느 브랜치에도 속하지 않아 다른 곳으로 옮기면 찾기 어려워지니, 커밋하려면 먼저 \'여기서 브랜치 만들기\'를 하세요.';

  @override
  String get helpForceTitle => '강제 push (force-with-lease)';

  @override
  String get helpForceWord =>
      'force는 \'억지로\', lease는 \'임대 계약\' — 내가 본 상태 그대로일 때만 바꾼다는 조건.';

  @override
  String get helpForceInGit =>
      'amend나 rebase로 이미 올린 커밋을 고치면 원격 기록과 갈라져 보통 push가 거부됩니다. 강제 push는 원격 브랜치를 내 기록으로 바꿉니다. --force-with-lease는 원격이 내가 마지막으로 fetch한 상태 그대로일 때만 바꾸고, 그 사이 누가 push했으면 거부합니다.';

  @override
  String get helpForceWhy =>
      '혼자 쓰는 작업 브랜치에서 기록을 정리했을 때만 씁니다. 여러 사람이 쓰는 브랜치, 특히 main에서는 쓰지 않습니다. 이 앱은 --force(무조건)는 제공하지 않고, 기본 브랜치에서는 막습니다.';

  @override
  String get menuBrowse => '브라우저에서 저장소 열기';

  @override
  String get menuSnapRight => '화면 오른쪽에 붙이기';

  @override
  String get menuSnapLeft => '화면 왼쪽에 붙이기';

  @override
  String get startInitRepository => '이 폴더를 git 저장소로 만들기';

  @override
  String get cloneTitle => 'GitHub에서 복제';

  @override
  String get cloneSearch => '내 저장소 찾기';

  @override
  String get cloneEmpty => '저장소가 없습니다';

  @override
  String get cloneNoFolder => '복제할 위치를 고르세요';

  @override
  String get cloneChooseFolder => '위치 고르기';

  @override
  String cloneExists(String path) {
    return '이미 있는 폴더입니다: $path';
  }

  @override
  String get cloneConfirm => '복제하고 열기';

  @override
  String get cloneRunning => '복제하는 중…';

  @override
  String get loginTitle => 'GitHub 로그인';

  @override
  String get loginSsh => 'SSH';

  @override
  String get loginHttps => 'HTTPS';

  @override
  String get loginSshRecommended => 'SSH 권장';

  @override
  String get loginSshWhy =>
      'SSH 주소의 원격이나 SSH로 접속한 환경에서는 HTTPS로 로그인하면 push 때 인증이 따로 놀 수 있습니다.';

  @override
  String get loginStepKey => 'SSH 키 확인';

  @override
  String get loginStepKeyFound => '이 키를 GitHub에 올립니다';

  @override
  String get loginStepKeyMissing =>
      '키가 없습니다. 터미널에서 아래 명령으로 만드세요 (암호 문구 권장). 앱은 키와 암호 문구를 받지 않습니다.';

  @override
  String get loginStepLogin => '로그인';

  @override
  String get loginStepLoginWhy => '브라우저에서 GitHub에 로그인하고 일회용 코드를 넣습니다.';

  @override
  String get loginLoggedIn => '로그인되어 있습니다';

  @override
  String get loginStart => '브라우저로 로그인';

  @override
  String get loginDeviceHowTo =>
      '브라우저가 열리지 않거나 원격 서버라면, 다른 기기의 브라우저에서 아래 주소를 열고 이 코드를 넣으세요.';

  @override
  String get loginStepUpload => '공개 키 올리기';

  @override
  String get loginStepUploadWhy =>
      '골라 둔 공개 키를 내 GitHub 계정에 등록합니다. 이미 등록돼 있으면 건너뜁니다.';

  @override
  String get loginUploadKey => '공개 키 올리기';

  @override
  String get loginNeedsKeyScope =>
      '키를 올릴 권한이 없습니다. 터미널에서 아래 명령으로 권한을 더한 뒤 다시 시도하세요.';

  @override
  String get loginStepTest => '연결 확인';

  @override
  String get loginStepTestWhy =>
      'GitHub에 SSH로 접속해 봅니다. 처음이면 github.com 호스트 키를 known_hosts에 더합니다.';

  @override
  String get loginSshFailed =>
      '연결하지 못했습니다. 키가 등록됐는지, ssh-agent에 키가 올라가 있는지 확인하세요.';

  @override
  String get loginTest => '연결 확인';

  @override
  String get loginChecking => '확인하는 중…';

  @override
  String get loginStepProtocol => 'git 프로토콜을 SSH로';

  @override
  String get loginStepProtocolWhy =>
      'gh가 앞으로 만드는 원격 주소를 SSH로 씁니다. 이미 있는 HTTPS 원격은 원격 탭의 URL 바꾸기에서 SSH로 바꿀 수 있습니다.';

  @override
  String get loginUseSshProtocol => 'SSH로 설정';

  @override
  String get loginAgentTip =>
      '암호 문구를 매번 묻지 않게 하려면 macOS는 ssh-add --apple-use-keychain, 그 밖에는 ssh-agent를 쓰세요.';

  @override
  String get doneProtocolSsh => 'gh의 git 프로토콜을 SSH로 바꿨습니다';

  @override
  String forkTitle(String parent) {
    return '$parent의 fork입니다';
  }

  @override
  String get forkAddWhy => '원본 저장소를 upstream 원격으로 추가하면 원본의 새 커밋을 가져올 수 있습니다.';

  @override
  String get forkSyncWhy => '원본(upstream)의 새 커밋을 가져와 현재 브랜치로 병합합니다.';

  @override
  String get forkAddUpstream => 'upstream 추가';

  @override
  String get forkSync => 'upstream에서 가져오기';

  @override
  String get remotesGhDefault => 'gh가 쓰는 저장소 (PR·릴리스·CI)';

  @override
  String get remotesGhDefaultNone => '정해지지 않음';

  @override
  String doneGhDefault(String repo) {
    return 'gh가 $repo을(를) 쓰도록 정했습니다';
  }

  @override
  String get releaseNeedsRemote => '원격이 없어 릴리스할 수 없습니다. 원격 탭에서 먼저 올리세요.';

  @override
  String get releaseDirectOnlyNotGitHub =>
      'GitHub 저장소가 아니라서 바로 커밋 방식(점검 → 버전 → 태그)으로 진행합니다. PR·릴리스 노트·CI는 호스팅 웹에서 하세요.';

  @override
  String get releaseDirectOnly => 'gh를 쓸 수 없어 바로 커밋 방식만 됩니다.';

  @override
  String get releaseDirectMode => '바로 커밋 방식';

  @override
  String releaseDirectModeWhy(String branch) {
    return 'PR 없이 $branch에 버전 올림을 커밋하고 커밋과 태그를 함께 push합니다. 혼자 쓰는 저장소에서만 쓰세요 — 보호된 브랜치면 push가 거부됩니다.';
  }

  @override
  String tagCheckSyncedDirect(String branch) {
    return '$branch에 있고 원격에 내게 없는 커밋이 없다';
  }

  @override
  String get versionUsesScript =>
      '저장소의 scripts/bump-version.sh로 버전을 올립니다 (lock 파일 포함, 규약과 같은 결과).';

  @override
  String versionLockFiles(String files) {
    return '함께 맞출 lock 파일: $files';
  }

  @override
  String get versionFileChoose => '버전 파일 바꾸기';

  @override
  String versionFileCustom(String path) {
    return '버전 파일: $path (직접 지정)';
  }

  @override
  String get versionFileTitle => '버전 파일 지정';

  @override
  String get versionFileWhy =>
      '자동으로 찾지 못하거나 다른 파일을 쓸 때 정합니다. 정규식의 첫 번째 괄호가 버전입니다. 이 저장소에만 적용됩니다.';

  @override
  String get versionFilePath => '파일 (저장소 기준 경로)';

  @override
  String get versionFilePattern => '버전 줄 정규식';

  @override
  String versionFileFound(String version) {
    return '찾았습니다: $version';
  }

  @override
  String get versionFileNotFound => '파일이 없거나 패턴에 맞는 버전이 없습니다';

  @override
  String get versionFileAuto => '자동 감지로 되돌리기';

  @override
  String get rollbackTitle => '릴리스 되돌리기';

  @override
  String rollbackConfirmTitle(String tag) {
    return '$tag 릴리스를 되돌릴까요?';
  }

  @override
  String rollbackMessage(String next) {
    return 'GitHub 릴리스, 원격 태그, 로컬 태그를 지웁니다. 이미 받아 간 사람이 있을 수 있으니 같은 번호를 다시 쓰지 말고 다음 번호($next)로 새로 릴리스하세요.';
  }

  @override
  String doneRollback(String tag) {
    return '$tag을(를) 되돌렸습니다';
  }

  @override
  String get diffBinary => '바이너리 파일이라 내용을 비교할 수 없습니다';

  @override
  String get diffEmpty => '차이가 없습니다';

  @override
  String diffTruncated(int count) {
    return '너무 길어 처음 $count줄만 보여 줍니다. 전체는 편집기에서 보세요.';
  }

  @override
  String headerCherryPicking(int count) {
    return 'cherry-pick 중 · 충돌 $count';
  }

  @override
  String headerReverting(int count) {
    return '되돌리는 중 · 충돌 $count';
  }

  @override
  String get operationAbortPickMessage =>
      '시작하기 전 상태로 되돌립니다. 충돌을 해결하던 내용은 사라집니다.';

  @override
  String get historyBranchLabel => '볼 브랜치';

  @override
  String historyOtherBranchHint(String head) {
    return '다른 브랜치의 기록입니다. 커밋 메뉴의 \'가져오기\'로 $head에 복사할 수 있습니다.';
  }

  @override
  String get historyViewChanges => '변경 내용 보기';

  @override
  String historyFilesChanged(int count) {
    return '바뀐 파일 $count개';
  }

  @override
  String get historyMergeNote => '병합 커밋 — 병합으로 들어온 변경';

  @override
  String get historyRevert => '이 커밋 되돌리기 (revert)';

  @override
  String historyRevertTitle(String hash) {
    return '$hash을(를) 되돌릴까요?';
  }

  @override
  String get historyRevertMessage =>
      '이 커밋의 변경을 거꾸로 적용한 새 커밋을 만듭니다. 기록을 지우지 않으므로 이미 올린 커밋에도 안전합니다.';

  @override
  String get historyRevertUnpushed =>
      '이 커밋의 변경을 거꾸로 적용한 새 커밋을 만듭니다. 아직 올리지 않은 커밋이라면 \'직전 커밋 고치기\'나 새 커밋으로 고쳐도 됩니다.';

  @override
  String get historyCherryPick => '가져오기';

  @override
  String historyCherryPickMenu(String head) {
    return '$head(으)로 가져오기 (cherry-pick)';
  }

  @override
  String historyCherryPickTitle(String hash, String head) {
    return '$hash을(를) $head(으)로 가져올까요?';
  }

  @override
  String get historyCherryPickMessage =>
      '이 커밋과 같은 변경을 현재 브랜치에 새 커밋으로 복사합니다. 브랜치 전체를 병합하지 않고 필요한 커밋 하나만 가져올 때 씁니다.';

  @override
  String doneRevert(String hash) {
    return '$hash을(를) 되돌리는 커밋을 만들었습니다';
  }

  @override
  String doneCherryPick(String hash) {
    return '$hash을(를) 가져왔습니다';
  }

  @override
  String get menuPalette => '명령 팔레트';

  @override
  String get paletteHint => '무엇을 할까요? (예: push, 브랜치, 태그)';

  @override
  String get paletteEmpty => '맞는 명령이 없습니다';

  @override
  String get paletteGroupActions => '동작';

  @override
  String get paletteGroupTabs => '탭';

  @override
  String get paletteGroupBranches => '브랜치';

  @override
  String get paletteGroupRepos => '저장소';

  @override
  String paletteGoToTab(String name) {
    return '$name 탭으로';
  }

  @override
  String paletteSwitchTo(String branch) {
    return '$branch(으)로 전환';
  }

  @override
  String get helpCaptionAfterRevert => 'C를 지우지 않고, C를 거꾸로 적용한 새 커밋 C⁻를 더함';

  @override
  String get helpCaptionAfterCherryPick =>
      'feature의 D와 같은 변경이 main에 새 커밋 D\'로 복사됨';

  @override
  String get helpRevertTitle => 'Revert (되돌리기)';

  @override
  String get helpRevertWord => 'revert는 \'원래 상태로 되돌리다\'.';

  @override
  String get helpRevertInGit =>
      '커밋을 지우지 않고, 그 커밋의 변경을 거꾸로 적용한 새 커밋을 만듭니다. 기록에는 원래 커밋과 되돌린 커밋이 모두 남습니다.';

  @override
  String get helpRevertWhy =>
      '이미 올린 커밋이 문제를 일으켰을 때 씁니다. 기록을 고치지 않아 다른 사람과 어긋나지 않고 강제 push도 필요 없습니다. 아직 올리지 않은 커밋은 amend로 고치는 편이 깔끔합니다.';

  @override
  String get helpCherryPickTitle => 'Cherry-pick (골라 가져오기)';

  @override
  String get helpCherryPickWord =>
      'cherry-pick은 \'체리를 하나씩 골라 따다\' — 좋은 것만 골라 가져오기.';

  @override
  String get helpCherryPickInGit =>
      '다른 브랜치의 커밋 하나와 같은 변경을 현재 브랜치에 새 커밋으로 복사합니다. 내용은 같지만 새 커밋(D\')이라 해시가 다릅니다.';

  @override
  String get helpCherryPickWhy =>
      '다른 브랜치의 버그 수정 하나만 급히 가져올 때 씁니다. 브랜치를 나중에 병합하면 같은 변경이 두 번 들어와 충돌할 수 있으니, 자주 쓰기보다 병합이 기본입니다.';

  @override
  String confirmTypeToContinue(String text) {
    return '되돌릴 수 없습니다. 계속하려면 $text을(를) 그대로 입력하세요.';
  }

  @override
  String tagsDeleteRemoteReleaseDraft(String tag) {
    return '⚠️ $tag에는 GitHub 릴리스가 있습니다. 태그를 지우면 GitHub가 그 릴리스를 초안(비공개)으로 바꿉니다 — 파일은 남지만 사람들이 볼 수 없게 됩니다. 릴리스까지 정리하려면 태그 메뉴의 \'릴리스 되돌리기\'를 쓰세요.';
  }

  @override
  String tagsPushCiTitle(int count) {
    return '태그 $count개를 push하면 릴리스가 새로 만들어집니다';
  }

  @override
  String tagsPushCiMessage(String workflow, String tags) {
    return '이 저장소는 태그를 push하면 $workflow이(가) 태그마다 빌드하고 GitHub 릴리스를 만듭니다: $tags. 일부러 지운 옛 릴리스라면 다시 생깁니다. 로컬에서만 지우려면 태그 메뉴의 \'삭제\'를 쓰세요.';
  }

  @override
  String get tagsPushAnyway => '그래도 push';
}
