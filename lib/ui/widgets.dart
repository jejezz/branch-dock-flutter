import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/command_log.dart';
import '../core/command_runner.dart';
import '../git/error_hints.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'help/concept_sheet.dart';
import 'help/concepts.dart';

/// 상태 색 — 라이트 테마에서는 대비를 위해 진한 글자색을 쓴다 (theming.md).
enum Tone { primary, success, warning, danger, neutral }

Color toneColor(BuildContext context, Tone tone) {
  final light = Theme.of(context).brightness == Brightness.light;
  final scheme = Theme.of(context).colorScheme;
  return switch (tone) {
    Tone.primary => scheme.primary,
    Tone.success => light ? AppColors.successTextLight : AppColors.success,
    Tone.warning => light ? AppColors.warningTextLight : AppColors.warning,
    Tone.danger => scheme.error,
    Tone.neutral => scheme.onSurfaceVariant,
  };
}

/// 작은 상태 표시 (ui-ux.md의 StatusPill).
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, this.tone = Tone.neutral, this.icon, this.tooltip});

  final String label;
  final Tone tone;
  final IconData? icon;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final color = toneColor(context, tone);
    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 12, color: color), const SizedBox(width: 4)],
        Text(label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: color)),
      ]),
    );
    return tooltip == null ? pill : Tooltip(message: tooltip!, child: pill);
  }
}

/// 섹션 제목 + 주 행동 (UI_UX.md §3 E).
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.trailing, this.help});

  final String title;
  final Widget? trailing;
  final Concept? help;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
      child: Row(children: [
        Flexible(
          child: Text(title, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleLarge),
        ),
        if (help != null) HelpButton(concept: help!),
        const Spacer(),
        if (trailing != null) Flexible(flex: 3, child: trailing!),
      ]),
    );
  }
}

/// 접을 수 있는 그룹 머리 (변경 파일 그룹, 로컬/원격 브랜치).
class GroupHeader extends StatelessWidget {
  const GroupHeader({
    super.key,
    required this.title,
    required this.count,
    required this.expanded,
    required this.onToggle,
    this.action,
    this.tone = Tone.neutral,
  });

  final String title;
  final int count;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget? action;
  final Tone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onToggle,
      splashFactory: NoSplash.splashFactory,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.sm, 4, AppSpacing.md, 4),
        child: Row(children: [
          Icon(expanded ? Icons.expand_more_rounded : Icons.chevron_right_rounded, size: 18,
              color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(title,
              style: theme.textTheme.titleSmall?.copyWith(
                  color: tone == Tone.neutral ? null : toneColor(context, tone))),
          const SizedBox(width: 6),
          Text('$count', style: theme.textTheme.bodySmall),
          const Spacer(),
          if (action != null) SizedBox(height: 28, child: action),
        ]),
      ),
    );
  }
}

/// "실행될 명령" 블록 (UI_UX.md §5). 고정폭, 복사 버튼.
class CommandPreview extends StatelessWidget {
  const CommandPreview({super.key, required this.commands});

  final List<List<String>> commands;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final text = commands.map(formatCommandLine).join('\n');
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(l10n.commandPreviewLabel, style: theme.textTheme.labelMedium),
      const SizedBox(height: 4),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, 4, AppSpacing.sm),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.button),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: SelectableText(text, style: AppFonts.mono.copyWith(fontSize: 12))),
          CopyButton(text: text),
        ]),
      ),
    ]);
  }
}

class CopyButton extends StatelessWidget {
  const CopyButton({super.key, required this.text, this.size = 16});

  final String text;
  final double size;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return IconButton(
      tooltip: l10n.commonCopy,
      visualDensity: VisualDensity.compact,
      iconSize: size,
      icon: const Icon(Icons.content_copy_rounded),
      onPressed: () {
        Clipboard.setData(ClipboardData(text: text));
        ScaffoldMessenger.maybeOf(context)
          ?..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(l10n.commonCopied), duration: const Duration(seconds: 2)));
      },
    );
  }
}

/// 개념 도움말을 여는 `?` (PLAN.md 3.13, UI_UX.md §6.1).
class HelpButton extends StatelessWidget {
  const HelpButton({super.key, required this.concept});

  final Concept concept;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: AppLocalizations.of(context).helpTooltip,
      visualDensity: VisualDensity.compact,
      iconSize: 16,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      icon: const Icon(Icons.help_outline_rounded),
      onPressed: () => showConceptSheet(context, concept),
    );
  }
}

/// 완료 알림: 4초 후 닫힘 (ui-ux.md §6).
void showDone(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message), duration: const Duration(seconds: 4)));
}

/// 오류 알림: 쉬운 설명 + 원문 복사 + (있으면) 해결 버튼 (UI_UX.md §3 F).
void showCommandError(
  BuildContext context,
  CommandResult result, {
  String? action,
  VoidCallback? onAction,
}) {
  final l10n = AppLocalizations.of(context);
  final hint = classifyError(result.combined, exitCode: result.exitCode);
  final raw = result.combined.trim();
  final explanation = hint == null ? null : errorHintText(l10n, hint);
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      duration: const Duration(seconds: 10),
      showCloseIcon: true,
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(explanation ?? l10n.errorGeneric, style: const TextStyle(fontWeight: FontWeight.w700)),
        if (raw.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(raw.split('\n').where((l) => l.trim().isNotEmpty).take(3).join('\n'),
              maxLines: 3, overflow: TextOverflow.ellipsis, style: AppFonts.mono.copyWith(fontSize: 11)),
        ],
      ]),
      action: onAction != null && action != null
          ? SnackBarAction(label: action, onPressed: onAction)
          : SnackBarAction(
              label: l10n.commonCopy,
              onPressed: () => Clipboard.setData(ClipboardData(text: raw)),
            ),
    ));
}

String errorHintText(AppLocalizations l10n, GitErrorKind hint) => switch (hint) {
      GitErrorKind.pushRejected => l10n.errorPushRejected,
      GitErrorKind.authFailed => l10n.errorAuthFailed,
      GitErrorKind.conflict => l10n.errorConflict,
      GitErrorKind.localChangesWouldBeOverwritten => l10n.errorLocalChanges,
      GitErrorKind.notFastForward => l10n.errorNotFastForward,
      GitErrorKind.protectedBranch => l10n.errorProtectedBranch,
      GitErrorKind.branchNotMerged => l10n.errorBranchNotMerged,
      GitErrorKind.noUpstream => l10n.errorNoUpstream,
      GitErrorKind.alreadyExists => l10n.errorAlreadyExists,
      GitErrorKind.repositoryNotFound => l10n.errorRepositoryNotFound,
      GitErrorKind.network => l10n.errorNetwork,
      GitErrorKind.notInstalled => l10n.errorNotInstalled,
    };

/// 되돌릴 수 없는 작업 확인 (ui-ux.md §6): 위험 버튼은 error 색, 기본 포커스는 취소.
Future<bool> confirmDanger(
  BuildContext context, {
  required String title,
  required String message,
  required String confirm,
  List<List<String>> commands = const [],
}) async {
  final l10n = AppLocalizations.of(context);
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 360,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(message),
          if (commands.isNotEmpty) ...[const SizedBox(height: AppSpacing.md), CommandPreview(commands: commands)],
        ]),
      ),
      actions: [
        TextButton(autofocus: true, onPressed: () => Navigator.pop(context, false), child: Text(l10n.commonCancel)),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirm),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// 빈 상태 (ui-ux.md §6): 48px 아이콘, 한 줄 안내, 주 행동 하나.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, this.message, this.action});

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 48, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(height: AppSpacing.md),
        Text(title, style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
        if (message != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(message!, style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
        ],
        if (action != null) ...[const SizedBox(height: AppSpacing.lg), action!],
      ]),
    );
  }
}

/// 상대 시간: 방금, 5분 전, 3시간 전, 2일 전, 그 이상은 날짜.
String relativeTime(AppLocalizations l10n, DateTime? t) {
  if (t == null) return '';
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return l10n.timeJustNow;
  if (d.inHours < 1) return l10n.timeMinutesAgo(d.inMinutes);
  if (d.inDays < 1) return l10n.timeHoursAgo(d.inHours);
  if (d.inDays < 30) return l10n.timeDaysAgo(d.inDays);
  return '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';
}

/// 작은 선택 칩 (커밋 접두어, 브랜치 접두어, 편집기 이름). 좁은 창에서 한 줄에 들어가게.
class SmallChip extends StatelessWidget {
  const SmallChip({super.key, required this.label, required this.onPressed, this.tooltip});

  final String label;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chip = Material(
      color: theme.colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.iconChip),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.iconChip),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          child: Text(label, style: AppFonts.mono.copyWith(fontSize: 11.5, color: theme.colorScheme.onSurface)),
        ),
      ),
    );
    return tooltip == null ? chip : Tooltip(message: tooltip!, child: chip);
  }
}
