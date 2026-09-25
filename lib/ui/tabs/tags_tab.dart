import 'package:flutter/material.dart';

import '../../core/command_runner.dart';
import '../../git/commands.dart';
import '../../git/tags.dart';
import '../../l10n/app_localizations.dart';
import '../../release/repo_release_info.dart';
import '../../repo/repo_controller.dart';
import '../../theme/app_theme.dart';
import '../action_sheet.dart';
import '../help/concepts.dart';
import '../repo_actions.dart';
import '../repo_scope.dart';
import '../shortcut_label.dart';
import '../widgets.dart';

/// 태그 탭 (UI_UX.md §4.3, PLAN.md 3.7).
class TagsTab extends StatefulWidget {
  const TagsTab({super.key});

  @override
  State<TagsTab> createState() => _TagsTabState();
}

class _TagsTabState extends State<TagsTab> {
  bool _loadedRemote = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 원격 태그는 네트워크를 쓰므로 탭을 처음 볼 때 한 번 읽는다.
    if (!_loadedRemote) {
      _loadedRemote = true;
      RepoScope.of(context).loadRemoteTags();
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = RepoScope.of(context);
    final l10n = AppLocalizations.of(context);
    final localOnly = repo.remoteTagNames == null ? const <Tag>[] : repo.tags.where((t) => !t.pushed).toList();
    final remote = repo.defaultRemote;

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      children: [
        SectionHeader(
          title: l10n.tagsTitle,
          help: Concept.annotatedTag,
          trailing: FilledButton.tonalIcon(
            onPressed: repo.busy || repo.status.unborn ? null : () => showCreateTagSheet(context, repo),
            icon: const Icon(Icons.add_rounded, size: 16),
            label: Text('${l10n.tagsNew}  ${shortcutLabel('T')}', overflow: TextOverflow.ellipsis),
          ),
        ),
        if (localOnly.isNotEmpty && remote != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
            child: Tooltip(
              message: GitCommands.pushTags(remote, localOnly.map((t) => t.name).toList()).join(' '),
              child: OutlinedButton.icon(
                onPressed: repo.busy
                    ? null
                    : () => RepoActions.report(
                          context,
                          _pushTags(repo, remote, localOnly.map((t) => t.name).toList()),
                          done: l10n.donePushTags(localOnly.length),
                        ),
                icon: const Icon(Icons.cloud_upload_outlined, size: 16),
                label: Text(l10n.tagsPushAll(localOnly.length)),
              ),
            ),
          ),
        if (repo.tags.isEmpty)
          EmptyState(icon: Icons.sell_outlined, title: l10n.tagsEmptyTitle, message: l10n.tagsEmptyMessage)
        else
          for (final t in repo.tags) _TagRow(tag: t, repo: repo, remoteKnown: repo.remoteTagNames != null),
      ],
    );
  }
}

Future<CommandResult> _pushTags(RepoController repo, String remote, List<String> names) async {
  final r = await repo.execute(GitCommands.pushTags(remote, names));
  await repo.loadRemoteTags();
  return r;
}

enum _TagMenu { push, delete, deleteRemote }

class _TagRow extends StatelessWidget {
  const _TagRow({required this.tag, required this.repo, required this.remoteKnown});

  final Tag tag;
  final RepoController repo;
  final bool remoteKnown;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final t = tag;
    final remote = repo.defaultRemote;
    return SizedBox(
      height: 44,
      child: Padding(
        padding: const EdgeInsets.only(left: AppSpacing.lg, right: 4),
        child: Row(children: [
          Tooltip(
            message: !remoteKnown ? '' : (t.pushed ? l10n.tagsPushed : l10n.tagsLocalOnly),
            child: Icon(
              !remoteKnown ? Icons.cloud_outlined : (t.pushed ? Icons.cloud_done_rounded : Icons.cloud_off_rounded),
              size: 16,
              color: t.pushed ? toneColor(context, Tone.success) : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.mono.copyWith(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: t.prerelease ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.onSurface,
                  )),
              Text(
                [t.commit.substring(0, t.commit.length < 7 ? t.commit.length : 7), if (t.subject.isNotEmpty) t.subject]
                    .join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.merge(AppFonts.userContent),
              ),
            ]),
          ),
          if (!t.annotated) ...[StatusPill(label: l10n.tagsLightweight), const SizedBox(width: 4)],
          Text(relativeTime(l10n, t.date), style: theme.textTheme.labelSmall),
          PopupMenuButton<_TagMenu>(
            tooltip: l10n.commonMore,
            icon: const Icon(Icons.more_horiz_rounded, size: 18),
            enabled: !repo.busy,
            onSelected: (m) => _onMenu(context, m),
            itemBuilder: (context) => [
              if (remote != null && !t.pushed) PopupMenuItem(value: _TagMenu.push, child: Text(l10n.tagsPush)),
              PopupMenuItem(value: _TagMenu.delete, child: Text(l10n.tagsDelete)),
              if (remote != null && t.pushed)
                PopupMenuItem(
                  value: _TagMenu.deleteRemote,
                  child: Text(l10n.tagsDeleteRemote, style: TextStyle(color: theme.colorScheme.error)),
                ),
            ],
          ),
        ]),
      ),
    );
  }

  Future<void> _onMenu(BuildContext context, _TagMenu m) async {
    final l10n = AppLocalizations.of(context);
    final remote = repo.defaultRemote;
    switch (m) {
      case _TagMenu.push:
        await RepoActions.report(context, _pushTags(repo, remote!, [tag.name]), done: l10n.donePushTags(1));
      case _TagMenu.delete:
        await RepoActions.report(context, repo.execute(GitCommands.deleteTag(tag.name)),
            done: l10n.doneDeleteTag(tag.name));
      case _TagMenu.deleteRemote:
        final command = GitCommands.deleteRemoteTag(remote!, tag.name);
        final target = repo.remotes.where((r) => r.name == remote).firstOrNull?.location?.webUrl ?? remote;
        final ok = await confirmDanger(
          context,
          title: l10n.tagsDeleteRemoteTitle,
          message: l10n.tagsDeleteRemoteMessage(tag.name, target),
          confirm: l10n.tagsDeleteRemote,
          commands: [command],
        );
        if (ok && context.mounted) {
          await RepoActions.report(
            context,
            () async {
              final r = await repo.execute(command);
              await repo.loadRemoteTags();
              return r;
            }(),
            done: l10n.doneDeleteRemoteTag(tag.name),
          );
        }
    }
  }
}

/// 새 태그 (PLAN.md 3.7): 주석 태그(기본)/가벼운 태그, 대상, 메시지, 이름 검사.
Future<void> showCreateTagSheet(BuildContext context, RepoController repo) =>
    showActionSheet<void>(context, (context) => _CreateTagSheet(repo: repo));

class _CreateTagSheet extends StatefulWidget {
  const _CreateTagSheet({required this.repo});

  final RepoController repo;

  @override
  State<_CreateTagSheet> createState() => _CreateTagSheetState();
}

class _CreateTagSheetState extends State<_CreateTagSheet> {
  late final _name = TextEditingController(text: _suggestion());
  late final _message = TextEditingController();
  bool _annotated = true;
  bool _push = true;
  String? _target;

  String _suggestion() {
    final latest = widget.repo.tags.map((t) => t.version).whereType<SemVer>().firstOrNull;
    if (latest == null) return 'v0.1.0';
    return latest.pre != null ? 'v${latest.major}.${latest.minor}.${latest.patch}' : 'v${latest.major}.${latest.minor}.${latest.patch + 1}';
  }

  @override
  void initState() {
    super.initState();
    _message.text = '${displayNameFor(widget.repo.root, widget.repo.name)} ${_name.text.replaceFirst('v', '')}';
    _name.addListener(() => setState(() {}));
    _message.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final repo = widget.repo;
    final name = _name.text.trim();
    final problem = validateTagName(name);
    final exists = repo.tags.any((t) => t.name == name);
    final blocking = exists || problem == TagNameProblem.empty || problem == TagNameProblem.invalid;
    final warning = switch (problem) {
      TagNameProblem.notSemVer => l10n.tagNameNotSemVer,
      TagNameProblem.missingV => l10n.tagNameMissingV,
      TagNameProblem.invalid => l10n.tagNameInvalid,
      _ => null,
    };
    final remote = repo.defaultRemote;
    final commands = [
      GitCommands.createTag(name.isEmpty ? '<tag>' : name,
          message: _annotated ? _message.text.trim() : null, target: _target),
      if (_push && remote != null) GitCommands.pushTags(remote, [name.isEmpty ? '<tag>' : name]),
    ];

    Future<void> submit() async {
      if (blocking || name.isEmpty) return;
      Navigator.pop(context);
      await RepoActions.report(
        context,
        () async {
          final r = await repo.executeAll(commands);
          if (_push) await repo.loadRemoteTags();
          return r;
        }(),
        done: l10n.doneCreateTag(name),
      );
    }

    return ActionSheetBody(
      title: l10n.tagsNew,
      help: Concept.annotatedTag,
      commands: commands,
      confirmLabel: _push ? l10n.tagsCreateAndPush : l10n.tagsCreate,
      onConfirm: blocking || name.isEmpty ? null : submit,
      children: [
        TextField(
          controller: _name,
          autofocus: true,
          style: AppFonts.mono.copyWith(fontSize: 13),
          decoration: InputDecoration(
            labelText: l10n.tagNameLabel,
            errorText: exists ? l10n.tagNameExists : (problem == TagNameProblem.invalid ? warning : null),
            helperText: exists || problem == TagNameProblem.invalid ? null : warning,
            helperStyle: TextStyle(color: toneColor(context, Tone.warning)),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SegmentedButton<bool>(
          segments: [
            ButtonSegment(value: true, label: Text(l10n.tagsAnnotated)),
            ButtonSegment(value: false, label: Text(l10n.tagsLightweight)),
          ],
          selected: {_annotated},
          onSelectionChanged: (s) => setState(() => _annotated = s.first),
        ),
        if (_annotated) ...[
          const SizedBox(height: AppSpacing.md),
          TextField(controller: _message, decoration: InputDecoration(labelText: l10n.tagMessageLabel)),
        ],
        const SizedBox(height: AppSpacing.md),
        DropdownButtonFormField<String?>(
          initialValue: _target,
          isExpanded: true,
          decoration: InputDecoration(labelText: l10n.tagTargetLabel),
          items: [
            DropdownMenuItem(value: null, child: Text(l10n.tagTargetHead(repo.status.head ?? 'HEAD'))),
            for (final b in repo.localBranches.where((b) => !b.current))
              DropdownMenuItem(value: b.name, child: Text(b.name, style: AppFonts.userContent)),
          ],
          onChanged: (v) => setState(() => _target = v),
        ),
        if (remote != null)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _push,
            onChanged: (v) => setState(() => _push = v ?? true),
            title: Text(l10n.tagsPushAfter(remote)),
          ),
      ],
    );
  }
}
