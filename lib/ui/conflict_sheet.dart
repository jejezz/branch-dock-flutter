import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import '../git/commands.dart';
import '../git/conflicts.dart';
import '../git/status.dart';
import '../l10n/app_localizations.dart';
import '../repo/repo_controller.dart';
import '../theme/app_theme.dart';
import 'action_sheet.dart';
import 'repo_actions.dart';
import 'widgets.dart';

/// 충돌 파일을 구간별로 해결 (PLAN.md 3.5 P1). 구간마다 "내 것 / 들어오는 것 / 둘 다"를 고르면
/// 파일을 그대로 다시 쓰고 `git add` 한다. 직접 고쳐 쓰는 일은 편집기에 맡긴다.
Future<void> showConflictSheet(BuildContext context, RepoController repo, FileChange file) async {
  final path = conflictFilePath(repo, file);
  final text = await readConflictFile(path);
  if (!context.mounted) return;
  await showActionSheet<void>(
    context,
    (context) => _ConflictSheet(repo: repo, file: file, path: path, text: text),
  );
}

String conflictFilePath(RepoController repo, FileChange file) =>
    '${repo.root}${Platform.pathSeparator}${file.path.replaceAll('/', Platform.pathSeparator)}';

/// 파일 내용. 없는 파일, 이진 파일, UTF-8이 아닌 파일은 null.
Future<String?> readConflictFile(String path) async {
  try {
    return utf8.decode(await File(path).readAsBytes());
  } catch (_) {
    return null;
  }
}

class _ConflictSheet extends StatefulWidget {
  const _ConflictSheet({required this.repo, required this.file, required this.path, required this.text});

  final RepoController repo;
  final FileChange file;
  final String path;
  final String? text;

  @override
  State<_ConflictSheet> createState() => _ConflictSheetState();
}

class _ConflictSheetState extends State<_ConflictSheet> {
  late final ConflictFile? _parsed = widget.text == null ? null : ConflictFile.parse(widget.text!);
  late final List<ConflictChoice?> _choices = List.filled(_parsed?.blocks.length ?? 0, null);

  /// rebase 중에는 git의 위/아래가 뒤바뀐다: 위(HEAD)는 옮겨 붙일 바탕, 아래는 내 커밋.
  bool get _swapped => widget.repo.operation == RepoOperation.rebasing;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final parsed = _parsed;
    final title = l10n.conflictSheetTitle(widget.file.fileName);

    String? problem;
    if (widget.text == null) {
      problem = l10n.conflictUnreadable;
    } else if (parsed == null) {
      problem = l10n.conflictBroken;
    } else if (!parsed.hasConflicts) {
      problem = l10n.conflictNone;
    }
    if (problem != null) {
      return ActionSheetBody(
        title: title,
        commands: const [],
        confirmLabel: l10n.changesOpenInEditor,
        onConfirm: () {
          Navigator.pop(context);
          RepoActions.openInEditor(context, widget.repo, widget.file);
        },
        children: [Text(problem, style: theme.textTheme.bodyMedium)],
      );
    }

    final blocks = parsed!.blocks;
    final left = _choices.where((c) => c == null).length;

    Future<void> apply() async {
      final resolved = parsed.resolve([for (final c in _choices) c!]);
      final navigator = Navigator.of(context);
      try {
        await File(widget.path).writeAsString(resolved);
      } on FileSystemException catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
        return;
      }
      if (!context.mounted) return;
      // 시트를 닫으면 이 context는 곧 무효가 되므로, 명령은 닫기 전에 시작한다 (merge_sheet와 같은 순서).
      final staged = widget.repo.stage(widget.file);
      navigator.pop();
      await RepoActions.report(context, staged, done: l10n.doneConflictResolved(widget.file.fileName));
    }

    return ActionSheetBody(
      title: title,
      commands: [GitCommands.stage(widget.file.path)],
      confirmLabel: l10n.conflictApply,
      onConfirm: left == 0 && !widget.repo.busy ? apply : null,
      children: [
        for (var i = 0; i < blocks.length; i++) ...[
          _BlockCard(
            index: i + 1,
            total: blocks.length,
            block: blocks[i],
            swapped: _swapped,
            choice: _choices[i],
            onChoice: (c) => setState(() => _choices[i] = c),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        Text(
          left == 0 ? l10n.conflictApplyNote : l10n.conflictPickHint(left),
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _BlockCard extends StatelessWidget {
  const _BlockCard({
    required this.index,
    required this.total,
    required this.block,
    required this.swapped,
    required this.choice,
    required this.onChoice,
  });

  final int index;
  final int total;
  final ConflictBlock block;
  final bool swapped;
  final ConflictChoice? choice;
  final ValueChanged<ConflictChoice> onChoice;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    // 위쪽(first)이 "내 것"인지는 병합이냐 rebase냐에 따라 다르다.
    final firstName = swapped ? l10n.conflictSideIncoming : l10n.conflictSideMine;
    final secondName = swapped ? l10n.conflictSideMine : l10n.conflictSideIncoming;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(l10n.conflictBlockTitle(index, total), style: theme.textTheme.labelMedium),
      const SizedBox(height: 4),
      _Side(
        name: firstName,
        label: block.firstLabel,
        text: block.first,
        tone: swapped ? Tone.primary : Tone.success,
        selected: choice == ConflictChoice.first,
        onTap: () => onChoice(ConflictChoice.first),
      ),
      const SizedBox(height: 4),
      _Side(
        name: secondName,
        label: block.secondLabel,
        text: block.second,
        tone: swapped ? Tone.success : Tone.primary,
        selected: choice == ConflictChoice.second,
        onTap: () => onChoice(ConflictChoice.second),
      ),
      const SizedBox(height: 4),
      ListTile(
        dense: true,
        contentPadding: const EdgeInsets.only(left: 4),
        leading: Icon(choice == ConflictChoice.both ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
            color: choice == ConflictChoice.both ? theme.colorScheme.primary : null),
        title: Text(l10n.conflictKeepBoth),
        onTap: () => onChoice(ConflictChoice.both),
      ),
    ]);
  }
}

class _Side extends StatelessWidget {
  const _Side({
    required this.name,
    required this.label,
    required this.text,
    required this.tone,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final String label;
  final String text;
  final Tone tone;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final color = toneColor(context, tone);
    final lines = text.isEmpty ? <String>[] : text.replaceAll(RegExp(r'\r?\n$'), '').split(RegExp(r'\r?\n'));
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.button),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: selected ? 0.16 : 0.06),
          borderRadius: BorderRadius.circular(AppRadius.button),
          border: Border.all(color: selected ? color : theme.colorScheme.outlineVariant, width: selected ? 1.5 : 1),
        ),
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                size: 18, color: selected ? color : theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: AppSpacing.sm),
            Text(name, style: theme.textTheme.labelLarge),
            if (label.isNotEmpty) ...[
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.mono.copyWith(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
              ),
            ],
          ]),
          const SizedBox(height: 4),
          if (lines.isEmpty)
            Text(l10n.conflictEmptySide, style: theme.textTheme.bodySmall)
          else
            for (final line in lines.take(12))
              Text(line.isEmpty ? ' ' : line,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.mono.copyWith(fontSize: 11.5, color: theme.colorScheme.onSurface)),
          if (lines.length > 12)
            Text('… +${lines.length - 12}', style: theme.textTheme.bodySmall),
        ]),
      ),
    );
  }
}
