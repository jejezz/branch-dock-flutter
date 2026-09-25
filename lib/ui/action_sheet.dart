import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'help/concepts.dart';
import 'repo_scope.dart';
import 'widgets.dart';

/// 아래에서 올라오는 양식 (UI_UX.md §5). 버튼 바로 위에 "실행될 명령".
/// 시트는 앱 최상위 경로에 뜨므로, 부른 곳의 저장소·환경을 시트 안에도 다시 넣어 준다.
Future<T?> showActionSheet<T>(BuildContext context, WidgetBuilder builder) {
  final scope = context.getInheritedWidgetOfExactType<RepoScope>();
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.85),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet))),
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: scope == null
          ? builder(context)
          : RepoScope(repo: scope.notifier!, environment: scope.environment, child: Builder(builder: builder)),
    ),
  );
}

/// 시트 한 장의 틀: 제목, 본문, 실행될 명령, [취소] [실행].
class ActionSheetBody extends StatelessWidget {
  const ActionSheetBody({
    super.key,
    required this.title,
    required this.children,
    required this.commands,
    required this.confirmLabel,
    required this.onConfirm,
    this.help,
    this.danger = false,
  });

  final String title;
  final List<Widget> children;
  final List<List<String>> commands;
  final String confirmLabel;

  /// null이면 실행 버튼 비활성 (입력이 아직 올바르지 않음).
  final VoidCallback? onConfirm;
  final Concept? help;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.lg),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(child: Text(title, style: theme.textTheme.titleLarge)),
            if (help != null) HelpButton(concept: help!),
          ]),
          const SizedBox(height: AppSpacing.lg),
          ...children,
          const SizedBox(height: AppSpacing.lg),
          if (commands.isNotEmpty) CommandPreview(commands: commands),
          const SizedBox(height: AppSpacing.lg),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.commonCancel)),
            const SizedBox(width: AppSpacing.sm),
            FilledButton(
              style: danger
                  ? FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.error, foregroundColor: theme.colorScheme.onError)
                  : null,
              onPressed: onConfirm,
              child: Text(confirmLabel),
            ),
          ]),
        ]),
      ),
    );
  }
}
