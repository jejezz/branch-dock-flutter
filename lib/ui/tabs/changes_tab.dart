import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/command_log.dart';
import '../../git/commands.dart';
import '../../git/status.dart';
import '../../l10n/app_localizations.dart';
import '../../repo/repo_controller.dart';
import '../../theme/app_theme.dart';
import '../repo_actions.dart';
import '../repo_scope.dart';
import '../widgets.dart';
import '../shortcut_label.dart';

/// 변경 탭 (UI_UX.md §4.1): 커밋 상자 + 충돌 / 스테이징됨 / 변경됨 / 추적 안 됨.
class ChangesTab extends StatefulWidget {
  const ChangesTab({super.key, required this.commitFocus});

  /// ⌘Enter와 탭 전환 후 커밋 메시지로 바로 가기 위한 포커스.
  final FocusNode commitFocus;

  @override
  State<ChangesTab> createState() => _ChangesTabState();
}

enum _Group { conflicts, staged, unstaged, untracked }

class _ChangesTabState extends State<ChangesTab> {
  final _message = TextEditingController();
  final _collapsed = <_Group>{};

  static const _prefixes = ['feat', 'fix', 'docs', 'chore', 'refactor', 'test'];

  @override
  void initState() {
    super.initState();
    _message.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  /// Conventional Commit 접두어를 붙이거나 바꾼다.
  void _applyPrefix(String prefix) {
    final text = _message.text;
    final m = RegExp(r'^[a-z]+(\([^)]*\))?!?: ?').firstMatch(text);
    final rest = m == null ? text : text.substring(m.end);
    _message.value = TextEditingValue(
      text: '$prefix: $rest',
      selection: TextSelection.collapsed(offset: '$prefix: $rest'.length),
    );
    widget.commitFocus.requestFocus();
  }

  Future<void> _commit(RepoController repo) async {
    final l10n = AppLocalizations.of(context);
    final message = _message.text.trim();
    final s = repo.status;
    if (message.isEmpty || repo.busy || s.clean) return;
    final stageAll = s.staged.isEmpty;
    final ok = await RepoActions.report(
      context,
      repo.commit(message, stageAllFirst: stageAll),
      done: l10n.doneCommit,
    );
    if (ok) _message.clear();
  }

  @override
  Widget build(BuildContext context) {
    final repo = RepoScope.of(context);
    final l10n = AppLocalizations.of(context);
    final s = repo.status;

    final groups = <(_Group, String, List<FileChange>, Tone)>[
      (_Group.conflicts, l10n.changesConflicts, s.conflicts.toList(), Tone.danger),
      (_Group.staged, l10n.changesStaged, s.staged.toList(), Tone.success),
      (_Group.unstaged, l10n.changesUnstaged, s.unstaged.toList(), Tone.neutral),
      (_Group.untracked, l10n.changesUntracked, s.untracked.toList(), Tone.neutral),
    ];

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      children: [
        _commitBox(context, repo),
        if (s.clean)
          EmptyState(
            icon: Icons.check_circle_outline_rounded,
            title: l10n.changesCleanTitle,
            message: l10n.changesCleanMessage,
          ),
        for (final (group, title, files, tone) in groups)
          if (files.isNotEmpty) ...[
            GroupHeader(
              title: title,
              count: files.length,
              tone: tone,
              expanded: !_collapsed.contains(group),
              onToggle: () => setState(() => _collapsed.contains(group) ? _collapsed.remove(group) : _collapsed.add(group)),
              action: switch (group) {
                _Group.staged => TextButton(
                    onPressed: repo.busy ? null : () => repo.unstageAll(),
                    child: Text(l10n.changesUnstageAll),
                  ),
                _Group.unstaged || _Group.untracked => TextButton(
                    onPressed: repo.busy ? null : () => repo.stageAll(),
                    child: Text(l10n.changesStageAll),
                  ),
                _Group.conflicts => null,
              },
            ),
            if (!_collapsed.contains(group))
              for (final f in files) _FileRow(file: f, group: group, repo: repo),
          ],
      ],
    );
  }

  Widget _commitBox(BuildContext context, RepoController repo) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final s = repo.status;
    final firstLine = _message.text.split('\n').first;
    final staged = s.staged.length;
    final canCommit = _message.text.trim().isNotEmpty && !s.clean && !repo.busy && s.conflicts.isEmpty;
    final commitLabel = staged > 0 ? l10n.changesCommitStaged(staged) : l10n.changesCommitAll;

    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.tile),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final p in _prefixes)
            SmallChip(label: p, tooltip: l10n.changesPrefixTooltip, onPressed: () => _applyPrefix(p)),
        ]),
        const SizedBox(height: AppSpacing.sm),
        CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.enter, meta: true): () => _commit(repo),
            const SingleActivator(LogicalKeyboardKey.enter, control: true): () => _commit(repo),
          },
          child: TextField(
            controller: _message,
            focusNode: widget.commitFocus,
            minLines: 2,
            maxLines: 6,
            style: AppFonts.userContent.copyWith(fontSize: 13),
            decoration: InputDecoration(
              hintText: l10n.changesMessageHint,
              isDense: true,
              helperText: firstLine.length > 72 ? l10n.changesFirstLineLong(firstLine.length) : null,
              helperStyle: TextStyle(color: toneColor(context, Tone.warning)),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Tooltip(
          message: canCommit
              ? commandsText([if (staged == 0) GitCommands.stageAll, GitCommands.commit(_message.text.trim())])
              : '',
          child: FilledButton.icon(
            onPressed: canCommit ? () => _commit(repo) : null,
            icon: const Icon(Icons.check_rounded, size: 16),
            label: Text('$commitLabel  ${shortcutLabel('⏎')}'),
          ),
        ),
      ]),
    );
  }
}

String commandsText(List<List<String>> commands) => commands.map(formatCommandLine).join('\n');

class _FileRow extends StatefulWidget {
  const _FileRow({required this.file, required this.group, required this.repo});

  final FileChange file;
  final _Group group;
  final RepoController repo;

  @override
  State<_FileRow> createState() => _FileRowState();
}

class _FileRowState extends State<_FileRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final f = widget.file;
    final repo = widget.repo;
    final (letter, tone) = switch (widget.group) {
      _Group.conflicts => ('U', Tone.danger),
      _Group.untracked => ('?', Tone.neutral),
      _Group.staged => _kindLetter(f.stagedKind),
      _Group.unstaged => _kindLetter(f.unstagedKind),
    };
    final staging = widget.group != _Group.staged;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: InkWell(
        splashFactory: NoSplash.splashFactory,
        onDoubleTap: () => RepoActions.openInEditor(context, repo, f),
        onTap: () {},
        child: SizedBox(
          height: 36,
          child: Padding(
            padding: const EdgeInsets.only(left: AppSpacing.lg, right: AppSpacing.sm),
            child: Row(children: [
              Container(
                width: 20,
                height: 20,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: toneColor(context, tone).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.iconChip),
                ),
                child: Text(letter,
                    style: AppFonts.mono.copyWith(
                        fontSize: 11, fontWeight: FontWeight.w700, color: toneColor(context, tone))),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Tooltip(
                  message: f.originalPath == null ? f.path : '${f.originalPath} → ${f.path}',
                  waitDuration: const Duration(milliseconds: 600),
                  child: Text.rich(
                    TextSpan(children: [
                      TextSpan(text: f.fileName, style: const TextStyle(fontWeight: FontWeight.w600)),
                      if (f.directory.isNotEmpty)
                        TextSpan(text: '  ${f.directory}', style: theme.textTheme.bodySmall),
                    ]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.userContent.copyWith(fontSize: 13, color: theme.colorScheme.onSurface),
                  ),
                ),
              ),
              if (_hover || widget.group == _Group.conflicts) ...[
                IconButton(
                  tooltip: l10n.changesOpenInEditor,
                  visualDensity: VisualDensity.compact,
                  iconSize: 16,
                  icon: const Icon(Icons.open_in_new_rounded),
                  onPressed: () => RepoActions.openInEditor(context, repo, f),
                ),
                if (widget.group == _Group.conflicts)
                  TextButton(
                    onPressed: repo.busy ? null : () => repo.stage(f),
                    child: Text(l10n.changesMarkResolved),
                  )
                else
                  IconButton(
                    tooltip: staging ? l10n.changesStage : l10n.changesUnstage,
                    visualDensity: VisualDensity.compact,
                    iconSize: 18,
                    icon: Icon(staging ? Icons.add_rounded : Icons.remove_rounded),
                    onPressed: repo.busy ? null : () => staging ? repo.stage(f) : repo.unstage(f),
                  ),
              ],
            ]),
          ),
        ),
      ),
    );
  }

  static (String, Tone) _kindLetter(ChangeKind k) => switch (k) {
        ChangeKind.added => ('A', Tone.success),
        ChangeKind.deleted => ('D', Tone.danger),
        ChangeKind.renamed || ChangeKind.copied => ('R', Tone.primary),
        ChangeKind.typeChanged => ('T', Tone.neutral),
        ChangeKind.unmerged => ('U', Tone.danger),
        ChangeKind.untracked => ('?', Tone.neutral),
        ChangeKind.modified => ('M', Tone.primary),
      };
}
