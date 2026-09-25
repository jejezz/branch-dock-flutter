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

  /// No description provided for @tabTags.
  ///
  /// In ko, this message translates to:
  /// **'태그'**
  String get tabTags;

  /// No description provided for @tabRelease.
  ///
  /// In ko, this message translates to:
  /// **'릴리스'**
  String get tabRelease;

  /// No description provided for @tabPr.
  ///
  /// In ko, this message translates to:
  /// **'PR'**
  String get tabPr;

  /// No description provided for @branchesMergeInto.
  ///
  /// In ko, this message translates to:
  /// **'{head}(으)로 병합해 오기'**
  String branchesMergeInto(String head);

  /// No description provided for @mergeTitle.
  ///
  /// In ko, this message translates to:
  /// **'{source} → {into} 병합'**
  String mergeTitle(String source, String into);

  /// No description provided for @mergeNothing.
  ///
  /// In ko, this message translates to:
  /// **'{source}에는 {into}에 없는 커밋이 없습니다'**
  String mergeNothing(String source, String into);

  /// No description provided for @mergeIncoming.
  ///
  /// In ko, this message translates to:
  /// **'들어올 커밋 {count}개'**
  String mergeIncoming(int count);

  /// No description provided for @mergeFastForward.
  ///
  /// In ko, this message translates to:
  /// **'Fast-forward'**
  String get mergeFastForward;

  /// No description provided for @mergeFastForwardWhen.
  ///
  /// In ko, this message translates to:
  /// **'새 커밋 없이 이름표만 앞으로 옮깁니다. 기록이 한 줄로 남습니다.'**
  String get mergeFastForwardWhen;

  /// No description provided for @mergeFastForwardDisabled.
  ///
  /// In ko, this message translates to:
  /// **'현재 브랜치에도 새 커밋이 있어서(갈라져서) 쓸 수 없습니다.'**
  String get mergeFastForwardDisabled;

  /// No description provided for @mergeMergeCommit.
  ///
  /// In ko, this message translates to:
  /// **'병합 커밋'**
  String get mergeMergeCommit;

  /// No description provided for @mergeMergeCommitWhen.
  ///
  /// In ko, this message translates to:
  /// **'두 기록을 그대로 두고 병합 커밋으로 합칩니다. 가장 안전합니다.'**
  String get mergeMergeCommitWhen;

  /// No description provided for @mergeSquash.
  ///
  /// In ko, this message translates to:
  /// **'Squash'**
  String get mergeSquash;

  /// No description provided for @mergeSquashWhen.
  ///
  /// In ko, this message translates to:
  /// **'브랜치의 커밋을 하나로 눌러 합칩니다. 기능 하나 = 커밋 하나.'**
  String get mergeSquashWhen;

  /// No description provided for @mergeSquashNote.
  ///
  /// In ko, this message translates to:
  /// **'squash 뒤 {source}를 계속 쓰면 같은 변경이 다시 충돌할 수 있습니다. 병합 후 브랜치를 지우는 것을 권합니다.'**
  String mergeSquashNote(String source);

  /// No description provided for @mergeMessageLabel.
  ///
  /// In ko, this message translates to:
  /// **'커밋 메시지'**
  String get mergeMessageLabel;

  /// No description provided for @mergeConfirm.
  ///
  /// In ko, this message translates to:
  /// **'병합'**
  String get mergeConfirm;

  /// No description provided for @doneMerge.
  ///
  /// In ko, this message translates to:
  /// **'{source}을(를) {into}(으)로 병합했습니다'**
  String doneMerge(String source, String into);

  /// No description provided for @tagsTitle.
  ///
  /// In ko, this message translates to:
  /// **'태그'**
  String get tagsTitle;

  /// No description provided for @tagsNew.
  ///
  /// In ko, this message translates to:
  /// **'새 태그'**
  String get tagsNew;

  /// No description provided for @tagsCreate.
  ///
  /// In ko, this message translates to:
  /// **'만들기'**
  String get tagsCreate;

  /// No description provided for @tagsCreateAndPush.
  ///
  /// In ko, this message translates to:
  /// **'만들고 push'**
  String get tagsCreateAndPush;

  /// No description provided for @tagsPushAll.
  ///
  /// In ko, this message translates to:
  /// **'원격에 없는 태그 {count}개 push'**
  String tagsPushAll(int count);

  /// No description provided for @tagsPushed.
  ///
  /// In ko, this message translates to:
  /// **'원격에 있음'**
  String get tagsPushed;

  /// No description provided for @tagsLocalOnly.
  ///
  /// In ko, this message translates to:
  /// **'내 컴퓨터에만 있음'**
  String get tagsLocalOnly;

  /// No description provided for @tagsLightweight.
  ///
  /// In ko, this message translates to:
  /// **'가벼운 태그'**
  String get tagsLightweight;

  /// No description provided for @tagsAnnotated.
  ///
  /// In ko, this message translates to:
  /// **'주석 태그'**
  String get tagsAnnotated;

  /// No description provided for @tagsPush.
  ///
  /// In ko, this message translates to:
  /// **'Push'**
  String get tagsPush;

  /// No description provided for @tagsDelete.
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get tagsDelete;

  /// No description provided for @tagsDeleteRemote.
  ///
  /// In ko, this message translates to:
  /// **'원격에서 삭제'**
  String get tagsDeleteRemote;

  /// No description provided for @tagsDeleteRemoteTitle.
  ///
  /// In ko, this message translates to:
  /// **'원격 태그를 삭제할까요?'**
  String get tagsDeleteRemoteTitle;

  /// No description provided for @tagsDeleteRemoteMessage.
  ///
  /// In ko, this message translates to:
  /// **'{target}에서 {tag} 태그를 삭제합니다. 이미 받아 간 사람이 있을 수 있으니, 같은 이름을 다시 쓰기보다 다음 번호를 쓰세요. 이 태그의 GitHub 릴리스는 그대로 남습니다.'**
  String tagsDeleteRemoteMessage(String tag, String target);

  /// No description provided for @tagsEmptyTitle.
  ///
  /// In ko, this message translates to:
  /// **'아직 태그가 없습니다'**
  String get tagsEmptyTitle;

  /// No description provided for @tagsEmptyMessage.
  ///
  /// In ko, this message translates to:
  /// **'태그는 특정 커밋에 붙이는 이름표입니다. 보통 v1.0.0처럼 릴리스 버전에 씁니다.'**
  String get tagsEmptyMessage;

  /// No description provided for @tagsPushAfter.
  ///
  /// In ko, this message translates to:
  /// **'만든 뒤 {remote}에 push'**
  String tagsPushAfter(String remote);

  /// No description provided for @tagNameLabel.
  ///
  /// In ko, this message translates to:
  /// **'태그 이름'**
  String get tagNameLabel;

  /// No description provided for @tagNameExists.
  ///
  /// In ko, this message translates to:
  /// **'같은 이름의 태그가 이미 있습니다'**
  String get tagNameExists;

  /// No description provided for @tagNameInvalid.
  ///
  /// In ko, this message translates to:
  /// **'공백, .., ~ ^ : ? * [ \\ 는 쓸 수 없습니다'**
  String get tagNameInvalid;

  /// No description provided for @tagNameNotSemVer.
  ///
  /// In ko, this message translates to:
  /// **'버전 형식(v1.2.3)이 아닙니다. 만들 수는 있지만 릴리스에는 버전 형식을 권합니다.'**
  String get tagNameNotSemVer;

  /// No description provided for @tagNameMissingV.
  ///
  /// In ko, this message translates to:
  /// **'릴리스 태그는 v를 붙이는 것이 관례입니다 (v1.2.3).'**
  String get tagNameMissingV;

  /// No description provided for @tagMessageLabel.
  ///
  /// In ko, this message translates to:
  /// **'메시지'**
  String get tagMessageLabel;

  /// No description provided for @tagTargetLabel.
  ///
  /// In ko, this message translates to:
  /// **'어느 커밋에 달까요'**
  String get tagTargetLabel;

  /// No description provided for @tagTargetHead.
  ///
  /// In ko, this message translates to:
  /// **'현재 위치 ({name})'**
  String tagTargetHead(String name);

  /// No description provided for @doneCreateTag.
  ///
  /// In ko, this message translates to:
  /// **'{name} 태그를 만들었습니다'**
  String doneCreateTag(String name);

  /// No description provided for @donePushTags.
  ///
  /// In ko, this message translates to:
  /// **'태그 {count}개를 push했습니다'**
  String donePushTags(int count);

  /// No description provided for @doneDeleteTag.
  ///
  /// In ko, this message translates to:
  /// **'{name} 태그를 삭제했습니다'**
  String doneDeleteTag(String name);

  /// No description provided for @doneDeleteRemoteTag.
  ///
  /// In ko, this message translates to:
  /// **'원격에서 {name} 태그를 삭제했습니다'**
  String doneDeleteRemoteTag(String name);

  /// No description provided for @prTitle.
  ///
  /// In ko, this message translates to:
  /// **'Pull Request'**
  String get prTitle;

  /// No description provided for @prCreate.
  ///
  /// In ko, this message translates to:
  /// **'PR 만들기'**
  String get prCreate;

  /// No description provided for @prPublishAndCreate.
  ///
  /// In ko, this message translates to:
  /// **'게시하고 PR 만들기'**
  String get prPublishAndCreate;

  /// No description provided for @prTitleLabel.
  ///
  /// In ko, this message translates to:
  /// **'제목'**
  String get prTitleLabel;

  /// No description provided for @prBodyLabel.
  ///
  /// In ko, this message translates to:
  /// **'본문'**
  String get prBodyLabel;

  /// No description provided for @prBodyChanges.
  ///
  /// In ko, this message translates to:
  /// **'변경 내용'**
  String get prBodyChanges;

  /// No description provided for @prDraft.
  ///
  /// In ko, this message translates to:
  /// **'초안으로 만들기'**
  String get prDraft;

  /// No description provided for @prNotGitHubTitle.
  ///
  /// In ko, this message translates to:
  /// **'GitHub 저장소가 아닙니다'**
  String get prNotGitHubTitle;

  /// No description provided for @prNotGitHubMessage.
  ///
  /// In ko, this message translates to:
  /// **'Pull Request는 GitHub 저장소에서만 쓸 수 있습니다 — gh는 GitHub 전용 도구입니다.'**
  String get prNotGitHubMessage;

  /// No description provided for @prGhRequiredTitle.
  ///
  /// In ko, this message translates to:
  /// **'gh가 필요합니다'**
  String get prGhRequiredTitle;

  /// No description provided for @prDetached.
  ///
  /// In ko, this message translates to:
  /// **'브랜치에 있지 않습니다'**
  String get prDetached;

  /// No description provided for @prOnDefaultTitle.
  ///
  /// In ko, this message translates to:
  /// **'기본 브랜치에 있습니다'**
  String get prOnDefaultTitle;

  /// No description provided for @prOnDefaultMessage.
  ///
  /// In ko, this message translates to:
  /// **'PR은 작업 브랜치에서 만듭니다. 브랜치 탭에서 새 브랜치를 만드세요.'**
  String get prOnDefaultMessage;

  /// No description provided for @prNoneTitle.
  ///
  /// In ko, this message translates to:
  /// **'{head}에는 아직 PR이 없습니다'**
  String prNoneTitle(String head);

  /// No description provided for @prNoneMessage.
  ///
  /// In ko, this message translates to:
  /// **'{base}(으)로 합칠 PR을 만들면 GitHub에서 검토와 검사를 거쳐 병합합니다.'**
  String prNoneMessage(String base);

  /// No description provided for @prOpenOnGitHub.
  ///
  /// In ko, this message translates to:
  /// **'GitHub에서 보기'**
  String get prOpenOnGitHub;

  /// No description provided for @prStateOpen.
  ///
  /// In ko, this message translates to:
  /// **'열림'**
  String get prStateOpen;

  /// No description provided for @prStateDraft.
  ///
  /// In ko, this message translates to:
  /// **'초안'**
  String get prStateDraft;

  /// No description provided for @prStateMerged.
  ///
  /// In ko, this message translates to:
  /// **'병합됨'**
  String get prStateMerged;

  /// No description provided for @prStateClosed.
  ///
  /// In ko, this message translates to:
  /// **'닫힘'**
  String get prStateClosed;

  /// No description provided for @prNoChecks.
  ///
  /// In ko, this message translates to:
  /// **'검사 없음'**
  String get prNoChecks;

  /// No description provided for @prChecksPassed.
  ///
  /// In ko, this message translates to:
  /// **'통과 {n}'**
  String prChecksPassed(int n);

  /// No description provided for @prChecksFailed.
  ///
  /// In ko, this message translates to:
  /// **'실패 {n}'**
  String prChecksFailed(int n);

  /// No description provided for @prChecksPending.
  ///
  /// In ko, this message translates to:
  /// **'진행 중 {n}'**
  String prChecksPending(int n);

  /// No description provided for @prApproved.
  ///
  /// In ko, this message translates to:
  /// **'승인됨'**
  String get prApproved;

  /// No description provided for @prReviewRequired.
  ///
  /// In ko, this message translates to:
  /// **'리뷰 필요'**
  String get prReviewRequired;

  /// No description provided for @prBlockedDraft.
  ///
  /// In ko, this message translates to:
  /// **'초안 PR은 병합할 수 없습니다. GitHub에서 \'검토 준비 완료\'로 바꾸세요.'**
  String get prBlockedDraft;

  /// No description provided for @prBlockedConflict.
  ///
  /// In ko, this message translates to:
  /// **'기준 브랜치와 충돌이 있습니다. 기준 브랜치를 병합해 와서 충돌을 해결하세요.'**
  String get prBlockedConflict;

  /// No description provided for @prBlockedChecks.
  ///
  /// In ko, this message translates to:
  /// **'실패한 검사가 있습니다: {names}'**
  String prBlockedChecks(String names);

  /// No description provided for @prBlockedPending.
  ///
  /// In ko, this message translates to:
  /// **'검사 {count}개가 아직 진행 중입니다.'**
  String prBlockedPending(int count);

  /// No description provided for @prBlockedReview.
  ///
  /// In ko, this message translates to:
  /// **'리뷰 승인이 필요할 수 있습니다. 병합이 거부되면 GitHub에서 확인하세요.'**
  String get prBlockedReview;

  /// No description provided for @prMethodMerge.
  ///
  /// In ko, this message translates to:
  /// **'병합 커밋 (merge)'**
  String get prMethodMerge;

  /// No description provided for @prMethodSquash.
  ///
  /// In ko, this message translates to:
  /// **'Squash 후 병합'**
  String get prMethodSquash;

  /// No description provided for @prMethodRebase.
  ///
  /// In ko, this message translates to:
  /// **'Rebase 후 병합'**
  String get prMethodRebase;

  /// No description provided for @prDeleteBranch.
  ///
  /// In ko, this message translates to:
  /// **'병합 후 브랜치 삭제'**
  String get prDeleteBranch;

  /// No description provided for @prMerge.
  ///
  /// In ko, this message translates to:
  /// **'병합하기'**
  String get prMerge;

  /// No description provided for @donePrCreated.
  ///
  /// In ko, this message translates to:
  /// **'PR을 만들었습니다'**
  String get donePrCreated;

  /// No description provided for @donePrMerged.
  ///
  /// In ko, this message translates to:
  /// **'PR #{number}을(를) 병합했습니다'**
  String donePrMerged(int number);

  /// No description provided for @releaseTitle.
  ///
  /// In ko, this message translates to:
  /// **'릴리스'**
  String get releaseTitle;

  /// No description provided for @releaseLatest.
  ///
  /// In ko, this message translates to:
  /// **'마지막 릴리스 {tag}'**
  String releaseLatest(String tag);

  /// No description provided for @releaseNoTags.
  ///
  /// In ko, this message translates to:
  /// **'아직 릴리스가 없습니다'**
  String get releaseNoTags;

  /// No description provided for @releaseIntro.
  ///
  /// In ko, this message translates to:
  /// **'버전 올리기 → PR → 병합 → 태그 → CI 확인을 차례로 안내합니다.'**
  String get releaseIntro;

  /// No description provided for @releaseNeedsGitHub.
  ///
  /// In ko, this message translates to:
  /// **'릴리스 마법사는 GitHub 저장소에서 쓸 수 있습니다. 태그는 태그 탭에서 만들 수 있습니다.'**
  String get releaseNeedsGitHub;

  /// No description provided for @releaseStart.
  ///
  /// In ko, this message translates to:
  /// **'새 릴리스'**
  String get releaseStart;

  /// No description provided for @releaseNew.
  ///
  /// In ko, this message translates to:
  /// **'새 릴리스'**
  String get releaseNew;

  /// No description provided for @releaseNewVersion.
  ///
  /// In ko, this message translates to:
  /// **'새 릴리스 {tag}'**
  String releaseNewVersion(String tag);

  /// No description provided for @releaseCancel.
  ///
  /// In ko, this message translates to:
  /// **'그만두기'**
  String get releaseCancel;

  /// No description provided for @releaseCancelTitle.
  ///
  /// In ko, this message translates to:
  /// **'릴리스를 그만둘까요?'**
  String get releaseCancelTitle;

  /// No description provided for @releaseCancelMessage.
  ///
  /// In ko, this message translates to:
  /// **'지금까지 만든 {branch} 브랜치와 PR은 그대로 남습니다. 필요 없으면 직접 지우세요.'**
  String releaseCancelMessage(String branch);

  /// No description provided for @releaseCancelAfterTag.
  ///
  /// In ko, this message translates to:
  /// **'태그는 이미 push되었습니다. 마법사만 닫고, CI와 릴리스는 GitHub에서 확인하세요.'**
  String get releaseCancelAfterTag;

  /// No description provided for @releaseDone.
  ///
  /// In ko, this message translates to:
  /// **'{tag} 릴리스를 마쳤습니다'**
  String releaseDone(String tag);

  /// No description provided for @releasePrerelease.
  ///
  /// In ko, this message translates to:
  /// **'프리릴리스'**
  String get releasePrerelease;

  /// No description provided for @releasePushAndPr.
  ///
  /// In ko, this message translates to:
  /// **'push하고 PR 만들기'**
  String get releasePushAndPr;

  /// No description provided for @stepCheck.
  ///
  /// In ko, this message translates to:
  /// **'점검'**
  String get stepCheck;

  /// No description provided for @stepVersion.
  ///
  /// In ko, this message translates to:
  /// **'버전'**
  String get stepVersion;

  /// No description provided for @stepPr.
  ///
  /// In ko, this message translates to:
  /// **'PR'**
  String get stepPr;

  /// No description provided for @stepMerge.
  ///
  /// In ko, this message translates to:
  /// **'병합'**
  String get stepMerge;

  /// No description provided for @stepTag.
  ///
  /// In ko, this message translates to:
  /// **'태그'**
  String get stepTag;

  /// No description provided for @stepNotes.
  ///
  /// In ko, this message translates to:
  /// **'릴리스 노트'**
  String get stepNotes;

  /// No description provided for @stepNotesCi.
  ///
  /// In ko, this message translates to:
  /// **'노트 (CI 릴리스 후)'**
  String get stepNotesCi;

  /// No description provided for @stepNotesCiSummary.
  ///
  /// In ko, this message translates to:
  /// **'CI가 릴리스를 만듭니다'**
  String get stepNotesCiSummary;

  /// No description provided for @stepCi.
  ///
  /// In ko, this message translates to:
  /// **'CI 확인'**
  String get stepCi;

  /// No description provided for @stepNext.
  ///
  /// In ko, this message translates to:
  /// **'다음'**
  String get stepNext;

  /// No description provided for @stepCheckDone.
  ///
  /// In ko, this message translates to:
  /// **'모두 통과'**
  String get stepCheckDone;

  /// No description provided for @stepMergeDone.
  ///
  /// In ko, this message translates to:
  /// **'PR #{number} 병합됨'**
  String stepMergeDone(int number);

  /// No description provided for @checkCleanTree.
  ///
  /// In ko, this message translates to:
  /// **'커밋하지 않은 변경이 없다'**
  String get checkCleanTree;

  /// No description provided for @checkShowChanges.
  ///
  /// In ko, this message translates to:
  /// **'변경 보기'**
  String get checkShowChanges;

  /// No description provided for @checkOnDefault.
  ///
  /// In ko, this message translates to:
  /// **'기본 브랜치({branch})에 있다'**
  String checkOnDefault(String branch);

  /// No description provided for @checkSynced.
  ///
  /// In ko, this message translates to:
  /// **'원격과 같다'**
  String get checkSynced;

  /// No description provided for @checkGitHub.
  ///
  /// In ko, this message translates to:
  /// **'GitHub 원격과 gh 로그인'**
  String get checkGitHub;

  /// No description provided for @checkChangesSince.
  ///
  /// In ko, this message translates to:
  /// **'{tag} 이후 커밋 {count}개'**
  String checkChangesSince(int count, String tag);

  /// No description provided for @checkFirstRelease.
  ///
  /// In ko, this message translates to:
  /// **'첫 릴리스입니다'**
  String get checkFirstRelease;

  /// No description provided for @checkNoWorkflow.
  ///
  /// In ko, this message translates to:
  /// **'태그로 도는 워크플로가 없습니다. 앱이 GitHub 릴리스를 만듭니다.'**
  String get checkNoWorkflow;

  /// No description provided for @checkWorkflowCi.
  ///
  /// In ko, this message translates to:
  /// **'{file}이(가) 태그 push로 릴리스를 만듭니다. 앱은 태그까지 달고 CI를 지켜봅니다.'**
  String checkWorkflowCi(String file);

  /// No description provided for @checkWorkflowOther.
  ///
  /// In ko, this message translates to:
  /// **'{file}이(가) 태그 push로 돕니다.'**
  String checkWorkflowOther(String file);

  /// No description provided for @manualBuildTitle.
  ///
  /// In ko, this message translates to:
  /// **'태그 전 수동 빌드 (권장)'**
  String get manualBuildTitle;

  /// No description provided for @manualBuildWhy.
  ///
  /// In ko, this message translates to:
  /// **'지난 릴리스 이후 빌드에 영향을 주는 파일이 바뀌었습니다. 태그 전에 모든 플랫폼이 빌드되는지 확인하세요. 수동 실행은 릴리스를 만들지 않습니다.'**
  String get manualBuildWhy;

  /// No description provided for @manualBuildStart.
  ///
  /// In ko, this message translates to:
  /// **'빌드만 확인'**
  String get manualBuildStart;

  /// No description provided for @manualBuildShort.
  ///
  /// In ko, this message translates to:
  /// **'수동 빌드 {state}'**
  String manualBuildShort(String state);

  /// No description provided for @doneManualBuildStarted.
  ///
  /// In ko, this message translates to:
  /// **'수동 빌드를 시작했습니다'**
  String get doneManualBuildStarted;

  /// No description provided for @versionCurrent.
  ///
  /// In ko, this message translates to:
  /// **'현재 {version} ({source})'**
  String versionCurrent(String version, String source);

  /// No description provided for @versionFromTag.
  ///
  /// In ko, this message translates to:
  /// **'마지막 태그'**
  String get versionFromTag;

  /// No description provided for @versionRecommended.
  ///
  /// In ko, this message translates to:
  /// **'추천'**
  String get versionRecommended;

  /// No description provided for @versionReason.
  ///
  /// In ko, this message translates to:
  /// **'새 기능 {feats} · 버그 수정 {fixes} · 호환 깨짐 {breaking}'**
  String versionReason(int feats, int fixes, int breaking);

  /// No description provided for @versionCustom.
  ///
  /// In ko, this message translates to:
  /// **'직접 입력'**
  String get versionCustom;

  /// No description provided for @versionFiles.
  ///
  /// In ko, this message translates to:
  /// **'바뀌는 파일'**
  String get versionFiles;

  /// No description provided for @versionNoFiles.
  ///
  /// In ko, this message translates to:
  /// **'버전 파일이 없어서 태그만 만듭니다.'**
  String get versionNoFiles;

  /// No description provided for @versionCommit.
  ///
  /// In ko, this message translates to:
  /// **'릴리스 브랜치 만들고 커밋'**
  String get versionCommit;

  /// No description provided for @bumpFinal.
  ///
  /// In ko, this message translates to:
  /// **'정식'**
  String get bumpFinal;

  /// No description provided for @bumpPrerelease.
  ///
  /// In ko, this message translates to:
  /// **'프리릴리스'**
  String get bumpPrerelease;

  /// No description provided for @doneReleaseCommit.
  ///
  /// In ko, this message translates to:
  /// **'{tag} 버전 올림을 커밋했습니다'**
  String doneReleaseCommit(String tag);

  /// No description provided for @mergeWaiting.
  ///
  /// In ko, this message translates to:
  /// **'PR #{number} 병합을 기다리는 중 — GitHub에서 병합해도 알아챕니다'**
  String mergeWaiting(int number);

  /// No description provided for @tagCheckPrMerged.
  ///
  /// In ko, this message translates to:
  /// **'PR #{number}이(가) 병합됐다'**
  String tagCheckPrMerged(int number);

  /// No description provided for @tagCheckSynced.
  ///
  /// In ko, this message translates to:
  /// **'{branch}에 있고 원격과 같다'**
  String tagCheckSynced(String branch);

  /// No description provided for @tagCheckVersion.
  ///
  /// In ko, this message translates to:
  /// **'버전 파일이 {tag}와 같다'**
  String tagCheckVersion(String tag);

  /// No description provided for @tagCheckVersionWrong.
  ///
  /// In ko, this message translates to:
  /// **'지금 버전은 {version}입니다. 버전 올림 PR이 아직 병합되지 않았을 수 있습니다.'**
  String tagCheckVersionWrong(String version);

  /// No description provided for @tagCheckFree.
  ///
  /// In ko, this message translates to:
  /// **'{tag} 태그가 아직 없다'**
  String tagCheckFree(String tag);

  /// No description provided for @tagConfirmTitle.
  ///
  /// In ko, this message translates to:
  /// **'{tag} 태그를 push할까요?'**
  String tagConfirmTitle(String tag);

  /// No description provided for @tagConfirmMessage.
  ///
  /// In ko, this message translates to:
  /// **'{branch}의 병합 커밋에 {tag}를 답니다. push하면 릴리스가 공개되고, 태그는 옮기거나 지우지 않는 것이 규칙입니다.'**
  String tagConfirmMessage(String tag, String branch);

  /// No description provided for @tagConfirmPush.
  ///
  /// In ko, this message translates to:
  /// **'태그 달고 push'**
  String get tagConfirmPush;

  /// No description provided for @doneTagPushed.
  ///
  /// In ko, this message translates to:
  /// **'{tag} 태그를 push했습니다'**
  String doneTagPushed(String tag);

  /// No description provided for @notesLabel.
  ///
  /// In ko, this message translates to:
  /// **'릴리스 노트 (마크다운)'**
  String get notesLabel;

  /// No description provided for @notesFeatures.
  ///
  /// In ko, this message translates to:
  /// **'새 기능'**
  String get notesFeatures;

  /// No description provided for @notesFixes.
  ///
  /// In ko, this message translates to:
  /// **'버그 수정'**
  String get notesFixes;

  /// No description provided for @notesOther.
  ///
  /// In ko, this message translates to:
  /// **'기타'**
  String get notesOther;

  /// No description provided for @notesCreateRelease.
  ///
  /// In ko, this message translates to:
  /// **'GitHub 릴리스 만들기'**
  String get notesCreateRelease;

  /// No description provided for @notesEdit.
  ///
  /// In ko, this message translates to:
  /// **'노트 고치기'**
  String get notesEdit;

  /// No description provided for @doneReleaseCreated.
  ///
  /// In ko, this message translates to:
  /// **'GitHub 릴리스를 만들었습니다'**
  String get doneReleaseCreated;

  /// No description provided for @doneNotesSaved.
  ///
  /// In ko, this message translates to:
  /// **'릴리스 노트를 저장했습니다'**
  String get doneNotesSaved;

  /// No description provided for @ciWaitingForRun.
  ///
  /// In ko, this message translates to:
  /// **'{tag}(으)로 시작된 워크플로를 찾는 중'**
  String ciWaitingForRun(String tag);

  /// No description provided for @ciOpenInBrowser.
  ///
  /// In ko, this message translates to:
  /// **'브라우저에서 보기'**
  String get ciOpenInBrowser;

  /// No description provided for @ciRerunFailed.
  ///
  /// In ko, this message translates to:
  /// **'실패한 잡 다시 실행'**
  String get ciRerunFailed;

  /// No description provided for @doneRerun.
  ///
  /// In ko, this message translates to:
  /// **'실패한 잡을 다시 실행했습니다'**
  String get doneRerun;

  /// No description provided for @runQueued.
  ///
  /// In ko, this message translates to:
  /// **'대기 중'**
  String get runQueued;

  /// No description provided for @runRunning.
  ///
  /// In ko, this message translates to:
  /// **'진행 중'**
  String get runRunning;

  /// No description provided for @runSuccess.
  ///
  /// In ko, this message translates to:
  /// **'성공'**
  String get runSuccess;

  /// No description provided for @runFailure.
  ///
  /// In ko, this message translates to:
  /// **'실패'**
  String get runFailure;

  /// No description provided for @runCancelled.
  ///
  /// In ko, this message translates to:
  /// **'취소됨'**
  String get runCancelled;

  /// No description provided for @runSkipped.
  ///
  /// In ko, this message translates to:
  /// **'건너뜀'**
  String get runSkipped;

  /// No description provided for @helpCaptionAfterSquash.
  ///
  /// In ko, this message translates to:
  /// **'squash 병합 후 — main에 새 커밋 S 하나'**
  String get helpCaptionAfterSquash;

  /// No description provided for @helpCaptionTag.
  ///
  /// In ko, this message translates to:
  /// **'v1.0.0과 v1.1.0은 옮겨지지 않는 이름표, main은 앞으로 나아가는 이름표'**
  String get helpCaptionTag;

  /// No description provided for @helpLinkGitHubMergeMethods.
  ///
  /// In ko, this message translates to:
  /// **'GitHub — 병합 방법 정보'**
  String get helpLinkGitHubMergeMethods;

  /// No description provided for @helpLinkTagging.
  ///
  /// In ko, this message translates to:
  /// **'Pro Git — 태그'**
  String get helpLinkTagging;

  /// No description provided for @helpSquashTitle.
  ///
  /// In ko, this message translates to:
  /// **'Squash (눌러 합치기)'**
  String get helpSquashTitle;

  /// No description provided for @helpSquashWord.
  ///
  /// In ko, this message translates to:
  /// **'눌러서 납작하게 만들다, 찌그러뜨리다.'**
  String get helpSquashWord;

  /// No description provided for @helpSquashInGit.
  ///
  /// In ko, this message translates to:
  /// **'브랜치의 여러 커밋을 눌러 커밋 하나로 합친 뒤 대상 브랜치에 올립니다. 변경 내용은 그대로이고 커밋 개수만 하나가 됩니다.'**
  String get helpSquashInGit;

  /// No description provided for @helpSquashWhy.
  ///
  /// In ko, this message translates to:
  /// **'\'오타 수정\', \'다시 시도\' 같은 작업 중 커밋을 기본 브랜치 기록에 남기지 않고, 기능 하나 = 커밋 하나로 정리합니다. PR을 병합할 때 많이 씁니다. 원래 커밋들은 기본 브랜치에 남지 않으니, 병합한 브랜치를 계속 쓰지 말고 지우세요.'**
  String get helpSquashWhy;

  /// No description provided for @helpTagTitle.
  ///
  /// In ko, this message translates to:
  /// **'태그 (주석 태그와 가벼운 태그)'**
  String get helpTagTitle;

  /// No description provided for @helpTagWord.
  ///
  /// In ko, this message translates to:
  /// **'tag는 \'꼬리표, 이름표\'.'**
  String get helpTagWord;

  /// No description provided for @helpTagInGit.
  ///
  /// In ko, this message translates to:
  /// **'특정 커밋에 붙이는 이름표입니다. 브랜치 이름표는 새 커밋을 따라 앞으로 가지만, 태그는 한 번 붙이면 그 커밋에 머뭅니다. 주석 태그는 만든 사람·날짜·메시지를 함께 저장하고, 가벼운 태그는 이름만 저장합니다.'**
  String get helpTagInGit;

  /// No description provided for @helpTagWhy.
  ///
  /// In ko, this message translates to:
  /// **'릴리스 버전(v1.2.0)에는 주석 태그를 씁니다 — 릴리스 기록이 남고, GitHub 릴리스와 CI가 태그를 기준으로 돕니다. 이미 push한 태그는 옮기거나 지우지 말고, 잘못됐으면 다음 번호로 새로 다세요.'**
  String get helpTagWhy;

  /// No description provided for @headerMergedAndGone.
  ///
  /// In ko, this message translates to:
  /// **'병합됨 · 원격 삭제됨'**
  String get headerMergedAndGone;

  /// No description provided for @headerMergedAndGoneTooltip.
  ///
  /// In ko, this message translates to:
  /// **'이 브랜치는 이미 기본 브랜치에 병합되었고 원격에서 삭제되었습니다. 다시 게시하면 지운 브랜치가 되살아납니다.'**
  String get headerMergedAndGoneTooltip;

  /// No description provided for @bannerMergedAndGone.
  ///
  /// In ko, this message translates to:
  /// **'이 브랜치는 병합되어 원격에서 삭제되었습니다. {branch}(으)로 돌아가세요'**
  String bannerMergedAndGone(String branch);

  /// No description provided for @bannerSwitchTo.
  ///
  /// In ko, this message translates to:
  /// **'{branch}(으)로 전환'**
  String bannerSwitchTo(String branch);

  /// No description provided for @bannerCreatePr.
  ///
  /// In ko, this message translates to:
  /// **'{branch}을(를) 올렸지만 아직 PR이 없습니다'**
  String bannerCreatePr(String branch);

  /// No description provided for @prBaseLabel.
  ///
  /// In ko, this message translates to:
  /// **'기준 브랜치'**
  String get prBaseLabel;

  /// No description provided for @prBaseNotDefault.
  ///
  /// In ko, this message translates to:
  /// **'기본 브랜치({base})가 아닌 곳으로 합칩니다. 다른 기능 브랜치 위에 쌓는 PR일 때 씁니다.'**
  String prBaseNotDefault(String base);

  /// No description provided for @tabCi.
  ///
  /// In ko, this message translates to:
  /// **'CI'**
  String get tabCi;

  /// No description provided for @ciTitle.
  ///
  /// In ko, this message translates to:
  /// **'CI 실행'**
  String get ciTitle;

  /// No description provided for @ciNotGitHubMessage.
  ///
  /// In ko, this message translates to:
  /// **'Actions는 GitHub 저장소에서만 쓸 수 있습니다 — gh는 GitHub 전용 도구입니다.'**
  String get ciNotGitHubMessage;

  /// No description provided for @ciEmptyTitle.
  ///
  /// In ko, this message translates to:
  /// **'{branch}에는 아직 실행이 없습니다'**
  String ciEmptyTitle(String branch);

  /// No description provided for @ciEmptyMessage.
  ///
  /// In ko, this message translates to:
  /// **'push나 PR, 태그로 워크플로가 돌면 여기에 나옵니다.'**
  String get ciEmptyMessage;

  /// No description provided for @ciRerun.
  ///
  /// In ko, this message translates to:
  /// **'다시 실행'**
  String get ciRerun;

  /// No description provided for @ciCancel.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get ciCancel;

  /// No description provided for @ciDispatch.
  ///
  /// In ko, this message translates to:
  /// **'수동 실행'**
  String get ciDispatch;

  /// No description provided for @ciDispatchNeedsPush.
  ///
  /// In ko, this message translates to:
  /// **'수동 실행은 원격에 있는 브랜치에서만 할 수 있습니다. 먼저 게시하세요.'**
  String get ciDispatchNeedsPush;

  /// No description provided for @ciDispatchTitle.
  ///
  /// In ko, this message translates to:
  /// **'{file} 수동 실행'**
  String ciDispatchTitle(String file);

  /// No description provided for @ciDispatchMessage.
  ///
  /// In ko, this message translates to:
  /// **'{branch} 브랜치로 워크플로를 실행합니다. 입력이 필요한 워크플로는 브라우저에서 실행하세요.'**
  String ciDispatchMessage(String branch);

  /// No description provided for @ciDispatchConfirm.
  ///
  /// In ko, this message translates to:
  /// **'실행'**
  String get ciDispatchConfirm;

  /// No description provided for @doneDispatched.
  ///
  /// In ko, this message translates to:
  /// **'{file}을(를) 실행했습니다'**
  String doneDispatched(String file);

  /// No description provided for @doneRunCancelled.
  ///
  /// In ko, this message translates to:
  /// **'실행을 취소했습니다'**
  String get doneRunCancelled;

  /// No description provided for @notifyRunTitle.
  ///
  /// In ko, this message translates to:
  /// **'{name} {state}'**
  String notifyRunTitle(String name, String state);

  /// No description provided for @notifyReleaseRun.
  ///
  /// In ko, this message translates to:
  /// **'{tag} 릴리스 CI {state}'**
  String notifyReleaseRun(String tag, String state);

  /// No description provided for @notifyManualBuild.
  ///
  /// In ko, this message translates to:
  /// **'태그 전 수동 빌드 {state}'**
  String notifyManualBuild(String state);

  /// No description provided for @prFilterMine.
  ///
  /// In ko, this message translates to:
  /// **'내 PR'**
  String get prFilterMine;

  /// No description provided for @prFilterReview.
  ///
  /// In ko, this message translates to:
  /// **'리뷰 요청'**
  String get prFilterReview;

  /// No description provided for @prFilterOpen.
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get prFilterOpen;

  /// No description provided for @prListEmpty.
  ///
  /// In ko, this message translates to:
  /// **'열린 PR이 없습니다'**
  String get prListEmpty;

  /// No description provided for @prCurrentBranch.
  ///
  /// In ko, this message translates to:
  /// **'현재 브랜치'**
  String get prCurrentBranch;

  /// No description provided for @prCheckout.
  ///
  /// In ko, this message translates to:
  /// **'이 PR 브랜치로 체크아웃'**
  String get prCheckout;

  /// No description provided for @prCheckoutWhy.
  ///
  /// In ko, this message translates to:
  /// **'PR 브랜치를 내 컴퓨터로 가져와 전환합니다. 직접 실행해 보거나 고칠 때 씁니다.'**
  String get prCheckoutWhy;

  /// No description provided for @donePrCheckout.
  ///
  /// In ko, this message translates to:
  /// **'PR #{number}의 {branch}(으)로 전환했습니다'**
  String donePrCheckout(int number, String branch);

  /// No description provided for @releasesTitle.
  ///
  /// In ko, this message translates to:
  /// **'릴리스'**
  String get releasesTitle;

  /// No description provided for @releasesEmpty.
  ///
  /// In ko, this message translates to:
  /// **'GitHub 릴리스가 없습니다'**
  String get releasesEmpty;

  /// No description provided for @releasesLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'릴리스 목록을 불러오지 못했습니다'**
  String get releasesLoadFailed;

  /// No description provided for @releaseLatestPill.
  ///
  /// In ko, this message translates to:
  /// **'최신'**
  String get releaseLatestPill;

  /// No description provided for @releaseDraft.
  ///
  /// In ko, this message translates to:
  /// **'초안'**
  String get releaseDraft;

  /// No description provided for @releaseMakeFinal.
  ///
  /// In ko, this message translates to:
  /// **'정식 릴리스로 바꾸기'**
  String get releaseMakeFinal;

  /// No description provided for @releaseMakePrerelease.
  ///
  /// In ko, this message translates to:
  /// **'프리릴리스로 바꾸기'**
  String get releaseMakePrerelease;

  /// No description provided for @releasePublishDraft.
  ///
  /// In ko, this message translates to:
  /// **'초안 게시'**
  String get releasePublishDraft;

  /// No description provided for @releaseDelete.
  ///
  /// In ko, this message translates to:
  /// **'릴리스 삭제'**
  String get releaseDelete;

  /// No description provided for @releaseDeleteTitle.
  ///
  /// In ko, this message translates to:
  /// **'{tag} 릴리스를 삭제할까요?'**
  String releaseDeleteTitle(String tag);

  /// No description provided for @releaseDeleteMessage.
  ///
  /// In ko, this message translates to:
  /// **'GitHub 릴리스와 올라간 파일이 사라집니다. 이미 받아 간 사람이 있을 수 있습니다.'**
  String get releaseDeleteMessage;

  /// No description provided for @releaseDeleteTagToo.
  ///
  /// In ko, this message translates to:
  /// **'GitHub의 {tag} 태그도 삭제 (로컬 태그는 남음)'**
  String releaseDeleteTagToo(String tag);

  /// No description provided for @doneReleaseDeleted.
  ///
  /// In ko, this message translates to:
  /// **'{tag} 릴리스를 삭제했습니다'**
  String doneReleaseDeleted(String tag);

  /// No description provided for @doneReleaseMadeFinal.
  ///
  /// In ko, this message translates to:
  /// **'{tag}을(를) 정식 릴리스로 바꿨습니다'**
  String doneReleaseMadeFinal(String tag);

  /// No description provided for @doneReleaseMadePrerelease.
  ///
  /// In ko, this message translates to:
  /// **'{tag}을(를) 프리릴리스로 바꿨습니다'**
  String doneReleaseMadePrerelease(String tag);

  /// No description provided for @doneReleasePublished.
  ///
  /// In ko, this message translates to:
  /// **'{tag} 초안을 게시했습니다'**
  String doneReleasePublished(String tag);

  /// No description provided for @notesEditTab.
  ///
  /// In ko, this message translates to:
  /// **'편집'**
  String get notesEditTab;

  /// No description provided for @notesPreviewTab.
  ///
  /// In ko, this message translates to:
  /// **'미리 보기'**
  String get notesPreviewTab;

  /// No description provided for @notesEmpty.
  ///
  /// In ko, this message translates to:
  /// **'내용이 없습니다'**
  String get notesEmpty;
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
