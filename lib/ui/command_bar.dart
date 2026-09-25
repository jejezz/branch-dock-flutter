import 'package:flutter/material.dart';

import '../core/command_log.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'widgets.dart';

/// 명령 바와 로그 패널 (UI_UX.md §3 F). 접힌 상태에서는 마지막 명령 한 줄,
/// 펼치면 명령마다 출력과 복사 버튼. 위쪽 경계를 끌어서 높이를 바꾼다.
class CommandBar extends StatefulWidget {
  const CommandBar({
    super.key,
    required this.log,
    required this.expanded,
    required this.onToggle,
    this.onCancel,
  });

  final CommandLog log;
  final bool expanded;
  final VoidCallback onToggle;

  /// 실행 중인 명령을 취소한다. null이면 취소 버튼을 숨긴다.
  final VoidCallback? onCancel;

  @override
  State<CommandBar> createState() => _CommandBarState();
}

class _CommandBarState extends State<CommandBar> {
  double _height = 260;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.log,
      builder: (context, _) {
        final maxHeight = MediaQuery.sizeOf(context).height * 0.5;
        return Column(mainAxisSize: MainAxisSize.min, children: [
          if (widget.expanded) ...[
            MouseRegion(
              cursor: SystemMouseCursors.resizeRow,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onVerticalDragUpdate: (d) =>
                    setState(() => _height = (_height - d.delta.dy).clamp(120, maxHeight)),
                child: Container(height: 6, color: Theme.of(context).colorScheme.outlineVariant),
              ),
            ),
            SizedBox(height: _height.clamp(120, maxHeight), child: _LogList(log: widget.log)),
          ],
          _Bar(
            last: widget.log.last,
            expanded: widget.expanded,
            onToggle: widget.onToggle,
            onCancel: widget.onCancel,
          ),
        ]);
      },
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.last, required this.expanded, required this.onToggle, this.onCancel});

  final CommandLogEntry? last;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final e = last;
    return Material(
      color: theme.colorScheme.surface,
      child: InkWell(
        onTap: onToggle,
        splashFactory: NoSplash.splashFactory,
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant))),
          child: Row(children: [
            _StatusIcon(entry: e),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                e == null ? l10n.logEmpty : e.commandLine,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: e == null ? theme.textTheme.bodySmall : AppFonts.mono.copyWith(fontSize: 11.5),
              ),
            ),
            if (e != null && e.running && onCancel != null)
              TextButton(onPressed: onCancel, child: Text(l10n.commonCancel))
            else if (e?.duration != null)
              Text(_duration(e!.duration!), style: theme.textTheme.bodySmall),
            const SizedBox(width: 4),
            Tooltip(
              message: l10n.logToggleTooltip,
              child: Icon(expanded ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_up_rounded,
                  size: 18, color: theme.colorScheme.onSurfaceVariant),
            ),
          ]),
        ),
      ),
    );
  }
}

String _duration(Duration d) =>
    d.inMilliseconds < 1000 ? '${d.inMilliseconds}ms' : '${(d.inMilliseconds / 1000).toStringAsFixed(1)}s';

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.entry});

  final CommandLogEntry? entry;

  @override
  Widget build(BuildContext context) {
    final e = entry;
    if (e == null) return Icon(Icons.terminal_rounded, size: 14, color: toneColor(context, Tone.neutral));
    if (e.running) {
      return const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2));
    }
    return Icon(
      e.succeeded ? Icons.check_rounded : Icons.close_rounded,
      size: 14,
      color: toneColor(context, e.succeeded ? Tone.success : Tone.danger),
    );
  }
}

class _LogList extends StatelessWidget {
  const _LogList({required this.log});

  final CommandLog log;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final entries = log.entries.reversed.toList();
    return ColoredBox(
      color: theme.colorScheme.surfaceContainerLowest,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, 4, 4, 0),
          child: Row(children: [
            Text(l10n.logTitle, style: theme.textTheme.titleSmall),
            const Spacer(),
            TextButton(onPressed: entries.isEmpty ? null : log.clear, child: Text(l10n.logClear)),
          ]),
        ),
        Expanded(
          child: entries.isEmpty
              ? Center(child: Text(l10n.logEmpty, style: theme.textTheme.bodySmall))
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  itemCount: entries.length,
                  itemBuilder: (context, i) => _LogEntryTile(entry: entries[i], initiallyExpanded: i == 0),
                ),
        ),
      ]),
    );
  }
}

class _LogEntryTile extends StatelessWidget {
  const _LogEntryTile({required this.entry, required this.initiallyExpanded});

  final CommandLogEntry entry;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final failed = !entry.running && !entry.succeeded;
    final output = entry.output.trimRight();
    final time = '${entry.started.hour.toString().padLeft(2, '0')}:'
        '${entry.started.minute.toString().padLeft(2, '0')}:'
        '${entry.started.second.toString().padLeft(2, '0')}';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(color: failed ? theme.colorScheme.error : theme.colorScheme.outlineVariant),
      ),
      child: ExpansionTile(
        key: PageStorageKey(entry),
        initiallyExpanded: initiallyExpanded && output.isNotEmpty,
        dense: true,
        visualDensity: VisualDensity.compact,
        tilePadding: const EdgeInsets.only(left: AppSpacing.sm, right: 4),
        childrenPadding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.sm, AppSpacing.sm),
        shape: const Border(),
        collapsedShape: const Border(),
        leading: _StatusIcon(entry: entry),
        title: Text(entry.commandLine, style: AppFonts.mono.copyWith(fontSize: 11.5)),
        subtitle: Text(
          [time, if (entry.duration != null) _duration(entry.duration!), if (entry.exitCode != null && failed) 'exit ${entry.exitCode}']
              .join(' · '),
          style: theme.textTheme.labelSmall,
        ),
        trailing: CopyButton(text: output.isEmpty ? entry.commandLine : '${entry.commandLine}\n$output'),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (output.isNotEmpty)
            SelectableText(output, style: AppFonts.mono.copyWith(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
