import 'package:flutter/widgets.dart';

import '../repo/environment.dart';
import '../repo/repo_controller.dart';

/// 열린 저장소를 아래 위젯에 내린다. 상태가 바뀌면 다시 그린다.
class RepoScope extends InheritedNotifier<RepoController> {
  const RepoScope({super.key, required RepoController repo, required this.environment, required super.child})
      : super(notifier: repo);

  final EnvironmentStatus environment;

  static RepoController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<RepoScope>()!.notifier!;

  static EnvironmentStatus environmentOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<RepoScope>()!.environment;

  @override
  bool updateShouldNotify(RepoScope oldWidget) =>
      super.updateShouldNotify(oldWidget) || oldWidget.environment != environment;
}
