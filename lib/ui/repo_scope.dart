import 'package:flutter/widgets.dart';

import '../repo/environment.dart';
import '../repo/repo_controller.dart';

/// 열린 저장소를 아래 위젯에 내린다. 상태가 바뀌면 다시 그린다.
class RepoScope extends InheritedNotifier<RepoController> {
  const RepoScope({
    super.key,
    required RepoController repo,
    required this.environment,
    this.openRepo,
    required super.child,
  }) : super(notifier: repo);

  final EnvironmentStatus environment;

  /// 다른 폴더를 저장소로 연다 (예: 브랜치가 체크아웃된 다른 worktree).
  final ValueChanged<String>? openRepo;

  /// 다시 그리지 않고 [openRepo]만 꺼낸다. RepoScope 바깥이면 null.
  static ValueChanged<String>? openRepoOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<RepoScope>()?.openRepo;

  static RepoController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<RepoScope>()!.notifier!;

  static EnvironmentStatus environmentOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<RepoScope>()!.environment;

  @override
  bool updateShouldNotify(RepoScope oldWidget) =>
      super.updateShouldNotify(oldWidget) || oldWidget.environment != environment;
}
