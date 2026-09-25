import 'package:flutter/widgets.dart';

import '../core/command_log.dart';
import '../core/command_runner.dart';
import '../repo/repo_prefs.dart';

/// 앱 전체가 함께 쓰는 것들. 위젯 트리 맨 위에서 한 번 만든다.
class AppServices {
  AppServices({required this.runner, required this.prefs});

  final CommandRunner runner;
  final RepoPrefs prefs;

  CommandLog get log => runner.log;
}

class ServicesScope extends InheritedWidget {
  const ServicesScope({super.key, required this.services, required super.child});

  final AppServices services;

  static AppServices of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ServicesScope>()!.services;

  @override
  bool updateShouldNotify(ServicesScope oldWidget) => services != oldWidget.services;
}
