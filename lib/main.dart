// From jejezz/application-release-templates common/ @ conventions-v1.
//
// 새 앱의 시작점. 규약이 요구하는 연결을 한곳에 모았다:
//   창 크기(window_manager) · 추가 라이선스 · 설정 로드 · 라이트/다크 ·
//   언어 해석 · macOS 앱 메뉴 About · 앱 바 [테마 | 언어 | 정보] · 빈 상태.
// Branch Dock: 창은 편집기 옆 세로 창(UI_UX.md §2), 화면은 lib/ui/main_screen.dart.

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'about/about_dialog.dart';
import 'about/app_menu_bar.dart';
import 'about/extra_licenses.dart';
import 'app_identity.dart';
import 'core/command_log.dart';
import 'core/command_runner.dart';
import 'l10n/app_localizations.dart';
import 'repo/repo_prefs.dart';
import 'settings/app_settings.dart';
import 'theme/app_theme.dart';
import 'ui/main_screen.dart';
import 'ui/services.dart';

final bool _isDesktop = Platform.isMacOS || Platform.isWindows || Platform.isLinux;

/// UI_UX.md §2 — 규약 §5와 다르게 편집기 옆 세로 창.
const _defaultSize = Size(440, 960);
const _minimumSize = Size(380, 560);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerExtraLicenses();

  final prefs = await RepoPrefs.load();
  if (_isDesktop) {
    await windowManager.ensureInitialized();
    final saved = prefs.windowBounds;
    const options = WindowOptions(
      size: _defaultSize,
      minimumSize: _minimumSize,
      title: AppIdentity.displayName,
    );
    await windowManager.waitUntilReadyToShow(options, () async {
      // 사용자가 편집기 옆에 맞춰 둔 크기와 위치를 되살린다.
      if (saved != null && saved.width >= _minimumSize.width && saved.height >= _minimumSize.height) {
        await windowManager.setBounds(saved);
      } else {
        await windowManager.center();
      }
      await windowManager.show();
      await windowManager.focus();
    });
    windowManager.addListener(_BoundsSaver(prefs));
  }

  final services = AppServices(
    runner: CommandRunner(log: CommandLog(), path: await resolvePath()),
    prefs: prefs,
  );
  final settings = await AppSettings.load();
  runApp(ServicesScope(services: services, child: App(settings: settings)));
}

/// 창을 옮기거나 크기를 바꾸면 잠시 뒤 저장한다.
class _BoundsSaver with WindowListener {
  _BoundsSaver(this.prefs);

  final RepoPrefs prefs;
  Timer? _timer;

  void _schedule() {
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 500), () async {
      prefs.setWindowBounds(await windowManager.getBounds());
    });
  }

  @override
  void onWindowResized() => _schedule();

  @override
  void onWindowMoved() => _schedule();
}

class App extends StatefulWidget {
  const App({super.key, required this.settings});

  final AppSettings settings;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with WidgetsBindingObserver {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.settings.addListener(_syncWindowBrightness);
    _syncWindowBrightness();
  }

  @override
  void dispose() {
    widget.settings.removeListener(_syncWindowBrightness);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // 앱에서 다크를 골라도 OS가 라이트면 제목 표시줄은 밝게 남는다 (theming.md §4).
  @override
  void didChangePlatformBrightness() => _syncWindowBrightness();

  void _syncWindowBrightness() {
    if (!_isDesktop || Platform.isLinux) return;
    final brightness = switch (widget.settings.themeMode) {
      ThemeMode.light => Brightness.light,
      ThemeMode.dark => Brightness.dark,
      ThemeMode.system => WidgetsBinding.instance.platformDispatcher.platformBrightness,
    };
    windowManager.setBrightness(brightness);
  }

  void _showAbout() {
    final context = _navigatorKey.currentContext;
    if (context == null) return;
    final l10n = AppLocalizations.of(context);
    showAppAboutDialog(context, tagline: l10n.aboutTagline, description: l10n.aboutDescription);
  }

  @override
  Widget build(BuildContext context) {
    return AppSettingsScope(
      settings: widget.settings,
      child: ListenableBuilder(
        listenable: widget.settings,
        builder: (context, _) => MaterialApp(
          navigatorKey: _navigatorKey,
          title: AppIdentity.displayName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(dense: _isDesktop),
          darkTheme: AppTheme.dark(dense: _isDesktop),
          themeMode: widget.settings.themeMode,
          locale: widget.settings.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          localeResolutionCallback: AppSettings.resolveLocale,
          builder: (context, child) => AppMenuBar(onAbout: _showAbout, child: child!),
          home: MainScreen(onAbout: _showAbout),
        ),
      ),
    );
  }
}
