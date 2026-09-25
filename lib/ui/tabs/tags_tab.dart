import 'package:flutter/material.dart';

import '../../core/command_runner.dart';
import '../../git/commands.dart';
import '../../git/commits.dart';
import '../../git/tags.dart';
import '../../l10n/app_localizations.dart';
import '../../release/repo_release_info.dart';
import '../../release/version_files.dart';
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
  const TagsTab({super.key, this.onOpenReleaseWizard});

  final VoidCallback? onOpenReleaseWizard;

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
            onPressed: repo.busy || repo.status.unborn ? null : () => showCreateTagSheet(context, repo, onOpenReleaseWizard: widget.onOpenReleaseWizard),
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

enum _TagMenu { commits, checkout, push, delete, deleteRemote }

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
              PopupMenuItem(value: _TagMenu.commits, child: Text(l10n.tagsCommitsSince)),
              PopupMenuItem(value: _TagMenu.checkout, child: Text(l10n.tagsCheckout)),
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
      case _TagMenu.commits:
        await showTagCommitsSheet(context, repo, tag);
      case _TagMenu.checkout:
        // 태그 위치로 이동 = 분리된 HEAD. 무엇을 뜻하는지 먼저 알린다 (PLAN.md 3.7 P1).
        final command = GitCommands.switchDetach(tag.name);
        final ok = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.tagsCheckoutTitle(tag.name)),
            content: SizedBox(
              width: 360,
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(l10n.tagsCheckoutMessage)),
                  const HelpButton(concept: Concept.detachedHead),
                ]),
                const SizedBox(height: AppSpacing.md),
                CommandPreview(commands: [command]),
              ]),
            ),
            actions: [
              TextButton(autofocus: true, onPressed: () => Navigator.pop(context, false), child: Text(l10n.commonCancel)),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.tagsCheckout)),
            ],
          ),
        );
        if (ok == true && context.mounted) {
          await RepoActions.withStashRetry(context, repo, () => repo.execute(command), done: l10n.doneCheckoutTag(tag.name));
        }
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
/// [onOpenReleaseWizard]: 버전 파일과 맞지 않는 릴리스 태그를 막을 때 보여 줄
/// "릴리스 마법사 열기" 버튼의 동작.
/// [headVersion]을 주면 HEAD의 버전을 다시 읽지 않는다 (테스트에서 미리 읽을 때).
Future<void> showCreateTagSheet(
  BuildContext context,
  RepoController repo, {
  VoidCallback? onOpenReleaseWizard,
  SemVer? headVersion,
  String? target,
}) =>
    showActionSheet<void>(
      context,
      (context) => _CreateTagSheet(
        repo: repo,
        onOpenReleaseWizard: onOpenReleaseWizard,
        headVersion: headVersion,
        target: target,
      ),
    );

/// [ref] 커밋에 커밋된 버전 파일의 버전. 버전 파일이 없으면 null.
Future<SemVer?> loadCommittedVersion(RepoController repo, String ref) async {
  final files = detectVersionFiles(repo.root);
  if (files.isEmpty) return null;
  final f = files.first;
  final r = await repo.read(['git', 'show', '$ref:${f.path}']);
  return r.ok ? readVersion(f.kind, r.stdout) : null;
}

class _CreateTagSheet extends StatefulWidget {
  const _CreateTagSheet({required this.repo, this.onOpenReleaseWizard, this.headVersion, this.target});

  final RepoController repo;
  final VoidCallback? onOpenReleaseWizard;
  final SemVer? headVersion;

  /// 태그를 달 커밋을 정해서 열 때 (기록 탭의 "여기에 태그 달기").
  final String? target;

  @override
  State<_CreateTagSheet> createState() => _CreateTagSheetState();
}

class _CreateTagSheetState extends State<_CreateTagSheet> {
  late final _name = TextEditingController(text: _suggestion());
  late final _message = TextEditingController();
  bool _annotated = true;
  bool _push = true;
  late String? _target = widget.target;

  /// 메시지를 직접 고치기 전까지는 태그 이름을 따라간다 (`<표시 이름> <버전>`).
  bool _messageEdited = false;
  String _autoMessage = '';

  /// 태그를 달 커밋의 버전 파일 버전 (태그 전 점검, PLAN.md 3.8.3 5단계와 같은 규칙).
  /// v0.3.0을 태그 탭에서 버전 올림 없이 달아 CI가 멈춘 일에서 나왔다.
  VersionFile? _versionFile;
  SemVer? _targetVersion;
  late final bool _ciReleases = detectReleaseWorkflows(widget.repo.root).any((w) => w.onTags);

  String _suggestion() {
    final latest = widget.repo.tags.map((t) => t.version).whereType<SemVer>().firstOrNull;
    if (latest == null) return 'v0.1.0';
    return latest.pre != null ? 'v${latest.major}.${latest.minor}.${latest.patch}' : 'v${latest.major}.${latest.minor}.${latest.patch + 1}';
  }

  String _messageFor(String tag) => '${displayNameFor(widget.repo.root, widget.repo.name)} ${tag.replaceFirst('v', '')}';

  @override
  void initState() {
    super.initState();
    _message.text = _autoMessage = _messageFor(_name.text);
    _name.addListener(() {
      if (!_messageEdited) _message.text = _autoMessage = _messageFor(_name.text.trim());
      setState(() {});
    });
    _message.addListener(() {
      if (_message.text != _autoMessage) _messageEdited = true;
      setState(() {});
    });
    final files = detectVersionFiles(widget.repo.root);
    _versionFile = files.isEmpty ? null : files.first;
    _loadTargetVersion();
  }

  /// 대상 커밋에 커밋된 버전 (작업 트리가 아니라 태그가 가리킬 커밋 기준).
  Future<void> _loadTargetVersion() async {
    if (_versionFile == null) return;
    if (_target == null && widget.headVersion != null) {
      _targetVersion = widget.headVersion;
      return;
    }
    final v = await loadCommittedVersion(widget.repo, _target ?? 'HEAD');
    if (mounted) setState(() => _targetVersion = v);
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
    final tagVersion = SemVer.tryParse(name);
    final mismatch = tagVersion != null && _targetVersion != null && tagVersion.name != _targetVersion!.name;
    // 버전이 맞지 않는 릴리스 태그는 push하지 않는다. 로컬에만 만드는 것은 허용.
    final pushBlocked = mismatch && _push && remote != null;
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
      onConfirm: blocking || name.isEmpty || pushBlocked ? null : submit,
      children: [
        if (mismatch) ...[
          _VersionMismatch(
            file: _versionFile!.path,
            fileVersion: _targetVersion!.name,
            tag: name,
            ciReleases: _ciReleases,
            pushBlocked: pushBlocked,
            onOpenReleaseWizard: widget.onOpenReleaseWizard == null
                ? null
                : () {
                    Navigator.pop(context);
                    widget.onOpenReleaseWizard!();
                  },
          ),
          const SizedBox(height: AppSpacing.md),
        ],
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
            if (widget.target != null && !repo.localBranches.any((b) => b.name == widget.target))
              DropdownMenuItem(value: widget.target, child: Text(widget.target!, style: AppFonts.mono.copyWith(fontSize: 12))),
            for (final b in repo.localBranches.where((b) => !b.current))
              DropdownMenuItem(value: b.name, child: Text(b.name, style: AppFonts.userContent)),
          ],
          onChanged: (v) {
            setState(() => _target = v);
            _loadTargetVersion();
          },
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

/// 태그 버전과 버전 파일이 다를 때의 안내 (태그 전 점검).
class _VersionMismatch extends StatelessWidget {
  const _VersionMismatch({
    required this.file,
    required this.fileVersion,
    required this.tag,
    required this.ciReleases,
    required this.pushBlocked,
    this.onOpenReleaseWizard,
  });

  final String file;
  final String fileVersion;
  final String tag;
  final bool ciReleases;
  final bool pushBlocked;
  final VoidCallback? onOpenReleaseWizard;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final color = toneColor(context, Tone.warning);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.warning_amber_rounded, size: 18, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(l10n.tagVersionMismatch(file, fileVersion, tag), style: theme.textTheme.bodyMedium)),
        ]),
        const SizedBox(height: 4),
        Text(
          [
            l10n.tagVersionMismatchWhy,
            if (ciReleases) l10n.tagVersionMismatchCi,
            if (pushBlocked) l10n.tagVersionMismatchBlocked,
          ].join(' '),
          style: theme.textTheme.bodySmall,
        ),
        if (onOpenReleaseWizard != null) ...[
          const SizedBox(height: AppSpacing.sm),
          FilledButton.tonalIcon(
            onPressed: onOpenReleaseWizard,
            icon: const Icon(Icons.rocket_launch_rounded, size: 16),
            label: Text(l10n.tagOpenReleaseWizard),
          ),
        ],
      ]),
    );
  }
}


/// 이전 버전 태그부터 이 태그까지의 커밋 (PLAN.md 3.7 P1).
Future<void> showTagCommitsSheet(BuildContext context, RepoController repo, Tag tag) async {
  final versions = repo.tags.where((t) => t.version != null).toList();
  final i = versions.indexWhere((t) => t.name == tag.name);
  final previous = i >= 0 && i + 1 < versions.length ? versions[i + 1].name : null;
  final r = await repo.read(GitCommands.log(since: previous, until: tag.name));
  if (!context.mounted) return;
  final commits = r.ok ? Commit.parse(r.stdout) : const <Commit>[];
  await showActionSheet<void>(context, (context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.lg),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(previous == null ? l10n.tagsCommitsUpTo(tag.name) : l10n.tagsCommitsBetween(previous, tag.name),
              style: theme.textTheme.titleLarge),
          Text(l10n.tagsCommitsCount(commits.length), style: theme.textTheme.bodySmall),
          const SizedBox(height: AppSpacing.md),
          for (final c in commits)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text.rich(
                TextSpan(children: [
                  TextSpan(text: '${c.shortHash}  ', style: AppFonts.mono.copyWith(fontSize: 11.5)),
                  TextSpan(text: c.subject),
                ]),
                style: theme.textTheme.bodySmall?.merge(AppFonts.userContent),
              ),
            ),
        ]),
      ),
    );
  });
}
