import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/command_log.dart';
import '../../git/commands.dart';
import '../../git/status.dart';
import '../../git/history.dart';
import '../../l10n/app_localizations.dart';
import '../../repo/repo_controller.dart';
import '../../theme/app_theme.dart';
import '../action_sheet.dart';
import '../help/concepts.dart';
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
  bool _stashCollapsed = false;

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

  /// 직전 커밋 고치기 (PLAN.md 3.2 P1).
  bool _amend = false;

  List<List<String>> _commitCommands(RepoController repo) {
    final s = repo.status;
    final message = _message.text.trim();
    final stageAll = s.staged.isEmpty && !s.clean;
    return [
      if (stageAll) GitCommands.stageAll,
      _amend ? GitCommands.amend(message) : GitCommands.commit(message),
    ];
  }

  bool _canCommit(RepoController repo) {
    final s = repo.status;
    if (repo.busy || s.conflicts.isNotEmpty) return false;
    // 고치기는 메시지만 바꿔도 된다. 새 커밋은 메시지와 변경이 모두 있어야 한다.
    if (_amend) return !s.unborn && (_message.text.trim().isNotEmpty || !s.clean);
    return _message.text.trim().isNotEmpty && !s.clean;
  }

  Future<void> _commit(RepoController repo) async {
    final l10n = AppLocalizations.of(context);
    if (!_canCommit(repo)) return;
    final ok = await RepoActions.report(
      context,
      repo.executeAll(_commitCommands(repo)),
      done: _amend ? l10n.doneAmend : l10n.doneCommit,
    );
    if (ok) {
      _message.clear();
      setState(() => _amend = false);
    }
  }

  /// 고치기를 켜면 직전 커밋 메시지를 불러온다.
  Future<void> _toggleAmend(RepoController repo, bool value) async {
    setState(() => _amend = value);
    if (value && _message.text.trim().isEmpty) {
      final r = await repo.read(['git', 'log', '-1', '--format=%B']);
      if (r.ok && mounted && _message.text.trim().isEmpty) _message.text = r.stdout.trim();
    }
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
        // 임시 저장 (PLAN.md 3.2 P1)
        if (repo.stashes.isNotEmpty || !s.clean)
          GroupHeader(
            title: l10n.stashTitle,
            count: repo.stashes.length,
            expanded: !_stashCollapsed,
            onToggle: () => setState(() => _stashCollapsed = !_stashCollapsed),
            action: s.clean
                ? null
                : TextButton(
                    onPressed: repo.busy ? null : () => showStashSheet(context, repo),
                    child: Text(l10n.stashSave),
                  ),
          ),
        if (!_stashCollapsed)
          for (final st in repo.stashes) _StashRow(stash: st, repo: repo),
      ],
    );
  }

  Widget _commitBox(BuildContext context, RepoController repo) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final s = repo.status;
    final firstLine = _message.text.split('\n').first;
    final staged = s.staged.length;
    final canCommit = _canCommit(repo);
    final commitLabel = _amend
        ? l10n.changesAmend
        : (staged > 0 ? l10n.changesCommitStaged(staged) : l10n.changesCommitAll);
    // 이미 원격에 올린 커밋을 고치면 기록이 갈라져 강제 push가 필요하다.
    final amendingPushed = _amend && s.hasUpstream && s.ahead == 0;

    // 안의 CheckboxListTile(직전 커밋 고치기)이 잉크를 그릴 수 있게 Material로 감싼다.
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Material(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.tile),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
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
        if (!s.unborn)
          CheckboxListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _amend,
            onChanged: repo.busy ? null : (v) => _toggleAmend(repo, v ?? false),
            title: Text(l10n.changesAmendToggle),
          ),
        if (amendingPushed)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(l10n.changesAmendPushedWarning,
                style: theme.textTheme.bodySmall?.copyWith(color: toneColor(context, Tone.warning))),
          ),
        Tooltip(
          message: canCommit ? commandsText(_commitCommands(repo)) : '',
          child: FilledButton.icon(
            onPressed: canCommit ? () => _commit(repo) : null,
            icon: const Icon(Icons.check_rounded, size: 16),
            label: Text('$commitLabel  ${shortcutLabel('⏎')}'),
          ),
        ),
      ]),
      ),
      ),
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
      child: GestureDetector(
      onSecondaryTapDown: widget.group == _Group.staged ? null : (d) => _menu(context, d.globalPosition),
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
                if (widget.group != _Group.staged)
                  Builder(
                    builder: (context) => IconButton(
                      tooltip: l10n.commonMore,
                      visualDensity: VisualDensity.compact,
                      iconSize: 16,
                      icon: const Icon(Icons.more_horiz_rounded),
                      onPressed: repo.busy ? null : () => _menu(context, null),
                    ),
                  ),
              ],
            ]),
          ),
        ),
      ),
      ),
    );
  }

  /// 파일 메뉴 (PLAN.md 3.2·3.5 P1): 변경 취소, 추적 안 된 파일 삭제, 충돌에서 한쪽 고르기.
  Future<void> _menu(BuildContext context, Offset? position) async {
    final l10n = AppLocalizations.of(context);
    final repo = widget.repo;
    final f = widget.file;
    final rebasing = repo.operation == RepoOperation.rebasing;
    // rebase 중에는 git의 ours/theirs가 뒤바뀐다: ours = 옮겨 붙일 바탕, theirs = 내 커밋.
    final mine = GitCommands.checkoutSide(f.path, ours: !rebasing);
    final incoming = GitCommands.checkoutSide(f.path, ours: rebasing);
    final items = <PopupMenuEntry<List<List<String>>>>[
      if (widget.group == _Group.conflicts) ...[
        PopupMenuItem(value: [mine, GitCommands.stage(f.path)], child: Text(l10n.conflictUseMine)),
        PopupMenuItem(value: [incoming, GitCommands.stage(f.path)], child: Text(l10n.conflictUseIncoming)),
      ],
      if (widget.group == _Group.unstaged)
        PopupMenuItem(value: [GitCommands.discard(f.path)], child: Text(l10n.changesDiscard)),
      if (widget.group == _Group.untracked)
        PopupMenuItem(value: [GitCommands.removeUntracked(f.path)], child: Text(l10n.changesDeleteUntracked)),
    ];
    if (items.isEmpty) return;
    final box = context.findRenderObject() as RenderBox;
    final origin = position ?? box.localToGlobal(Offset(box.size.width - 40, box.size.height));
    final commands = await showMenu<List<List<String>>>(
      context: context,
      position: RelativeRect.fromLTRB(origin.dx, origin.dy, origin.dx, origin.dy),
      items: items,
    );
    if (commands == null || !context.mounted) return;
    // 변경 취소·삭제는 되돌릴 수 없으므로 확인한다 (ui-ux.md §6).
    if (widget.group != _Group.conflicts) {
      final ok = await confirmDanger(
        context,
        title: widget.group == _Group.untracked ? l10n.changesDeleteUntracked : l10n.changesDiscard,
        message: widget.group == _Group.untracked
            ? l10n.changesDeleteUntrackedMessage(f.path)
            : l10n.changesDiscardMessage(f.path),
        confirm: widget.group == _Group.untracked ? l10n.changesDeleteUntracked : l10n.changesDiscard,
        commands: commands,
      );
      if (!ok || !context.mounted) return;
    }
    await RepoActions.report(context, repo.executeAll(commands), done: l10n.doneFileAction(f.fileName));
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


/// stash 한 줄 (PLAN.md 3.2 P1): 다시 적용 / 적용하고 지우기 / 삭제.
class _StashRow extends StatelessWidget {
  const _StashRow({required this.stash, required this.repo});

  final Stash stash;
  final RepoController repo;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final (:branch, :text) = stash.parts;
    Future<void> run(List<String> command, String done) => RepoActions.report(context, repo.execute(command), done: done);
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.lg, right: 4),
      child: Row(children: [
        Icon(Icons.inventory_2_outlined, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppFonts.userContent.copyWith(fontSize: 13)),
            Text('${stash.ref} · $branch · ${relativeTime(l10n, stash.date)}', style: theme.textTheme.labelSmall),
          ]),
        ),
        PopupMenuButton<String>(
          tooltip: l10n.commonMore,
          icon: const Icon(Icons.more_horiz_rounded, size: 18),
          enabled: !repo.busy,
          onSelected: (v) async {
            switch (v) {
              case 'pop':
                await run(GitCommands.stashPop(stash.ref), l10n.doneStashApplied);
              case 'apply':
                await run(GitCommands.stashApply(stash.ref), l10n.doneStashApplied);
              case 'drop':
                final command = GitCommands.stashDrop(stash.ref);
                final ok = await confirmDanger(
                  context,
                  title: l10n.stashDropTitle,
                  message: l10n.stashDropMessage(text),
                  confirm: l10n.stashDrop,
                  commands: [command],
                );
                if (ok && context.mounted) await run(command, l10n.doneStashDropped);
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(value: 'pop', child: Text(l10n.stashPop)),
            PopupMenuItem(value: 'apply', child: Text(l10n.stashApply)),
            PopupMenuItem(
              value: 'drop',
              child: Text(l10n.stashDrop, style: TextStyle(color: theme.colorScheme.error)),
            ),
          ],
        ),
      ]),
    );
  }
}

/// 지금 변경을 임시 저장 (추적 안 된 파일 포함).
Future<bool> showStashSheet(BuildContext context, RepoController repo) async {
  final saved = await showActionSheet<bool>(context, (context) => _StashSheet(repo: repo));
  return saved ?? false;
}

class _StashSheet extends StatefulWidget {
  const _StashSheet({required this.repo});

  final RepoController repo;

  @override
  State<_StashSheet> createState() => _StashSheetState();
}

class _StashSheetState extends State<_StashSheet> {
  final _message = TextEditingController();

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final command = GitCommands.stashPush(_message.text);
    return ActionSheetBody(
      title: l10n.stashSave,
      help: Concept.stash,
      commands: [command],
      confirmLabel: l10n.stashSave,
      onConfirm: () async {
        final ok = await RepoActions.report(context, widget.repo.execute(command), done: l10n.doneStashSaved);
        if (context.mounted) Navigator.pop(context, ok);
      },
      children: [
        Text(l10n.stashWhy(widget.repo.status.changedCount), style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _message,
          autofocus: true,
          style: AppFonts.userContent.copyWith(fontSize: 13),
          decoration: InputDecoration(labelText: l10n.stashMessageLabel),
        ),
      ],
    );
  }
}
