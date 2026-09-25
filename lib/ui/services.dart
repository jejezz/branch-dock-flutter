import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:window_manager/window_manager.dart';

import '../core/command_log.dart';
import '../core/desktop_notifier.dart';
import '../core/command_runner.dart';
import '../repo/repo_prefs.dart';

/// 앱 전체가 함께 쓰는 것들. 위젯 트리 맨 위에서 한 번 만든다.
class AppServices {
  AppServices({required this.runner, required this.prefs, DesktopNotifier? notifier})
      : notifier = notifier ?? DesktopNotifier(path: runner.path);

  final CommandRunner runner;
  final RepoPrefs prefs;
  final DesktopNotifier notifier;

  CommandLog get log => runner.log;

  /// 창이 앞에 없을 때만 OS 알림을 띄운다 — 보고 있으면 화면으로 충분하다.
  Future<void> notifyIfAway(String title, String body) async {
    if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      try {
        if (await windowManager.isFocused()) return;
      } on Object {
        // window_manager가 없는 환경(테스트)에서는 알리지 않는다.
        return;
      }
    }
    await notifier.notify(title, body);
  }
}

class ServicesScope extends InheritedWidget {
  const ServicesScope({super.key, required this.services, required super.child});

  final AppServices services;

  static AppServices of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ServicesScope>()!.services;

  @override
  bool updateShouldNotify(ServicesScope oldWidget) => services != oldWidget.services;
}
