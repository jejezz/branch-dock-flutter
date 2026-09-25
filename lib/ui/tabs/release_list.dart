import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../git/commands.dart';
import '../../git/tags.dart';
import '../../github/models.dart';
import '../../l10n/app_localizations.dart';
import '../../repo/repo_controller.dart';
import '../../theme/app_theme.dart';
import '../action_sheet.dart';
import '../markdown_editor.dart';
import '../repo_actions.dart';
import '../widgets.dart';

/// 릴리스 관리 (PLAN.md 3.8.6): 목록, 노트 수정, 프리릴리스 ↔ 정식, 초안 게시, 삭제.
class ReleaseList extends StatefulWidget {
  const ReleaseList({super.key, required this.repo});

  final RepoController repo;

  @override
  State<ReleaseList> createState() => _ReleaseListState();
}

class _ReleaseListState extends State<ReleaseList> {
  List<ReleaseSummary>? _releases;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final r = await widget.repo.read(GhCommands.releaseList());
    if (!mounted) return;
    setState(() {
      _failed = !r.ok;
      _releases = r.ok ? ReleaseSummary.parseList(r.stdout) : const [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final releases = _releases;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.sm, 0),
        child: Row(children: [
          Text(l10n.releasesTitle, style: theme.textTheme.titleSmall),
          const Spacer(),
          IconButton(
            tooltip: l10n.appBarRefresh,
            iconSize: 16,
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
          ),
        ]),
      ),
      if (releases == null)
        const Padding(padding: EdgeInsets.all(AppSpacing.lg), child: Center(child: CircularProgressIndicator()))
      else if (_failed)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Text(l10n.releasesLoadFailed, style: theme.textTheme.bodySmall),
        )
      else if (releases.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Text(l10n.releasesEmpty, style: theme.textTheme.bodySmall),
        )
      else
        for (final r in releases) _ReleaseRow(release: r, repo: widget.repo, onChanged: _load),
    ]);
  }
}

enum _ReleaseMenu { notes, open, togglePrerelease, publishDraft, rollback, delete }

class _ReleaseRow extends StatelessWidget {
  const _ReleaseRow({required this.release, required this.repo, required this.onChanged});

  final ReleaseSummary release;
  final RepoController repo;
  final VoidCallback onChanged;

  Future<void> _run(BuildContext context, List<String> command, String done) async {
    final ok = await RepoActions.report(context, repo.execute(command), done: done);
    if (ok) onChanged();
  }

  Future<void> _onMenu(BuildContext context, _ReleaseMenu m) async {
    final l10n = AppLocalizations.of(context);
    final r = release;
    switch (m) {
      case _ReleaseMenu.notes:
        await showReleaseNotesSheet(context, repo, r.tag, onSaved: onChanged);
      case _ReleaseMenu.open:
        final view = await repo.read(GhCommands.releaseView(r.tag));
        final url = GitHubRelease.parse(view.stdout)?.url;
        if (url != null) await launchUrl(Uri.parse(url));
      case _ReleaseMenu.togglePrerelease:
        await _run(
          context,
          GhCommands.releaseSetPrerelease(r.tag, !r.prerelease),
          r.prerelease ? l10n.doneReleaseMadeFinal(r.tag) : l10n.doneReleaseMadePrerelease(r.tag),
        );
      case _ReleaseMenu.publishDraft:
        await _run(context, GhCommands.releasePublishDraft(r.tag), l10n.doneReleasePublished(r.tag));
      case _ReleaseMenu.rollback:
        if (await showRollbackDialog(context, repo, r.tag, hasRelease: true)) onChanged();
      case _ReleaseMenu.delete:
        await _delete(context);
    }
  }

  /// 릴리스 삭제는 되돌릴 수 없어 태그 이름을 입력해야 지운다 (v0.6.1).
  Future<void> _delete(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    var cleanupTag = false;
    final ok = await confirmTyped(
      context,
      title: l10n.releaseDeleteTitle(release.tag),
      message: l10n.releaseDeleteMessage,
      expected: release.tag,
      confirm: l10n.releaseDelete,
      commands: [GhCommands.releaseDelete(release.tag)],
      extra: StatefulBuilder(
        builder: (context, setState) => CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: cleanupTag,
          onChanged: (v) => setState(() => cleanupTag = v ?? false),
          title: Text(l10n.releaseDeleteTagToo(release.tag)),
        ),
      ),
    );
    if (ok && context.mounted) {
      await _run(context, GhCommands.releaseDelete(release.tag, cleanupTag: cleanupTag), l10n.doneReleaseDeleted(release.tag));
      if (cleanupTag) await repo.loadRemoteTags();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final r = release;
    return InkWell(
      onTap: () => showReleaseNotesSheet(context, repo, r.tag, onSaved: onChanged),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 4, 4, 4),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.name.isEmpty ? r.tag : r.name,
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyMedium?.merge(AppFonts.userContent)),
              const SizedBox(height: 2),
              Wrap(spacing: 4, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
                Text(r.tag, style: AppFonts.mono.copyWith(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
                if (r.latest) StatusPill(label: l10n.releaseLatestPill, tone: Tone.success),
                if (r.prerelease) StatusPill(label: l10n.releasePrerelease, tone: Tone.warning),
                if (r.draft) StatusPill(label: l10n.releaseDraft),
              ]),
            ]),
          ),
          Text(relativeTime(l10n, r.published), style: theme.textTheme.labelSmall),
          PopupMenuButton<_ReleaseMenu>(
            tooltip: l10n.commonMore,
            icon: const Icon(Icons.more_horiz_rounded, size: 18),
            enabled: !repo.busy,
            onSelected: (m) => _onMenu(context, m),
            itemBuilder: (context) => [
              PopupMenuItem(value: _ReleaseMenu.notes, child: Text(l10n.notesEdit)),
              PopupMenuItem(value: _ReleaseMenu.open, child: Text(l10n.ciOpenInBrowser)),
              if (r.draft)
                PopupMenuItem(value: _ReleaseMenu.publishDraft, child: Text(l10n.releasePublishDraft))
              else
                PopupMenuItem(
                  value: _ReleaseMenu.togglePrerelease,
                  child: Text(r.prerelease ? l10n.releaseMakeFinal : l10n.releaseMakePrerelease),
                ),
              PopupMenuItem(
                value: _ReleaseMenu.rollback,
                child: Text(l10n.rollbackTitle, style: TextStyle(color: theme.colorScheme.error)),
              ),
              PopupMenuItem(
                value: _ReleaseMenu.delete,
                child: Text(l10n.releaseDelete, style: TextStyle(color: theme.colorScheme.error)),
              ),
            ],
          ),
        ]),
      ),
    );
  }
}

/// 릴리스 노트 보기·고치기: 현재 노트를 읽어 편집기에 넣는다.
Future<void> showReleaseNotesSheet(BuildContext context, RepoController repo, String tag, {VoidCallback? onSaved}) async {
  final view = await repo.read(GhCommands.releaseView(tag));
  if (!context.mounted) return;
  final release = GitHubRelease.parse(view.stdout);
  if (release == null) {
    showCommandError(context, view);
    return;
  }
  await showActionSheet<void>(context, (context) => _NotesSheet(repo: repo, release: release, onSaved: onSaved));
}

class _NotesSheet extends StatefulWidget {
  const _NotesSheet({required this.repo, required this.release, this.onSaved});

  final RepoController repo;
  final GitHubRelease release;
  final VoidCallback? onSaved;

  @override
  State<_NotesSheet> createState() => _NotesSheetState();
}

class _NotesSheetState extends State<_NotesSheet> {
  late final _notes = TextEditingController(text: widget.release.body);

  @override
  void initState() {
    super.initState();
    _notes.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final r = widget.release;
    final changed = _notes.text != r.body;
    return ActionSheetBody(
      title: r.name.isEmpty ? r.tag : r.name,
      commands: [GhCommands.releaseEditNotes(r.tag)],
      confirmLabel: l10n.commonSave,
      onConfirm: !changed
          ? null
          : () async {
              Navigator.pop(context);
              final ok = await RepoActions.report(
                context,
                widget.repo.execute(GhCommands.releaseEditNotes(r.tag), stdin: _notes.text),
                done: l10n.doneNotesSaved,
              );
              if (ok) widget.onSaved?.call();
            },
      children: [
        ReleaseAssets(repo: widget.repo, release: r),
        const SizedBox(height: AppSpacing.md),
        MarkdownEditor(controller: _notes, label: l10n.notesLabel),
      ],
    );
  }
}

/// 릴리스 산출물 (PLAN.md 3.8 P2): 파일 목록과 받기 · 올리기 · 삭제.
/// CI가 올린 빌드 결과물 옆에 손으로 파일을 더하거나 잘못 올린 것을 지울 때 쓴다.
class ReleaseAssets extends StatefulWidget {
  const ReleaseAssets({super.key, required this.repo, required this.release});

  final RepoController repo;
  final GitHubRelease release;

  @override
  State<ReleaseAssets> createState() => _ReleaseAssetsState();
}

class _ReleaseAssetsState extends State<ReleaseAssets> {
  late List<ReleaseAsset> _assets = widget.release.assets;

  String get _tag => widget.release.tag;

  Future<void> _reload() async {
    final r = await widget.repo.read(GhCommands.releaseView(_tag));
    final release = r.ok ? GitHubRelease.parse(r.stdout) : null;
    if (mounted && release != null) setState(() => _assets = release.assets);
  }

  Future<void> _download(ReleaseAsset a) async {
    final l10n = AppLocalizations.of(context);
    final dir = await getDirectoryPath(confirmButtonText: l10n.assetDownload);
    if (dir == null || !mounted) return;
    await RepoActions.report(
      context,
      widget.repo.execute(GhCommands.releaseDownload(_tag, a.name, dir)),
      done: l10n.doneAssetDownloaded(a.name),
    );
  }

  Future<void> _upload() async {
    final l10n = AppLocalizations.of(context);
    final files = await openFiles(confirmButtonText: l10n.assetUpload);
    if (files.isEmpty || !mounted) return;
    final paths = [for (final f in files) f.path];
    final names = {for (final a in _assets) a.name};
    final clashes = [for (final f in files) if (names.contains(f.name)) f.name];
    final command = GhCommands.releaseUpload(_tag, paths, replace: clashes.isNotEmpty);
    // 같은 이름을 덮어쓰면 이미 받아 간 사람과 내용이 달라진다. 한 번 더 묻는다.
    if (clashes.isNotEmpty) {
      final ok = await confirmDanger(
        context,
        title: l10n.assetReplaceTitle,
        message: l10n.assetReplaceMessage(clashes.join(', ')),
        confirm: l10n.assetReplace,
        commands: [command],
      );
      if (!ok || !mounted) return;
    }
    final ok = await RepoActions.report(
      context,
      widget.repo.execute(command),
      done: l10n.doneAssetUploaded(files.length),
    );
    if (ok) await _reload();
  }

  Future<void> _delete(ReleaseAsset a) async {
    final l10n = AppLocalizations.of(context);
    final command = GhCommands.releaseDeleteAsset(_tag, a.name);
    final ok = await confirmDanger(
      context,
      title: l10n.assetDeleteTitle(a.name),
      message: l10n.assetDeleteMessage,
      confirm: l10n.commonDelete,
      commands: [command],
    );
    if (!ok || !mounted) return;
    final done = await RepoActions.report(context, widget.repo.execute(command), done: l10n.doneAssetDeleted(a.name));
    if (done) await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    // 시트는 탭과 따로 그려지므로 실행 중 여부를 직접 듣는다.
    return ListenableBuilder(listenable: widget.repo, builder: (context, _) => _build(context, l10n, theme));
  }

  Widget _build(BuildContext context, AppLocalizations l10n, ThemeData theme) {
    final busy = widget.repo.busy;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Expanded(child: Text(l10n.assetTitle(_assets.length), style: theme.textTheme.labelMedium)),
        TextButton.icon(
          onPressed: busy ? null : _upload,
          icon: const Icon(Icons.upload_rounded, size: 16),
          label: Text(l10n.assetUpload),
        ),
      ]),
      if (_assets.isEmpty) Text(l10n.assetEmpty, style: theme.textTheme.bodySmall),
      for (final a in _assets)
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(a.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppFonts.mono.copyWith(fontSize: 11.5)),
              Text(l10n.assetMeta(formatSize(a.size), a.downloads), style: theme.textTheme.labelSmall),
            ]),
          ),
          IconButton(
            tooltip: l10n.assetDownload,
            onPressed: busy ? null : () => _download(a),
            icon: const Icon(Icons.download_rounded, size: 18),
          ),
          IconButton(
            tooltip: l10n.commonDelete,
            onPressed: busy ? null : () => _delete(a),
            icon: Icon(Icons.delete_outline_rounded, size: 18, color: theme.colorScheme.error),
          ),
        ]),
    ]);
  }
}

/// 1.2 MB, 340 KB처럼 읽기 쉬운 크기.
String formatSize(int bytes) {
  if (bytes >= 1024 * 1024) return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  return '$bytes B';
}

/// 잘못 단 릴리스 되돌리기 (PLAN.md 3.8.7 P1): GitHub 릴리스 → 원격 태그 →
/// 로컬 태그를 한 번에 지운다. 이미 받아 간 사람이 있을 수 있으니 같은 번호를
/// 다시 쓰지 말고 다음 번호로 새로 릴리스하라고 권한다. 되돌렸으면 true.
Future<bool> showRollbackDialog(BuildContext context, RepoController repo, String tag, {bool? hasRelease}) async {
  final l10n = AppLocalizations.of(context);
  final remote = repo.githubRemote?.name ?? repo.defaultRemote;
  var release = hasRelease ?? false;
  if (hasRelease == null && repo.githubRemote != null) {
    release = (await repo.read(GhCommands.releaseView(tag))).ok;
    if (!context.mounted) return false;
  }
  final pushed = repo.remoteTagNames?.contains(tag) ?? true;
  final local = repo.tags.any((t) => t.name == tag);
  final commands = [
    if (release) GhCommands.releaseDelete(tag),
    if (remote != null && pushed) GitCommands.deleteRemoteTag(remote, tag),
    if (local) GitCommands.deleteTag(tag),
  ];
  if (commands.isEmpty) return false;
  final next = SemVer.tryParse(tag);
  final ok = await confirmTyped(
    context,
    title: l10n.rollbackConfirmTitle(tag),
    message: l10n.rollbackMessage(next == null ? '' : 'v${next.major}.${next.minor}.${next.patch + 1}'),
    expected: tag,
    confirm: l10n.rollbackTitle,
    commands: commands,
  );
  if (!ok || !context.mounted) return false;
  final done = await RepoActions.report(
    context,
    () async {
      final r = await repo.executeAll(commands);
      await repo.loadRemoteTags();
      return r;
    }(),
    done: l10n.doneRollback(tag),
  );
  return done;
}
