// From jejezz/application-release-templates common/ @ conventions-v1.
//
// 새 앱의 시작점. 규약이 요구하는 연결을 한곳에 모았다:
//   창 크기(window_manager) · 추가 라이선스 · 설정 로드 · 라이트/다크 ·
//   언어 해석 · macOS 앱 메뉴 About · 앱 바 [테마 | 언어 | 정보] · 빈 상태.
// Branch Dock: 창은 편집기 옆 세로 창(UI_UX.md §2), 화면은 lib/ui/main_screen.dart.

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:screen_retriever/screen_retriever.dart';
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
import 'update/update_service.dart';

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
    final saved = Platform.isWindows ? await _restorableWindowsBounds(prefs) : prefs.windowBounds;
    // Windows는 runner(main.cpp)가 첫 크기와 위치를 정한다. Dart 쪽 setSize/center는
    // devicePixelRatio 오차로 창을 화면 오른쪽 밖에 놓을 수 있다.
    final options = WindowOptions(
      size: Platform.isWindows ? null : _defaultSize,
      minimumSize: _minimumSize,
      title: AppIdentity.displayName,
    );
    await windowManager.waitUntilReadyToShow(options, () async {
      // 사용자가 편집기 옆에 맞춰 둔 크기와 위치를 되살린다.
      if (saved != null && saved.width >= _minimumSize.width && saved.height >= _minimumSize.height) {
        await windowManager.setBounds(saved);
      } else if (!Platform.isWindows) {
        await windowManager.center();
      }
      await windowManager.show();
      await windowManager.focus();
    });
    windowManager.addListener(_BoundsSaver(prefs));
  }

  final services = AppServices(
    runner: CommandRunner(
      log: CommandLog(),
      path: await resolvePath(),
      gitPath: prefs.toolPath('git'),
      ghPath: prefs.toolPath('gh'),
    ),
    prefs: prefs,
  );
  final settings = await AppSettings.load();
  // 데스크톱이 아니거나 UPDATE_SERVER 가 비어 있으면 null — 업데이트 확인 없음.
  final updates = await UpdateService.create();
  runApp(ServicesScope(services: services, child: App(settings: settings, updates: updates)));
}

double _devicePixelRatio() => ui.PlatformDispatcher.instance.implicitView?.devicePixelRatio ?? 1.0;

/// 저장한 물리 픽셀 위치가 지금 연결된 모니터 안에 있을 때만 window_manager 좌표(논리)로 바꿔 돌려준다.
/// 보조 모니터에서 종료한 뒤 그 모니터가 없거나 배율이 다르면 null → runner가 정한 기본 위치를 쓴다.
Future<Rect?> _restorableWindowsBounds(RepoPrefs prefs) async {
  final px = prefs.windowPixelBounds;
  if (px == null) return null;
  final dpr = _devicePixelRatio();
  final logical = Rect.fromLTWH(px.left / dpr, px.top / dpr, px.width / dpr, px.height / dpr);
  if (logical.width < _minimumSize.width || logical.height < _minimumSize.height) return null;
  try {
    for (final d in await screenRetriever.getAllDisplays()) {
      final scale = (d.scaleFactor ?? 1.0).toDouble();
      final pos = d.visiblePosition ?? Offset.zero;
      final size = d.visibleSize ?? d.size;
      final area = Rect.fromLTWH(pos.dx * scale, pos.dy * scale, size.width * scale, size.height * scale);
      final overlap = area.intersect(px);
      if (overlap.width >= 100 && overlap.height >= 100) return logical;
    }
  } catch (_) {}
  return null;
}

/// 창을 옮기거나 크기를 바꾸면 잠시 뒤 저장한다.
class _BoundsSaver with WindowListener {
  _BoundsSaver(this.prefs);

  final RepoPrefs prefs;
  Timer? _timer;

  void _schedule() {
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 500), () async {
      final b = await windowManager.getBounds();
      if (Platform.isWindows) {
        final dpr = _devicePixelRatio();
        prefs.setWindowPixelBounds(Rect.fromLTWH(b.left * dpr, b.top * dpr, b.width * dpr, b.height * dpr));
      } else {
        prefs.setWindowBounds(b);
      }
    });
  }

  @override
  void onWindowResized() => _schedule();

  @override
  void onWindowMoved() => _schedule();
}

class App extends StatefulWidget {
  const App({super.key, required this.settings, this.updates});

  final AppSettings settings;
  final UpdateService? updates;

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
    widget.updates?.startAutomaticCheck(_navigatorKey);
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
    showAppAboutDialog(
      context,
      tagline: l10n.aboutTagline,
      description: l10n.aboutDescription,
      onCheckForUpdates: widget.updates == null ? null : () => widget.updates!.checkManually(context),
    );
  }

  void _checkForUpdates() {
    final context = _navigatorKey.currentContext;
    if (context != null) widget.updates?.checkManually(context);
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
          builder: (context, child) => AppMenuBar(
            onAbout: _showAbout,
            onCheckForUpdates: widget.updates == null ? null : _checkForUpdates,
            child: child!,
          ),
          home: MainScreen(onAbout: _showAbout),
        ),
      ),
    );
  }
}
