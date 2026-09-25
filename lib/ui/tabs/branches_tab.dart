import 'package:flutter/material.dart';

import '../../core/command_log.dart';
import '../../git/commands.dart';
import '../../git/error_hints.dart';
import '../../git/refs.dart';
import '../../l10n/app_localizations.dart';
import '../../repo/repo_controller.dart';
import '../../theme/app_theme.dart';
import '../action_sheet.dart';
import '../merge_sheet.dart';
import '../repo_actions.dart';
import '../repo_scope.dart';
import '../widgets.dart';
import '../shortcut_label.dart';

/// 브랜치 탭 (UI_UX.md §4.2): 로컬 / 원격, 검색, 전환, 새 브랜치.
class BranchesTab extends StatefulWidget {
  const BranchesTab({super.key});

  @override
  State<BranchesTab> createState() => _BranchesTabState();
}

class _BranchesTabState extends State<BranchesTab> {
  final _filter = TextEditingController();
  bool _localOpen = true;
  bool _remoteOpen = true;

  @override
  void initState() {
    super.initState();
    _filter.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _filter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = RepoScope.of(context);
    final l10n = AppLocalizations.of(context);
    final q = _filter.text.trim().toLowerCase();
    bool match(Branch b) => q.isEmpty || b.name.toLowerCase().contains(q);

    // 현재 브랜치를 맨 위에 둔다.
    final local = repo.localBranches.where(match).toList()
      ..sort(
        (a, b) => a.current ? -1 : (b.current ? 1 : a.name.compareTo(b.name)),
      );
    final remote = repo.remoteBranches.where(match).toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      children: [
        SectionHeader(
          title: l10n.branchesTitle,
          trailing: FilledButton.tonalIcon(
            onPressed: repo.busy || repo.status.unborn
                ? null
                : () => showCreateBranchSheet(context, repo),
            icon: const Icon(Icons.add_rounded, size: 16),
            label: Text(
              '${l10n.branchesNew}  ${shortcutLabel('B')}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: TextField(
            controller: _filter,
            decoration: InputDecoration(
              isDense: true,
              prefixIcon: const Icon(Icons.search_rounded, size: 18),
              hintText: l10n.branchesSearchHint,
            ),
          ),
        ),
        if (repo.status.unborn)
          EmptyState(
            icon: Icons.call_split_rounded,
            title: l10n.branchesUnbornTitle,
            message: l10n.branchesUnbornMessage,
          ),
        GroupHeader(
          title: l10n.branchesLocal,
          count: local.length,
          expanded: _localOpen,
          onToggle: () => setState(() => _localOpen = !_localOpen),
        ),
        if (_localOpen)
          for (final b in local) _BranchRow(branch: b, repo: repo),
        GroupHeader(
          title: l10n.branchesRemote,
          count: remote.length,
          expanded: _remoteOpen,
          onToggle: () => setState(() => _remoteOpen = !_remoteOpen),
        ),
        if (_remoteOpen)
          for (final b in remote) _BranchRow(branch: b, repo: repo),
      ],
    );
  }
}

enum _BranchMenu {
  switchTo,
  mergeIntoCurrent,
  publish,
  rename,
  delete,
  deleteRemote,
}

class _BranchRow extends StatefulWidget {
  const _BranchRow({required this.branch, required this.repo});

  final Branch branch;
  final RepoController repo;

  @override
  State<_BranchRow> createState() => _BranchRowState();
}

class _BranchRowState extends State<_BranchRow> {
  /// 마우스를 올리면 시간 대신 [전환] 버튼을 보여 준다. 더블클릭과 메뉴만으로는
  /// 전환 방법이 보이지 않았다 (v0.2.0 릴리스에서 발견).
  bool _hover = false;

  Branch get branch => widget.branch;
  RepoController get repo => widget.repo;

  Future<void> _switch(BuildContext context) async {
    if (branch.current || repo.busy) return;
    final l10n = AppLocalizations.of(context);
    await RepoActions.report(
      context,
      repo.switchTo(branch),
      done: l10n.doneSwitch(branch.shortName),
    );
  }

  Future<void> _menu(BuildContext context, Offset? position) async {
    final l10n = AppLocalizations.of(context);
    final items = <PopupMenuEntry<_BranchMenu>>[
      if (!branch.current)
        PopupMenuItem(
          value: _BranchMenu.switchTo,
          child: Text(l10n.branchesSwitch),
        ),
      if (!branch.current && !repo.status.detached)
        PopupMenuItem(
          value: _BranchMenu.mergeIntoCurrent,
          child: Text(l10n.branchesMergeInto(repo.status.head ?? '')),
        ),
      if (!branch.remote &&
          (branch.upstream == null || branch.upstreamGone) &&
          repo.remotes.isNotEmpty)
        PopupMenuItem(
          value: _BranchMenu.publish,
          child: Text(l10n.headerPublish),
        ),
      if (!branch.remote)
        PopupMenuItem(
          value: _BranchMenu.rename,
          child: Text(l10n.branchesRename),
        ),
      if (!branch.remote && !branch.current)
        PopupMenuItem(
          value: _BranchMenu.delete,
          child: Text(l10n.branchesDelete),
        ),
      if (branch.remote)
        PopupMenuItem(
          value: _BranchMenu.deleteRemote,
          child: Text(
            l10n.branchesDeleteRemote,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
    ];
    if (items.isEmpty) return;
    final box = context.findRenderObject() as RenderBox;
    final origin =
        position ??
        box.localToGlobal(Offset(box.size.width - 40, box.size.height));
    final choice = await showMenu<_BranchMenu>(
      context: context,
      position: RelativeRect.fromLTRB(
        origin.dx,
        origin.dy,
        origin.dx,
        origin.dy,
      ),
      items: items,
    );
    if (choice == null || !context.mounted) return;
    switch (choice) {
      case _BranchMenu.switchTo:
        await _switch(context);
      case _BranchMenu.mergeIntoCurrent:
        await showMergeSheet(context, repo, branch);
      case _BranchMenu.publish:
        final remote = repo.defaultRemote!;
        await RepoActions.report(
          context,
          repo.execute(GitCommands.publish(remote, branch.name)),
          done: l10n.donePublish(branch.name),
        );
      case _BranchMenu.rename:
        await showRenameBranchSheet(context, repo, branch);
      case _BranchMenu.delete:
        await _deleteLocal(context);
      case _BranchMenu.deleteRemote:
        await _deleteRemote(context);
    }
  }

  Future<void> _deleteLocal(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final result = await repo.execute(GitCommands.deleteBranch(branch.name));
    if (!context.mounted) return;
    if (result.ok) {
      showDone(context, l10n.doneDeleteBranch(branch.name));
      return;
    }
    // 병합되지 않은 커밋이 있으면 무엇을 잃는지 알리고 강제 삭제를 묻는다.
    if (classifyError(result.combined) == GitErrorKind.branchNotMerged) {
      final force = GitCommands.deleteBranch(branch.name, force: true);
      final ok = await confirmDanger(
        context,
        title: l10n.branchesForceDeleteTitle,
        message: l10n.branchesForceDeleteMessage(branch.name),
        confirm: l10n.branchesDelete,
        commands: [force],
      );
      if (ok && context.mounted) {
        await RepoActions.report(
          context,
          repo.execute(force),
          done: l10n.doneDeleteBranch(branch.name),
        );
      }
      return;
    }
    showCommandError(context, result);
  }

  Future<void> _deleteRemote(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final remote = branch.remoteName!;
    final command = GitCommands.deleteRemoteBranch(remote, branch.shortName);
    final target =
        repo.remotes
            .where((r) => r.name == remote)
            .firstOrNull
            ?.location
            ?.webUrl ??
        remote;
    final ok = await confirmDanger(
      context,
      title: l10n.branchesDeleteRemoteTitle,
      message: l10n.branchesDeleteRemoteMessage(branch.shortName, target),
      confirm: l10n.branchesDelete,
      commands: [command],
    );
    if (ok && context.mounted) {
      await RepoActions.report(
        context,
        repo.execute(command),
        done: l10n.doneDeleteBranch(branch.name),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final b = branch;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onSecondaryTapDown: (d) => _menu(context, d.globalPosition),
        child: InkWell(
          splashFactory: NoSplash.splashFactory,
          onDoubleTap: () => _switch(context),
          onTap: () {},
          child: SizedBox(
            height: 40,
            child: Padding(
              padding: const EdgeInsets.only(left: AppSpacing.lg, right: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 14,
                    child: b.current
                        ? Icon(
                            Icons.circle,
                            size: 8,
                            color: theme.colorScheme.primary,
                          )
                        : null,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          b.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppFonts.userContent.copyWith(
                            fontSize: 13,
                            fontWeight: b.current
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: theme.colorScheme.onSurface,
                            decoration: b.upstreamGone
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        if (b.subject.isNotEmpty)
                          Text(
                            b.subject,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.merge(
                              AppFonts.userContent,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (b.upstreamGone)
                    StatusPill(
                      label: l10n.branchesUpstreamGone,
                      tone: Tone.warning,
                    ),
                  if (b.ahead > 0) ...[
                    const SizedBox(width: 4),
                    StatusPill(label: '↑${b.ahead}', tone: Tone.primary),
                  ],
                  if (b.behind > 0) ...[
                    const SizedBox(width: 4),
                    StatusPill(label: '↓${b.behind}', tone: Tone.warning),
                  ],
                  const SizedBox(width: 6),
                  if (_hover && !b.current)
                    SizedBox(
                      height: 28,
                      child: Tooltip(
                        message: formatCommandLine(repo.switchCommand(b)),
                        child: TextButton(
                          onPressed: repo.busy ? null : () => _switch(context),
                          child: Text(l10n.branchesSwitch),
                        ),
                      ),
                    )
                  else
                    Text(
                      relativeTime(l10n, b.lastCommit),
                      style: theme.textTheme.labelSmall,
                    ),
                  Builder(
                    builder: (context) => IconButton(
                      tooltip: l10n.commonMore,
                      visualDensity: VisualDensity.compact,
                      iconSize: 18,
                      icon: const Icon(Icons.more_horiz_rounded),
                      onPressed: repo.busy ? null : () => _menu(context, null),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 새 브랜치 (PLAN.md 3.4): 이름 검사, 접두어 제안, 기준, 만든 뒤 전환.
Future<void> showCreateBranchSheet(BuildContext context, RepoController repo) {
  return showActionSheet<void>(
    context,
    (context) => _CreateBranchSheet(repo: repo),
  );
}

class _CreateBranchSheet extends StatefulWidget {
  const _CreateBranchSheet({required this.repo});

  final RepoController repo;

  @override
  State<_CreateBranchSheet> createState() => _CreateBranchSheetState();
}

class _CreateBranchSheetState extends State<_CreateBranchSheet> {
  final _name = TextEditingController();
  String? _base;
  bool _switchAfter = true;

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final repo = widget.repo;
    final name = _name.text.trim();
    final problem = validateBranchName(name);
    final exists = repo.localBranches.any((b) => b.name == name);
    final error = name.isEmpty
        ? null
        : exists
        ? l10n.branchNameExists
        : problem == null
        ? null
        : branchNameProblemText(l10n, problem);
    final command = GitCommands.createBranch(
      name.isEmpty ? '<name>' : name,
      base: _base,
      switchAfter: _switchAfter,
    );
    final valid = name.isNotEmpty && problem == null && !exists;

    Future<void> submit() async {
      if (!valid) return;
      Navigator.pop(context);
      await RepoActions.report(
        context,
        repo.execute(
          GitCommands.createBranch(
            name,
            base: _base,
            switchAfter: _switchAfter,
          ),
        ),
        done: l10n.doneCreateBranch(name),
      );
    }

    return ActionSheetBody(
      title: l10n.branchesNew,
      commands: [command],
      confirmLabel: l10n.branchesCreate,
      onConfirm: valid ? submit : null,
      children: [
        TextField(
          controller: _name,
          autofocus: true,
          style: AppFonts.userContent.copyWith(fontSize: 13),
          decoration: InputDecoration(
            labelText: l10n.branchNameLabel,
            errorText: error,
          ),
          onSubmitted: (_) => submit(),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: 6,
          children: [
            for (final p in ['feature/', 'fix/', 'docs/', 'chore/'])
              SmallChip(
                label: p,
                onPressed: () {
                  final rest = _name.text.replaceFirst(
                    RegExp(r'^(feature|fix|docs|chore)/'),
                    '',
                  );
                  _name.text = '$p$rest';
                  _name.selection = TextSelection.collapsed(
                    offset: _name.text.length,
                  );
                },
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        DropdownButtonFormField<String?>(
          initialValue: _base,
          isExpanded: true,
          decoration: InputDecoration(labelText: l10n.branchBaseLabel),
          items: [
            DropdownMenuItem(
              value: null,
              child: Text(l10n.branchBaseCurrent(repo.status.head ?? 'HEAD')),
            ),
            for (final b in repo.branches.where((b) => !b.current))
              DropdownMenuItem(
                value: b.name,
                child: Text(b.name, style: AppFonts.userContent),
              ),
          ],
          onChanged: (v) => setState(() => _base = v),
        ),
        const SizedBox(height: AppSpacing.sm),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: _switchAfter,
          onChanged: (v) => setState(() => _switchAfter = v ?? true),
          title: Text(l10n.branchSwitchAfter),
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ],
    );
  }
}

String branchNameProblemText(AppLocalizations l10n, BranchNameProblem p) =>
    switch (p) {
      BranchNameProblem.empty => l10n.branchNameEmpty,
      BranchNameProblem.invalidCharacter => l10n.branchNameInvalidCharacter,
      BranchNameProblem.startsWithDash => l10n.branchNameStartsWithDash,
      BranchNameProblem.invalidSequence => l10n.branchNameInvalidSequence,
      BranchNameProblem.invalidEdge => l10n.branchNameInvalidEdge,
    };

Future<void> showRenameBranchSheet(
  BuildContext context,
  RepoController repo,
  Branch branch,
) {
  return showActionSheet<void>(
    context,
    (context) => _RenameBranchSheet(repo: repo, branch: branch),
  );
}

class _RenameBranchSheet extends StatefulWidget {
  const _RenameBranchSheet({required this.repo, required this.branch});

  final RepoController repo;
  final Branch branch;

  @override
  State<_RenameBranchSheet> createState() => _RenameBranchSheetState();
}

class _RenameBranchSheetState extends State<_RenameBranchSheet> {
  late final _name = TextEditingController(text: widget.branch.name);

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final name = _name.text.trim();
    final problem = validateBranchName(name);
    final exists =
        name != widget.branch.name &&
        widget.repo.localBranches.any((b) => b.name == name);
    final valid = problem == null && !exists && name != widget.branch.name;
    final command = GitCommands.renameBranch(widget.branch.name, name);

    Future<void> submit() async {
      if (!valid) return;
      Navigator.pop(context);
      await RepoActions.report(
        context,
        widget.repo.execute(command),
        done: l10n.doneRenameBranch(name),
      );
    }

    return ActionSheetBody(
      title: l10n.branchesRename,
      commands: [command],
      confirmLabel: l10n.branchesRename,
      onConfirm: valid ? submit : null,
      children: [
        TextField(
          controller: _name,
          autofocus: true,
          style: AppFonts.userContent.copyWith(fontSize: 13),
          decoration: InputDecoration(
            labelText: l10n.branchNameLabel,
            errorText: exists
                ? l10n.branchNameExists
                : (problem == null
                      ? null
                      : branchNameProblemText(l10n, problem)),
          ),
          onSubmitted: (_) => submit(),
        ),
        if (widget.branch.upstream != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.branchRenameUpstreamNote(widget.branch.upstream!),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}
