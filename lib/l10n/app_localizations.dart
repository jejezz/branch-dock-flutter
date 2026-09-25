import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko'),
  ];

  /// No description provided for @aboutTooltip.
  ///
  /// In ko, this message translates to:
  /// **'정보'**
  String get aboutTooltip;

  /// No description provided for @aboutVersion.
  ///
  /// In ko, this message translates to:
  /// **'버전 {version} (빌드 {build})'**
  String aboutVersion(String version, String build);

  /// No description provided for @aboutOpenSourceLicenses.
  ///
  /// In ko, this message translates to:
  /// **'오픈소스 라이선스'**
  String get aboutOpenSourceLicenses;

  /// No description provided for @aboutRepository.
  ///
  /// In ko, this message translates to:
  /// **'GitHub'**
  String get aboutRepository;

  /// No description provided for @commonClose.
  ///
  /// In ko, this message translates to:
  /// **'닫기'**
  String get commonClose;

  /// No description provided for @aboutMenuItem.
  ///
  /// In ko, this message translates to:
  /// **'{appName} 정보'**
  String aboutMenuItem(String appName);

  /// No description provided for @themeMenuTooltip.
  ///
  /// In ko, this message translates to:
  /// **'테마'**
  String get themeMenuTooltip;

  /// No description provided for @themeSystem.
  ///
  /// In ko, this message translates to:
  /// **'시스템 설정 따르기'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In ko, this message translates to:
  /// **'라이트'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In ko, this message translates to:
  /// **'다크'**
  String get themeDark;

  /// No description provided for @languageMenuTooltip.
  ///
  /// In ko, this message translates to:
  /// **'언어'**
  String get languageMenuTooltip;

  /// No description provided for @languageSystem.
  ///
  /// In ko, this message translates to:
  /// **'시스템 설정 따르기 / System'**
  String get languageSystem;

  /// No description provided for @languageSystemShort.
  ///
  /// In ko, this message translates to:
  /// **'시스템'**
  String get languageSystemShort;

  /// No description provided for @aboutTagline.
  ///
  /// In ko, this message translates to:
  /// **'Git과 GitHub CLI를 위한 데스크톱 도우미'**
  String get aboutTagline;

  /// No description provided for @aboutDescription.
  ///
  /// In ko, this message translates to:
  /// **'편집기 옆에 세워 두고 브랜치, 태그, 병합, Pull/Push, 원격, 릴리스를 버튼으로 다룹니다. 버튼마다 실제로 실행되는 git·gh 명령을 보여 줍니다.'**
  String get aboutDescription;

  /// No description provided for @homeEmptyTitle.
  ///
  /// In ko, this message translates to:
  /// **'시작하려면 저장소를 선택하세요'**
  String get homeEmptyTitle;

  /// No description provided for @homeEmptyAction.
  ///
  /// In ko, this message translates to:
  /// **'저장소 열기'**
  String get homeEmptyAction;

  /// No description provided for @appBarRefresh.
  ///
  /// In ko, this message translates to:
  /// **'새로 고침'**
  String get appBarRefresh;

  /// No description provided for @appBarPin.
  ///
  /// In ko, this message translates to:
  /// **'항상 위에 표시'**
  String get appBarPin;

  /// No description provided for @appBarUnpin.
  ///
  /// In ko, this message translates to:
  /// **'항상 위에 표시 끄기'**
  String get appBarUnpin;

  /// No description provided for @menuOpenFolder.
  ///
  /// In ko, this message translates to:
  /// **'다른 폴더 열기…'**
  String get menuOpenFolder;

  /// No description provided for @menuEditor.
  ///
  /// In ko, this message translates to:
  /// **'파일을 열 편집기…'**
  String get menuEditor;

  /// No description provided for @menuEnvironment.
  ///
  /// In ko, this message translates to:
  /// **'환경 점검'**
  String get menuEnvironment;

  /// No description provided for @menuCloseRepo.
  ///
  /// In ko, this message translates to:
  /// **'저장소 닫기'**
  String get menuCloseRepo;

  /// No description provided for @hostOther.
  ///
  /// In ko, this message translates to:
  /// **'기타 git 서버'**
  String get hostOther;

  /// No description provided for @commonCancel.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get commonCancel;

  /// No description provided for @commonCopy.
  ///
  /// In ko, this message translates to:
  /// **'복사'**
  String get commonCopy;

  /// No description provided for @commonCopied.
  ///
  /// In ko, this message translates to:
  /// **'복사했습니다'**
  String get commonCopied;

  /// No description provided for @commonMore.
  ///
  /// In ko, this message translates to:
  /// **'더 보기'**
  String get commonMore;

  /// No description provided for @commonSave.
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get commonSave;

  /// No description provided for @commandPreviewLabel.
  ///
  /// In ko, this message translates to:
  /// **'실행될 명령'**
  String get commandPreviewLabel;

  /// No description provided for @startDropHint.
  ///
  /// In ko, this message translates to:
  /// **'git 저장소 폴더를 창에 끌어다 놓아도 됩니다.'**
  String get startDropHint;

  /// No description provided for @startRecent.
  ///
  /// In ko, this message translates to:
  /// **'최근 저장소'**
  String get startRecent;

  /// No description provided for @startRemoveRecent.
  ///
  /// In ko, this message translates to:
  /// **'목록에서 빼기'**
  String get startRemoveRecent;

  /// No description provided for @startNotARepository.
  ///
  /// In ko, this message translates to:
  /// **'이 폴더는 git 저장소가 아닙니다: {path}'**
  String startNotARepository(String path);

  /// No description provided for @startNotFound.
  ///
  /// In ko, this message translates to:
  /// **'폴더를 찾을 수 없습니다: {path}'**
  String startNotFound(String path);

  /// No description provided for @envTitle.
  ///
  /// In ko, this message translates to:
  /// **'환경 점검'**
  String get envTitle;

  /// No description provided for @envGitRequired.
  ///
  /// In ko, this message translates to:
  /// **'Branch Dock은 설치된 git을 실행합니다. git을 먼저 설치하세요.'**
  String get envGitRequired;

  /// No description provided for @envGitOnlyNote.
  ///
  /// In ko, this message translates to:
  /// **'gh가 없거나 로그인하지 않아도 브랜치·태그·Pull·Push는 쓸 수 있습니다. GitHub에 올리기, PR, 릴리스에는 gh 로그인이 필요합니다.'**
  String get envGitOnlyNote;

  /// No description provided for @envVersion.
  ///
  /// In ko, this message translates to:
  /// **'버전 {version}'**
  String envVersion(String version);

  /// No description provided for @envNotInstalled.
  ///
  /// In ko, this message translates to:
  /// **'설치되지 않았거나 찾을 수 없습니다'**
  String get envNotInstalled;

  /// No description provided for @envLogin.
  ///
  /// In ko, this message translates to:
  /// **'GitHub 로그인'**
  String get envLogin;

  /// No description provided for @envLoggedInAs.
  ///
  /// In ko, this message translates to:
  /// **'{login} 계정으로 로그인됨'**
  String envLoggedInAs(String login);

  /// No description provided for @envNotLoggedIn.
  ///
  /// In ko, this message translates to:
  /// **'로그인하지 않았습니다. 터미널에서 아래 명령을 실행하세요.'**
  String get envNotLoggedIn;

  /// No description provided for @envRecheck.
  ///
  /// In ko, this message translates to:
  /// **'다시 확인'**
  String get envRecheck;

  /// No description provided for @envGhMissing.
  ///
  /// In ko, this message translates to:
  /// **'GitHub CLI(gh)가 설치되지 않아 쓸 수 없습니다. 메뉴의 환경 점검을 확인하세요.'**
  String get envGhMissing;

  /// No description provided for @envGhLoggedOut.
  ///
  /// In ko, this message translates to:
  /// **'gh에 로그인해야 쓸 수 있습니다. 터미널에서 gh auth login을 실행하세요.'**
  String get envGhLoggedOut;

  /// No description provided for @headerBranchTooltip.
  ///
  /// In ko, this message translates to:
  /// **'브랜치 목록 보기'**
  String get headerBranchTooltip;

  /// No description provided for @headerDetached.
  ///
  /// In ko, this message translates to:
  /// **'분리된 HEAD'**
  String get headerDetached;

  /// No description provided for @headerNoUpstream.
  ///
  /// In ko, this message translates to:
  /// **'원격에 없음'**
  String get headerNoUpstream;

  /// No description provided for @headerNoUpstreamTooltip.
  ///
  /// In ko, this message translates to:
  /// **'이 브랜치는 아직 원격에 올라가지 않았습니다. 게시(Publish)하면 올라갑니다.'**
  String get headerNoUpstreamTooltip;

  /// No description provided for @headerAheadTooltip.
  ///
  /// In ko, this message translates to:
  /// **'원격에 아직 없는 내 커밋 {count}개'**
  String headerAheadTooltip(int count);

  /// No description provided for @headerBehindTooltip.
  ///
  /// In ko, this message translates to:
  /// **'내 컴퓨터에 아직 없는 원격 커밋 {count}개'**
  String headerBehindTooltip(int count);

  /// No description provided for @headerChanges.
  ///
  /// In ko, this message translates to:
  /// **'변경 {count}'**
  String headerChanges(int count);

  /// No description provided for @headerUpToDate.
  ///
  /// In ko, this message translates to:
  /// **'최신'**
  String get headerUpToDate;

  /// No description provided for @headerNoCommits.
  ///
  /// In ko, this message translates to:
  /// **'아직 커밋 없음'**
  String get headerNoCommits;

  /// No description provided for @headerMerging.
  ///
  /// In ko, this message translates to:
  /// **'병합 중 · 충돌 {count}'**
  String headerMerging(int count);

  /// No description provided for @headerRebasing.
  ///
  /// In ko, this message translates to:
  /// **'rebase 중 · 충돌 {count}'**
  String headerRebasing(int count);

  /// No description provided for @headerFetch.
  ///
  /// In ko, this message translates to:
  /// **'Fetch'**
  String get headerFetch;

  /// No description provided for @headerPull.
  ///
  /// In ko, this message translates to:
  /// **'Pull'**
  String get headerPull;

  /// No description provided for @headerPush.
  ///
  /// In ko, this message translates to:
  /// **'Push'**
  String get headerPush;

  /// No description provided for @headerPublish.
  ///
  /// In ko, this message translates to:
  /// **'게시'**
  String get headerPublish;

  /// No description provided for @pullModeTooltip.
  ///
  /// In ko, this message translates to:
  /// **'Pull 방식'**
  String get pullModeTooltip;

  /// No description provided for @pullModeTitle.
  ///
  /// In ko, this message translates to:
  /// **'Pull 방식'**
  String get pullModeTitle;

  /// No description provided for @pullModeMerge.
  ///
  /// In ko, this message translates to:
  /// **'병합 (기본)'**
  String get pullModeMerge;

  /// No description provided for @pullModeMergeWhen.
  ///
  /// In ko, this message translates to:
  /// **'양쪽에 새 커밋이 있으면 병합 커밋으로 합칩니다. 가장 안전합니다.'**
  String get pullModeMergeWhen;

  /// No description provided for @pullModeRebase.
  ///
  /// In ko, this message translates to:
  /// **'Rebase'**
  String get pullModeRebase;

  /// No description provided for @pullModeRebaseWhen.
  ///
  /// In ko, this message translates to:
  /// **'내 커밋을 받아온 커밋 뒤로 옮겨 기록을 한 줄로 유지합니다.'**
  String get pullModeRebaseWhen;

  /// No description provided for @pullModeFastForward.
  ///
  /// In ko, this message translates to:
  /// **'Fast-forward만'**
  String get pullModeFastForward;

  /// No description provided for @pullModeFastForwardWhen.
  ///
  /// In ko, this message translates to:
  /// **'내 커밋이 없을 때만 받아옵니다. 갈라졌으면 멈추고 알려 줍니다.'**
  String get pullModeFastForwardWhen;

  /// No description provided for @operationAbort.
  ///
  /// In ko, this message translates to:
  /// **'중단'**
  String get operationAbort;

  /// No description provided for @operationContinue.
  ///
  /// In ko, this message translates to:
  /// **'계속'**
  String get operationContinue;

  /// No description provided for @operationContinueBlocked.
  ///
  /// In ko, this message translates to:
  /// **'충돌을 모두 해결해야 계속할 수 있습니다'**
  String get operationContinueBlocked;

  /// No description provided for @operationAbortTitle.
  ///
  /// In ko, this message translates to:
  /// **'진행 중인 작업을 중단할까요?'**
  String get operationAbortTitle;

  /// No description provided for @operationAbortMergeMessage.
  ///
  /// In ko, this message translates to:
  /// **'병합을 시작하기 전 상태로 되돌립니다. 충돌을 해결하던 내용은 사라집니다.'**
  String get operationAbortMergeMessage;

  /// No description provided for @operationAbortRebaseMessage.
  ///
  /// In ko, this message translates to:
  /// **'rebase를 시작하기 전 상태로 되돌립니다. 충돌을 해결하던 내용은 사라집니다.'**
  String get operationAbortRebaseMessage;

  /// No description provided for @bannerConflicts.
  ///
  /// In ko, this message translates to:
  /// **'충돌 파일 {count}개를 해결해야 합니다'**
  String bannerConflicts(int count);

  /// No description provided for @bannerPull.
  ///
  /// In ko, this message translates to:
  /// **'원격에 새 커밋 {count}개가 있습니다'**
  String bannerPull(int count);

  /// No description provided for @bannerPublish.
  ///
  /// In ko, this message translates to:
  /// **'이 브랜치는 아직 원격에 없습니다'**
  String get bannerPublish;

  /// No description provided for @bannerPush.
  ///
  /// In ko, this message translates to:
  /// **'커밋 {count}개가 아직 원격에 없습니다'**
  String bannerPush(int count);

  /// No description provided for @bannerNoRemote.
  ///
  /// In ko, this message translates to:
  /// **'이 저장소는 아직 GitHub에 없습니다'**
  String get bannerNoRemote;

  /// No description provided for @bannerShow.
  ///
  /// In ko, this message translates to:
  /// **'보기'**
  String get bannerShow;

  /// No description provided for @bannerNotGitHub.
  ///
  /// In ko, this message translates to:
  /// **'{host} 저장소입니다. 브랜치·Pull·Push는 모두 쓸 수 있고, PR·릴리스·Actions는 GitHub 저장소에서만 쓸 수 있습니다.'**
  String bannerNotGitHub(String host);

  /// No description provided for @tabChanges.
  ///
  /// In ko, this message translates to:
  /// **'변경'**
  String get tabChanges;

  /// No description provided for @tabBranches.
  ///
  /// In ko, this message translates to:
  /// **'브랜치'**
  String get tabBranches;

  /// No description provided for @tabRemotes.
  ///
  /// In ko, this message translates to:
  /// **'원격'**
  String get tabRemotes;

  /// No description provided for @changesMessageHint.
  ///
  /// In ko, this message translates to:
  /// **'커밋 메시지'**
  String get changesMessageHint;

  /// No description provided for @changesPrefixTooltip.
  ///
  /// In ko, this message translates to:
  /// **'커밋 종류 접두어'**
  String get changesPrefixTooltip;

  /// No description provided for @changesFirstLineLong.
  ///
  /// In ko, this message translates to:
  /// **'첫 줄이 {length}자입니다. 72자 안으로 줄이면 목록에서 잘리지 않습니다.'**
  String changesFirstLineLong(int length);

  /// No description provided for @changesCommitStaged.
  ///
  /// In ko, this message translates to:
  /// **'커밋 (스테이징 {count})'**
  String changesCommitStaged(int count);

  /// No description provided for @changesCommitAll.
  ///
  /// In ko, this message translates to:
  /// **'모두 스테이징하고 커밋'**
  String get changesCommitAll;

  /// No description provided for @changesConflicts.
  ///
  /// In ko, this message translates to:
  /// **'충돌'**
  String get changesConflicts;

  /// No description provided for @changesStaged.
  ///
  /// In ko, this message translates to:
  /// **'스테이징됨'**
  String get changesStaged;

  /// No description provided for @changesUnstaged.
  ///
  /// In ko, this message translates to:
  /// **'변경됨'**
  String get changesUnstaged;

  /// No description provided for @changesUntracked.
  ///
  /// In ko, this message translates to:
  /// **'추적 안 됨'**
  String get changesUntracked;

  /// No description provided for @changesStageAll.
  ///
  /// In ko, this message translates to:
  /// **'모두 스테이징'**
  String get changesStageAll;

  /// No description provided for @changesUnstageAll.
  ///
  /// In ko, this message translates to:
  /// **'모두 해제'**
  String get changesUnstageAll;

  /// No description provided for @changesStage.
  ///
  /// In ko, this message translates to:
  /// **'스테이징'**
  String get changesStage;

  /// No description provided for @changesUnstage.
  ///
  /// In ko, this message translates to:
  /// **'스테이징 해제'**
  String get changesUnstage;

  /// No description provided for @changesOpenInEditor.
  ///
  /// In ko, this message translates to:
  /// **'편집기로 열기'**
  String get changesOpenInEditor;

  /// No description provided for @changesMarkResolved.
  ///
  /// In ko, this message translates to:
  /// **'해결됨'**
  String get changesMarkResolved;

  /// No description provided for @changesCleanTitle.
  ///
  /// In ko, this message translates to:
  /// **'커밋할 변경이 없습니다'**
  String get changesCleanTitle;

  /// No description provided for @changesCleanMessage.
  ///
  /// In ko, this message translates to:
  /// **'편집기에서 파일을 저장하면 여기에 바로 나타납니다.'**
  String get changesCleanMessage;

  /// No description provided for @branchesTitle.
  ///
  /// In ko, this message translates to:
  /// **'브랜치'**
  String get branchesTitle;

  /// No description provided for @branchesNew.
  ///
  /// In ko, this message translates to:
  /// **'새 브랜치'**
  String get branchesNew;

  /// No description provided for @branchesCreate.
  ///
  /// In ko, this message translates to:
  /// **'만들기'**
  String get branchesCreate;

  /// No description provided for @branchesSearchHint.
  ///
  /// In ko, this message translates to:
  /// **'브랜치 찾기'**
  String get branchesSearchHint;

  /// No description provided for @branchesLocal.
  ///
  /// In ko, this message translates to:
  /// **'로컬'**
  String get branchesLocal;

  /// No description provided for @branchesRemote.
  ///
  /// In ko, this message translates to:
  /// **'원격'**
  String get branchesRemote;

  /// No description provided for @branchesSwitch.
  ///
  /// In ko, this message translates to:
  /// **'전환'**
  String get branchesSwitch;

  /// No description provided for @branchesRename.
  ///
  /// In ko, this message translates to:
  /// **'이름 바꾸기'**
  String get branchesRename;

  /// No description provided for @branchesDelete.
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get branchesDelete;

  /// No description provided for @branchesDeleteRemote.
  ///
  /// In ko, this message translates to:
  /// **'원격에서 삭제'**
  String get branchesDeleteRemote;

  /// No description provided for @branchesUpstreamGone.
  ///
  /// In ko, this message translates to:
  /// **'원격 삭제됨'**
  String get branchesUpstreamGone;

  /// No description provided for @branchesUnbornTitle.
  ///
  /// In ko, this message translates to:
  /// **'아직 커밋이 없습니다'**
  String get branchesUnbornTitle;

  /// No description provided for @branchesUnbornMessage.
  ///
  /// In ko, this message translates to:
  /// **'첫 커밋을 만들면 브랜치를 만들 수 있습니다.'**
  String get branchesUnbornMessage;

  /// No description provided for @branchesForceDeleteTitle.
  ///
  /// In ko, this message translates to:
  /// **'병합되지 않은 브랜치입니다'**
  String get branchesForceDeleteTitle;

  /// No description provided for @branchesForceDeleteMessage.
  ///
  /// In ko, this message translates to:
  /// **'{name}에는 다른 브랜치에 병합되지 않은 커밋이 있습니다. 삭제하면 그 커밋을 찾기 어려워집니다.'**
  String branchesForceDeleteMessage(String name);

  /// No description provided for @branchesDeleteRemoteTitle.
  ///
  /// In ko, this message translates to:
  /// **'원격 브랜치를 삭제할까요?'**
  String get branchesDeleteRemoteTitle;

  /// No description provided for @branchesDeleteRemoteMessage.
  ///
  /// In ko, this message translates to:
  /// **'{target}에서 {branch} 브랜치를 삭제합니다. 다른 사람도 더 이상 이 브랜치를 받을 수 없습니다.'**
  String branchesDeleteRemoteMessage(String branch, String target);

  /// No description provided for @branchNameLabel.
  ///
  /// In ko, this message translates to:
  /// **'브랜치 이름'**
  String get branchNameLabel;

  /// No description provided for @branchNameExists.
  ///
  /// In ko, this message translates to:
  /// **'같은 이름의 브랜치가 이미 있습니다'**
  String get branchNameExists;

  /// No description provided for @branchNameEmpty.
  ///
  /// In ko, this message translates to:
  /// **'이름을 입력하세요'**
  String get branchNameEmpty;

  /// No description provided for @branchNameInvalidCharacter.
  ///
  /// In ko, this message translates to:
  /// **'공백과 ~ ^ : ? * [ \\ 는 쓸 수 없습니다'**
  String get branchNameInvalidCharacter;

  /// No description provided for @branchNameStartsWithDash.
  ///
  /// In ko, this message translates to:
  /// **'-로 시작할 수 없습니다'**
  String get branchNameStartsWithDash;

  /// No description provided for @branchNameInvalidSequence.
  ///
  /// In ko, this message translates to:
  /// **'.. 이나 //, .으로 시작하는 부분, .lock으로 끝나는 부분은 쓸 수 없습니다'**
  String get branchNameInvalidSequence;

  /// No description provided for @branchNameInvalidEdge.
  ///
  /// In ko, this message translates to:
  /// **'/ 로 시작하거나 / 또는 . 으로 끝날 수 없습니다'**
  String get branchNameInvalidEdge;

  /// No description provided for @branchBaseLabel.
  ///
  /// In ko, this message translates to:
  /// **'어디서 시작할까요'**
  String get branchBaseLabel;

  /// No description provided for @branchBaseCurrent.
  ///
  /// In ko, this message translates to:
  /// **'현재 브랜치 ({name})'**
  String branchBaseCurrent(String name);

  /// No description provided for @branchSwitchAfter.
  ///
  /// In ko, this message translates to:
  /// **'만든 뒤 바로 전환'**
  String get branchSwitchAfter;

  /// No description provided for @branchRenameUpstreamNote.
  ///
  /// In ko, this message translates to:
  /// **'원격의 {upstream}은 그대로 남습니다. 새 이름으로 다시 게시하세요.'**
  String branchRenameUpstreamNote(String upstream);

  /// No description provided for @remotesTitle.
  ///
  /// In ko, this message translates to:
  /// **'원격'**
  String get remotesTitle;

  /// No description provided for @remotesAdd.
  ///
  /// In ko, this message translates to:
  /// **'원격 추가'**
  String get remotesAdd;

  /// No description provided for @remotesRename.
  ///
  /// In ko, this message translates to:
  /// **'이름 바꾸기'**
  String get remotesRename;

  /// No description provided for @remotesSetUrl.
  ///
  /// In ko, this message translates to:
  /// **'URL 바꾸기'**
  String get remotesSetUrl;

  /// No description provided for @remotesRemove.
  ///
  /// In ko, this message translates to:
  /// **'원격 삭제'**
  String get remotesRemove;

  /// No description provided for @remotesRemoveTitle.
  ///
  /// In ko, this message translates to:
  /// **'원격을 삭제할까요?'**
  String get remotesRemoveTitle;

  /// No description provided for @remotesRemoveMessage.
  ///
  /// In ko, this message translates to:
  /// **'이 저장소에서 {name} 연결만 지웁니다. 서버의 저장소는 그대로 남습니다.'**
  String remotesRemoveMessage(String name);

  /// No description provided for @remotesEmptyTitle.
  ///
  /// In ko, this message translates to:
  /// **'이 저장소는 아직 GitHub에 없습니다'**
  String get remotesEmptyTitle;

  /// No description provided for @remotesEmptyMessage.
  ///
  /// In ko, this message translates to:
  /// **'GitHub에 새 저장소를 만들고 지금 브랜치를 올립니다.'**
  String get remotesEmptyMessage;

  /// No description provided for @remotesPublishToGitHub.
  ///
  /// In ko, this message translates to:
  /// **'GitHub에 올리기'**
  String get remotesPublishToGitHub;

  /// No description provided for @remotesPublishAlsoToGitHub.
  ///
  /// In ko, this message translates to:
  /// **'GitHub에도 올리기 (원격 추가)'**
  String get remotesPublishAlsoToGitHub;

  /// No description provided for @remotesPublishConfirm.
  ///
  /// In ko, this message translates to:
  /// **'만들고 올리기'**
  String get remotesPublishConfirm;

  /// No description provided for @remotesNotGitHubNote.
  ///
  /// In ko, this message translates to:
  /// **'GitHub 저장소가 아니라서 PR·릴리스·Actions는 쓸 수 없습니다 (gh는 GitHub 전용).'**
  String get remotesNotGitHubNote;

  /// No description provided for @remotesNameLabel.
  ///
  /// In ko, this message translates to:
  /// **'원격 이름'**
  String get remotesNameLabel;

  /// No description provided for @remotesNameTaken.
  ///
  /// In ko, this message translates to:
  /// **'같은 이름의 원격이 이미 있습니다'**
  String get remotesNameTaken;

  /// No description provided for @remotesNameInvalid.
  ///
  /// In ko, this message translates to:
  /// **'공백과 특수 문자는 쓸 수 없습니다'**
  String get remotesNameInvalid;

  /// No description provided for @remotesUrlLabel.
  ///
  /// In ko, this message translates to:
  /// **'URL'**
  String get remotesUrlLabel;

  /// No description provided for @remotesUseHttps.
  ///
  /// In ko, this message translates to:
  /// **'HTTPS 주소로 바꾸기'**
  String get remotesUseHttps;

  /// No description provided for @remotesUseSsh.
  ///
  /// In ko, this message translates to:
  /// **'SSH 주소로 바꾸기'**
  String get remotesUseSsh;

  /// No description provided for @publishNameLabel.
  ///
  /// In ko, this message translates to:
  /// **'저장소 이름'**
  String get publishNameLabel;

  /// No description provided for @publishNameHelper.
  ///
  /// In ko, this message translates to:
  /// **'조직에 만들려면 조직/이름'**
  String get publishNameHelper;

  /// No description provided for @publishNameInvalid.
  ///
  /// In ko, this message translates to:
  /// **'영문, 숫자, - _ . 만 쓸 수 있습니다'**
  String get publishNameInvalid;

  /// No description provided for @publishDescriptionLabel.
  ///
  /// In ko, this message translates to:
  /// **'설명 (선택)'**
  String get publishDescriptionLabel;

  /// No description provided for @publishPrivate.
  ///
  /// In ko, this message translates to:
  /// **'비공개'**
  String get publishPrivate;

  /// No description provided for @publishPublic.
  ///
  /// In ko, this message translates to:
  /// **'공개'**
  String get publishPublic;

  /// No description provided for @publishNoCommitsNote.
  ///
  /// In ko, this message translates to:
  /// **'아직 커밋이 없어서 저장소만 만듭니다. 첫 커밋 뒤에 Push하세요.'**
  String get publishNoCommitsNote;

  /// No description provided for @editorTitle.
  ///
  /// In ko, this message translates to:
  /// **'파일을 열 편집기'**
  String get editorTitle;

  /// No description provided for @editorMessage.
  ///
  /// In ko, this message translates to:
  /// **'편집기 명령을 적으면 파일을 그 편집기로 엽니다. 비워 두면 OS 기본 앱으로 엽니다.'**
  String get editorMessage;

  /// No description provided for @editorLabel.
  ///
  /// In ko, this message translates to:
  /// **'편집기 명령'**
  String get editorLabel;

  /// No description provided for @logTitle.
  ///
  /// In ko, this message translates to:
  /// **'명령 기록'**
  String get logTitle;

  /// No description provided for @logClear.
  ///
  /// In ko, this message translates to:
  /// **'지우기'**
  String get logClear;

  /// No description provided for @logEmpty.
  ///
  /// In ko, this message translates to:
  /// **'아직 실행한 명령이 없습니다'**
  String get logEmpty;

  /// No description provided for @logToggleTooltip.
  ///
  /// In ko, this message translates to:
  /// **'명령 기록 펼치기/접기'**
  String get logToggleTooltip;

  /// No description provided for @doneFetch.
  ///
  /// In ko, this message translates to:
  /// **'원격 정보를 가져왔습니다'**
  String get doneFetch;

  /// No description provided for @donePull.
  ///
  /// In ko, this message translates to:
  /// **'Pull을 마쳤습니다'**
  String get donePull;

  /// No description provided for @donePush.
  ///
  /// In ko, this message translates to:
  /// **'Push를 마쳤습니다'**
  String get donePush;

  /// No description provided for @donePublish.
  ///
  /// In ko, this message translates to:
  /// **'{branch} 브랜치를 게시했습니다'**
  String donePublish(String branch);

  /// No description provided for @doneCommit.
  ///
  /// In ko, this message translates to:
  /// **'커밋했습니다'**
  String get doneCommit;

  /// No description provided for @doneSwitch.
  ///
  /// In ko, this message translates to:
  /// **'{name}(으)로 전환했습니다'**
  String doneSwitch(String name);

  /// No description provided for @doneCreateBranch.
  ///
  /// In ko, this message translates to:
  /// **'{name} 브랜치를 만들었습니다'**
  String doneCreateBranch(String name);

  /// No description provided for @doneRenameBranch.
  ///
  /// In ko, this message translates to:
  /// **'이름을 {name}(으)로 바꿨습니다'**
  String doneRenameBranch(String name);

  /// No description provided for @doneDeleteBranch.
  ///
  /// In ko, this message translates to:
  /// **'{name} 브랜치를 삭제했습니다'**
  String doneDeleteBranch(String name);

  /// No description provided for @doneAddRemote.
  ///
  /// In ko, this message translates to:
  /// **'{name} 원격을 추가했습니다'**
  String doneAddRemote(String name);

  /// No description provided for @doneRenameRemote.
  ///
  /// In ko, this message translates to:
  /// **'원격 이름을 {name}(으)로 바꿨습니다'**
  String doneRenameRemote(String name);

  /// No description provided for @doneSetRemoteUrl.
  ///
  /// In ko, this message translates to:
  /// **'{name}의 URL을 바꿨습니다'**
  String doneSetRemoteUrl(String name);

  /// No description provided for @doneRemoveRemote.
  ///
  /// In ko, this message translates to:
  /// **'{name} 원격을 삭제했습니다'**
  String doneRemoveRemote(String name);

  /// No description provided for @donePublishToGitHub.
  ///
  /// In ko, this message translates to:
  /// **'GitHub에 {name} 저장소를 만들었습니다'**
  String donePublishToGitHub(String name);

  /// No description provided for @doneAbort.
  ///
  /// In ko, this message translates to:
  /// **'중단했습니다'**
  String get doneAbort;

  /// No description provided for @doneContinue.
  ///
  /// In ko, this message translates to:
  /// **'계속 진행했습니다'**
  String get doneContinue;

  /// No description provided for @errorGeneric.
  ///
  /// In ko, this message translates to:
  /// **'명령이 실패했습니다. 아래 원문을 확인하세요.'**
  String get errorGeneric;

  /// No description provided for @errorPushRejected.
  ///
  /// In ko, this message translates to:
  /// **'Push가 거부됐습니다. 원격에 내게 없는 커밋이 있어서입니다. 먼저 Pull 하세요.'**
  String get errorPushRejected;

  /// No description provided for @errorAuthFailed.
  ///
  /// In ko, this message translates to:
  /// **'인증에 실패했습니다. gh auth login으로 로그인했는지, SSH 키가 등록됐는지 확인하세요.'**
  String get errorAuthFailed;

  /// No description provided for @errorConflict.
  ///
  /// In ko, this message translates to:
  /// **'충돌이 났습니다. 변경 탭에서 충돌 파일을 편집기로 열어 고친 뒤 해결됨을 누르세요.'**
  String get errorConflict;

  /// No description provided for @errorLocalChanges.
  ///
  /// In ko, this message translates to:
  /// **'커밋하지 않은 변경이 덮어써질 수 있어서 멈췄습니다. 먼저 커밋하세요.'**
  String get errorLocalChanges;

  /// No description provided for @errorNotFastForward.
  ///
  /// In ko, this message translates to:
  /// **'기록이 갈라져서 fast-forward로 받을 수 없습니다. Pull 방식을 병합이나 rebase로 바꾸세요.'**
  String get errorNotFastForward;

  /// No description provided for @errorProtectedBranch.
  ///
  /// In ko, this message translates to:
  /// **'보호된 브랜치라서 직접 Push할 수 없습니다. 새 브랜치로 올리고 PR을 만드세요.'**
  String get errorProtectedBranch;

  /// No description provided for @errorBranchNotMerged.
  ///
  /// In ko, this message translates to:
  /// **'병합되지 않은 커밋이 있는 브랜치입니다.'**
  String get errorBranchNotMerged;

  /// No description provided for @errorNoUpstream.
  ///
  /// In ko, this message translates to:
  /// **'추적 브랜치가 없습니다. 먼저 게시(Publish)하세요.'**
  String get errorNoUpstream;

  /// No description provided for @errorAlreadyExists.
  ///
  /// In ko, this message translates to:
  /// **'같은 이름이 이미 있습니다.'**
  String get errorAlreadyExists;

  /// No description provided for @errorRepositoryNotFound.
  ///
  /// In ko, this message translates to:
  /// **'원격 저장소를 찾을 수 없습니다. URL과 접근 권한을 확인하세요.'**
  String get errorRepositoryNotFound;

  /// No description provided for @errorNetwork.
  ///
  /// In ko, this message translates to:
  /// **'서버에 연결할 수 없습니다. 네트워크를 확인하세요.'**
  String get errorNetwork;

  /// No description provided for @errorNotInstalled.
  ///
  /// In ko, this message translates to:
  /// **'프로그램을 찾을 수 없습니다. 메뉴의 환경 점검을 확인하세요.'**
  String get errorNotInstalled;

  /// No description provided for @timeJustNow.
  ///
  /// In ko, this message translates to:
  /// **'방금'**
  String get timeJustNow;

  /// No description provided for @timeMinutesAgo.
  ///
  /// In ko, this message translates to:
  /// **'{n}분 전'**
  String timeMinutesAgo(int n);

  /// No description provided for @timeHoursAgo.
  ///
  /// In ko, this message translates to:
  /// **'{n}시간 전'**
  String timeHoursAgo(int n);

  /// No description provided for @timeDaysAgo.
  ///
  /// In ko, this message translates to:
  /// **'{n}일 전'**
  String timeDaysAgo(int n);

  /// No description provided for @helpTooltip.
  ///
  /// In ko, this message translates to:
  /// **'이게 뭔가요?'**
  String get helpTooltip;

  /// No description provided for @helpSectionWord.
  ///
  /// In ko, this message translates to:
  /// **'낱말 뜻'**
  String get helpSectionWord;

  /// No description provided for @helpSectionInGit.
  ///
  /// In ko, this message translates to:
  /// **'git에서는'**
  String get helpSectionInGit;

  /// No description provided for @helpSectionWhy.
  ///
  /// In ko, this message translates to:
  /// **'왜 · 언제 쓰나'**
  String get helpSectionWhy;

  /// No description provided for @helpSectionLinks.
  ///
  /// In ko, this message translates to:
  /// **'더 알아보기'**
  String get helpSectionLinks;

  /// No description provided for @helpCaptionBefore.
  ///
  /// In ko, this message translates to:
  /// **'전'**
  String get helpCaptionBefore;

  /// No description provided for @helpCaptionAfter.
  ///
  /// In ko, this message translates to:
  /// **'후'**
  String get helpCaptionAfter;

  /// No description provided for @helpCaptionAfterFetch.
  ///
  /// In ko, this message translates to:
  /// **'Fetch 후 — 내 main은 그대로'**
  String get helpCaptionAfterFetch;

  /// No description provided for @helpCaptionAfterPull.
  ///
  /// In ko, this message translates to:
  /// **'Pull 후 — 내 main도 따라감'**
  String get helpCaptionAfterPull;

  /// No description provided for @helpCaptionAheadOne.
  ///
  /// In ko, this message translates to:
  /// **'feature가 origin/feature보다 커밋 하나 앞섬 (↑1)'**
  String get helpCaptionAheadOne;

  /// No description provided for @helpLinkBranchingBasics.
  ///
  /// In ko, this message translates to:
  /// **'Pro Git — 브랜치와 Merge의 기초'**
  String get helpLinkBranchingBasics;

  /// No description provided for @helpLinkRemoteBranches.
  ///
  /// In ko, this message translates to:
  /// **'Pro Git — 리모트 브랜치'**
  String get helpLinkRemoteBranches;

  /// No description provided for @helpLinkRebasing.
  ///
  /// In ko, this message translates to:
  /// **'Pro Git — Rebase 하기'**
  String get helpLinkRebasing;

  /// No description provided for @helpFetchVsPullTitle.
  ///
  /// In ko, this message translates to:
  /// **'Fetch와 Pull'**
  String get helpFetchVsPullTitle;

  /// No description provided for @helpFetchVsPullWord.
  ///
  /// In ko, this message translates to:
  /// **'fetch는 \'가서 가져오다\', pull은 \'끌어당기다\'.'**
  String get helpFetchVsPullWord;

  /// No description provided for @helpFetchVsPullInGit.
  ///
  /// In ko, this message translates to:
  /// **'Fetch는 원격(GitHub)에 새로 생긴 커밋을 내 컴퓨터로 가져와 origin/main 같은 \'원격 이름표\'만 옮깁니다. 내 브랜치와 파일은 건드리지 않습니다. Pull은 Fetch를 한 뒤, 가져온 커밋을 내 브랜치에 합칩니다.'**
  String get helpFetchVsPullInGit;

  /// No description provided for @helpFetchVsPullWhy.
  ///
  /// In ko, this message translates to:
  /// **'무엇이 바뀌었는지 먼저 보고 싶으면 Fetch — 안전하고 언제 해도 됩니다. 바로 최신으로 맞추려면 Pull. 커밋하지 않은 변경이 있으면 Pull이 멈출 수 있으니 먼저 커밋하세요.'**
  String get helpFetchVsPullWhy;

  /// No description provided for @helpUpstreamTitle.
  ///
  /// In ko, this message translates to:
  /// **'추적 브랜치 (upstream)와 origin'**
  String get helpUpstreamTitle;

  /// No description provided for @helpUpstreamWord.
  ///
  /// In ko, this message translates to:
  /// **'upstream은 \'상류\'. 물이 흘러오는 쪽입니다. origin은 \'출처, 기원\'.'**
  String get helpUpstreamWord;

  /// No description provided for @helpUpstreamInGit.
  ///
  /// In ko, this message translates to:
  /// **'origin은 저장소를 받아 온 원격(대개 GitHub)에 붙는 기본 이름입니다. 내 브랜치가 짝지어 둔 원격 브랜치(예: origin/feature)를 추적 브랜치, 곧 upstream이라고 합니다. ↑↓ 숫자는 이 짝과 비교한 것입니다.'**
  String get helpUpstreamInGit;

  /// No description provided for @helpUpstreamWhy.
  ///
  /// In ko, this message translates to:
  /// **'짝이 있어야 그냥 Push, Pull만 눌러도 어디로 보내고 어디서 받을지 압니다. 새 브랜치에는 짝이 없어서 처음 한 번은 \'게시\'(git push -u)로 짝을 지어 줍니다.'**
  String get helpUpstreamWhy;

  /// No description provided for @helpFastForwardTitle.
  ///
  /// In ko, this message translates to:
  /// **'Fast-forward (빨리 감기)'**
  String get helpFastForwardTitle;

  /// No description provided for @helpFastForwardWord.
  ///
  /// In ko, this message translates to:
  /// **'테이프나 영상을 앞으로 빨리 감는 것.'**
  String get helpFastForwardWord;

  /// No description provided for @helpFastForwardInGit.
  ///
  /// In ko, this message translates to:
  /// **'내 브랜치가 갈라진 적 없이 뒤처져 있기만 할 때, 새 커밋을 만들지 않고 브랜치 이름표를 최신 커밋 위치로 앞으로 옮기기만 합니다. 이미 있는 커밋을 따라 \'앞으로 감기\'만 하므로 이렇게 부릅니다.'**
  String get helpFastForwardInGit;

  /// No description provided for @helpFastForwardWhy.
  ///
  /// In ko, this message translates to:
  /// **'기록이 한 줄로 깔끔하고 합칠 것이 없으니 충돌도 없습니다. 양쪽에 서로 다른 새 커밋이 있으면(갈라졌으면) 빨리 감을 수 없어서, \'Fast-forward만\'은 멈추고 병합이나 rebase가 필요합니다. Push가 non-fast-forward로 거부되는 것도 같은 이유입니다.'**
  String get helpFastForwardWhy;

  /// No description provided for @helpMergeCommitTitle.
  ///
  /// In ko, this message translates to:
  /// **'병합 커밋 (merge commit)'**
  String get helpMergeCommitTitle;

  /// No description provided for @helpMergeCommitWord.
  ///
  /// In ko, this message translates to:
  /// **'merge는 \'합치다\', 두 길이 하나로 합류하는 것.'**
  String get helpMergeCommitWord;

  /// No description provided for @helpMergeCommitInGit.
  ///
  /// In ko, this message translates to:
  /// **'갈라진 두 기록을 그대로 두고, 둘을 부모로 가진 새 커밋(병합 커밋)을 하나 만들어 합칩니다. 누가 언제 무엇을 합쳤는지 기록에 그대로 남습니다.'**
  String get helpMergeCommitInGit;

  /// No description provided for @helpMergeCommitWhy.
  ///
  /// In ko, this message translates to:
  /// **'이미 올린 커밋을 바꾸지 않아 가장 안전합니다. 다른 사람과 같이 쓰는 브랜치에 알맞습니다. 대신 기록에 병합 커밋이 늘어 조금 복잡해 보입니다.'**
  String get helpMergeCommitWhy;

  /// No description provided for @helpRebaseTitle.
  ///
  /// In ko, this message translates to:
  /// **'Rebase'**
  String get helpRebaseTitle;

  /// No description provided for @helpRebaseWord.
  ///
  /// In ko, this message translates to:
  /// **'base는 \'밑받침\', rebase는 \'밑받침을 다시 놓다\'.'**
  String get helpRebaseWord;

  /// No description provided for @helpRebaseInGit.
  ///
  /// In ko, this message translates to:
  /// **'내 커밋들을 떼어 내서, 새로 받아온 커밋 뒤에 차례로 다시 붙입니다. 내용은 같지만 새 커밋(C\', D\')으로 다시 만들어지고, 기록은 한 줄이 됩니다.'**
  String get helpRebaseInGit;

  /// No description provided for @helpRebaseWhy.
  ///
  /// In ko, this message translates to:
  /// **'병합 커밋 없이 기록이 깔끔합니다. 아직 Push하지 않은 내 커밋에만 쓰세요. 이미 올린 커밋을 rebase하면 다른 사람의 기록과 어긋나서 강제 Push가 필요해집니다.'**
  String get helpRebaseWhy;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
