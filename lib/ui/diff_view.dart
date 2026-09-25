import 'package:flutter/material.dart';

import '../core/command_runner.dart';
import '../git/diff.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'action_sheet.dart';
import 'widgets.dart';

/// 읽기 전용 diff (PLAN.md 3.2 P2). 좁은 세로 창에 맞게 긴 줄은 접는다.
class DiffView extends StatelessWidget {
  const DiffView({super.key, required this.diff});

  final FileDiff diff;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    if (diff.binary) return Text(l10n.diffBinary, style: theme.textTheme.bodySmall);
    if (diff.empty) return Text(l10n.diffEmpty, style: theme.textTheme.bodySmall);
    final added = toneColor(context, Tone.success);
    final removed = toneColor(context, Tone.danger);
    final gutter = AppFonts.mono.copyWith(fontSize: 10.5, color: theme.colorScheme.onSurfaceVariant);
    final code = AppFonts.mono.copyWith(fontSize: 11.5, color: theme.colorScheme.onSurface);
    String n(int? v) => v == null ? '' : '$v';
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        for (final line in diff.lines)
          switch (line.kind) {
            DiffLineKind.hunk => Container(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                child: Text(line.text, style: gutter),
              ),
            DiffLineKind.meta => Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Text(line.text, style: gutter.copyWith(fontStyle: FontStyle.italic)),
              ),
            _ => Container(
                color: switch (line.kind) {
                  DiffLineKind.added => added.withValues(alpha: 0.12),
                  DiffLineKind.removed => removed.withValues(alpha: 0.12),
                  _ => null,
                },
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SizedBox(width: 34, child: Text(n(line.oldNo), textAlign: TextAlign.right, style: gutter)),
                  SizedBox(width: 34, child: Text(n(line.newNo), textAlign: TextAlign.right, style: gutter)),
                  SizedBox(
                    width: 16,
                    child: Text(
                      switch (line.kind) {
                        DiffLineKind.added => '+',
                        DiffLineKind.removed => '-',
                        _ => ' ',
                      },
                      textAlign: TextAlign.center,
                      style: code.copyWith(
                        color: line.kind == DiffLineKind.added
                            ? added
                            : (line.kind == DiffLineKind.removed ? removed : null),
                      ),
                    ),
                  ),
                  Expanded(child: SelectableText(line.text, style: code)),
                ]),
              ),
          },
        if (diff.truncated)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Text(l10n.diffTruncated(FileDiff.maxLines), style: theme.textTheme.bodySmall),
          ),
      ]),
    );
  }
}

/// diff 시트: 제목(경로), +N −M, 명령, 내용, 그리고 필요하면 아래 동작 버튼.
Future<void> showDiffSheet(
  BuildContext context, {
  required String title,
  required List<String> command,
  required CommandResult result,
  List<Widget> actions = const [],
}) {
  // 추적 안 된 파일 비교(--no-index)는 차이가 있으면 종료 코드 1 — 출력이 있으면 성공으로 본다.
  final diff = FileDiff.parse(result.stdout);
  return showActionSheet<void>(context, (context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(title, style: theme.textTheme.titleMedium?.merge(AppFonts.userContent)),
          const SizedBox(height: 4),
          Row(children: [
            StatusPill(label: '+${diff.added}', tone: Tone.success),
            const SizedBox(width: 4),
            StatusPill(label: '−${diff.removed}', tone: Tone.danger),
            const Spacer(),
            ...actions,
          ]),
          const SizedBox(height: AppSpacing.sm),
          if (!result.ok && result.stdout.isEmpty)
            Text(result.combined, style: AppFonts.mono.copyWith(fontSize: 11, color: theme.colorScheme.error))
          else
            DiffView(diff: diff),
          const SizedBox(height: AppSpacing.md),
          CommandPreview(commands: [command]),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.commonClose)),
          ),
        ]),
      ),
    );
  });
}
