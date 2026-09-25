import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../git/commands.dart';
import '../../git/remotes.dart';
import '../../github/onboarding.dart';
import '../../l10n/app_localizations.dart';
import '../../repo/environment.dart';
import '../../repo/repo_controller.dart';
import '../../theme/app_theme.dart';
import '../action_sheet.dart';
import '../merge_sheet.dart';
import '../repo_actions.dart';
import '../repo_scope.dart';
import '../widgets.dart';

/// 원격 탭 (UI_UX.md §4.4).
class RemotesTab extends StatefulWidget {
  const RemotesTab({super.key});

  @override
  State<RemotesTab> createState() => _RemotesTabState();
}

class _RemotesTabState extends State<RemotesTab> {
  /// fork 정보와 gh 기본 저장소 (PLAN.md 3.6 P1). GitHub 원격과 gh가 있을 때만 읽는다.
  ForkInfo? _fork;
  String? _ghDefault;
  String? _loadedFor;

  Future<void> _load(RepoController repo) async {
    _loadedFor = repo.root;
    final results = await Future.wait([repo.read(GhCommands.repoViewFork), repo.read(GhCommands.setDefaultView)]);
    if (!mounted) return;
    setState(() {
      _fork = results[0].ok ? ForkInfo.parse(results[0].stdout) : null;
      _ghDefault = results[1].ok ? results[1].stdout.trim() : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final repo = RepoScope.of(context);
    final env = RepoScope.environmentOf(context);
    final l10n = AppLocalizations.of(context);
    final hasGitHub = repo.githubRemote != null;
    if (hasGitHub && env.ghReady && _loadedFor != repo.root) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _load(repo);
      });
    }
    final githubRemotes = repo.remotes.where((r) => r.isGitHub).toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      children: [
        SectionHeader(
          title: l10n.remotesTitle,
          trailing: FilledButton.tonalIcon(
            onPressed: repo.busy ? null : () => showRemoteSheet(context, repo),
            icon: const Icon(Icons.add_rounded, size: 16),
            label: Text(l10n.remotesAdd, overflow: TextOverflow.ellipsis),
          ),
        ),
        if (_fork != null && _fork!.isFork) ForkCard(fork: _fork!, repo: repo),
        if (githubRemotes.length > 1)
          _DefaultRepoRow(
            repo: repo,
            current: _ghDefault,
            options: [for (final r in githubRemotes) ?r.location?.path],
            onChanged: () => _load(repo),
          ),
        if (repo.remotes.isEmpty)
          EmptyState(
            icon: Icons.cloud_upload_outlined,
            title: l10n.remotesEmptyTitle,
            message: env.ghReady ? l10n.remotesEmptyMessage : ghUnavailableText(l10n, env),
            action: FilledButton.icon(
              onPressed: env.ghReady && !repo.busy ? () => showPublishToGitHubSheet(context, repo) : null,
              icon: const Icon(Icons.cloud_upload_rounded, size: 16),
              label: Text(l10n.remotesPublishToGitHub),
            ),
          )
        else ...[
          for (final r in repo.remotes) _RemoteCard(remote: r, repo: repo),
          if (!hasGitHub)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: OutlinedButton.icon(
                onPressed: env.ghReady && !repo.busy ? () => showPublishToGitHubSheet(context, repo) : null,
                icon: const Icon(Icons.cloud_upload_rounded, size: 16),
                label: Text(l10n.remotesPublishAlsoToGitHub),
              ),
            ),
        ],
      ],
    );
  }
}

/// fork 저장소 (PLAN.md 3.6 P1): 원본을 upstream으로 추가하고, upstream에서
/// 새 커밋을 가져와 현재 브랜치로 병합한다.
class ForkCard extends StatelessWidget {
  const ForkCard({super.key, required this.fork, required this.repo});

  final ForkInfo fork;
  final RepoController repo;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final upstream = repo.remotes.where((r) => r.name == 'upstream').firstOrNull;
    final add = GitCommands.remoteAdd('upstream', fork.parentUrl!);
    final fetch = [GitCommands.fetch(remote: 'upstream'), GitCommands.remoteSetHeadAuto('upstream')];
    return Container(
      margin: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.tile),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Icon(Icons.fork_right_rounded, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(l10n.forkTitle(fork.parent!), style: theme.textTheme.titleSmall)),
        ]),
        const SizedBox(height: 4),
        Text(upstream == null ? l10n.forkAddWhy : l10n.forkSyncWhy, style: theme.textTheme.bodySmall),
        const SizedBox(height: AppSpacing.sm),
        CommandPreview(commands: upstream == null ? [add] : fetch),
        const SizedBox(height: AppSpacing.sm),
        Align(
          alignment: Alignment.centerRight,
          child: upstream == null
              ? FilledButton(
                  onPressed: repo.busy
                      ? null
                      : () => RepoActions.report(context, repo.execute(add), done: l10n.doneAddRemote('upstream')),
                  child: Text(l10n.forkAddUpstream),
                )
              : FilledButton(
                  onPressed: repo.busy ? null : () => _sync(context),
                  child: Text(l10n.forkSync),
                ),
        ),
      ]),
    );
  }

  /// upstream을 가져오고, upstream의 기본 브랜치를 현재 브랜치로 병합하는 시트를 연다.
  Future<void> _sync(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final ok = await RepoActions.report(
      context,
      repo.executeAll([GitCommands.fetch(remote: 'upstream'), GitCommands.remoteSetHeadAuto('upstream')]),
      done: l10n.doneFetch,
    );
    if (!ok || !context.mounted) return;
    final head = await repo.read(GitCommands.remoteHead('upstream'));
    final name = head.ok ? head.stdout.trim() : 'upstream/${repo.defaultBranch ?? 'main'}';
    final branch = repo.remoteBranches.where((b) => b.name == name).firstOrNull;
    if (branch == null || !context.mounted) return;
    await showMergeSheet(context, repo, branch);
  }
}

/// 원격이 여러 개일 때 gh가 쓸 저장소 (`gh repo set-default`).
class _DefaultRepoRow extends StatelessWidget {
  const _DefaultRepoRow({required this.repo, required this.current, required this.options, required this.onChanged});

  final RepoController repo;
  final String? current;
  final List<String> options;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final value = options.contains(current) ? current : null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.md, AppSpacing.sm),
      child: Row(children: [
        Expanded(child: Text(l10n.remotesGhDefault, style: theme.textTheme.bodySmall)),
        DropdownButton<String>(
          value: value,
          hint: Text(l10n.remotesGhDefaultNone, style: theme.textTheme.bodySmall),
          underline: const SizedBox.shrink(),
          items: [for (final o in options) DropdownMenuItem(value: o, child: Text(o, style: AppFonts.mono.copyWith(fontSize: 12)))],
          onChanged: repo.busy
              ? null
              : (v) async {
                  if (v == null) return;
                  final ok = await RepoActions.report(context, repo.execute(GhCommands.setDefault(v)), done: l10n.doneGhDefault(v));
                  if (ok) onChanged();
                },
        ),
      ]),
    );
  }
}

String hostLabel(AppLocalizations l10n, RemoteHost host) => switch (host) {
      RemoteHost.github => 'GitHub',
      RemoteHost.gitlab => 'GitLab',
      RemoteHost.bitbucket => 'Bitbucket',
      RemoteHost.other => l10n.hostOther,
    };

/// gh 기능을 쓸 수 없는 이유 (PLAN.md 3.1, §2.1).
String ghUnavailableText(AppLocalizations l10n, EnvironmentStatus env) {
  if (!env.hasGh) return l10n.envGhMissing;
  if (!env.ghLoggedIn) return l10n.envGhLoggedOut;
  return '';
}

enum _RemoteMenu { rename, setUrl, remove }

class _RemoteCard extends StatelessWidget {
  const _RemoteCard({required this.remote, required this.repo});

  final Remote remote;
  final RepoController repo;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final loc = remote.location;
    final github = remote.isGitHub;

    Widget url(String label, String value) => Row(children: [
          SizedBox(width: 44, child: Text(label, style: theme.textTheme.labelSmall)),
          Expanded(
            child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppFonts.mono.copyWith(fontSize: 11.5)),
          ),
          CopyButton(text: value, size: 14),
        ]);

    return Container(
      margin: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, 4, AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.tile),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Flexible(
            child: Text(remote.name,
                overflow: TextOverflow.ellipsis, style: theme.textTheme.titleSmall?.merge(AppFonts.userContent)),
          ),
          const SizedBox(width: AppSpacing.sm),
          StatusPill(label: hostLabel(l10n, remote.host), tone: github ? Tone.primary : Tone.neutral),
          const Spacer(),
          Tooltip(
            message: GitCommands.fetch(remote: remote.name).join(' '),
            child: TextButton.icon(
              onPressed: repo.busy
                  ? null
                  : () => RepoActions.report(context, repo.fetch(remote: remote.name), done: l10n.doneFetch),
              icon: const Icon(Icons.sync_rounded, size: 14),
              label: Text(l10n.headerFetch),
            ),
          ),
          PopupMenuButton<_RemoteMenu>(
            tooltip: l10n.commonMore,
            icon: const Icon(Icons.more_horiz_rounded, size: 18),
            enabled: !repo.busy,
            onSelected: (m) => switch (m) {
              _RemoteMenu.rename => showRemoteSheet(context, repo, rename: remote),
              _RemoteMenu.setUrl => showRemoteSheet(context, repo, editUrl: remote),
              _RemoteMenu.remove => _remove(context),
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: _RemoteMenu.rename, child: Text(l10n.remotesRename)),
              PopupMenuItem(value: _RemoteMenu.setUrl, child: Text(l10n.remotesSetUrl)),
              PopupMenuItem(
                value: _RemoteMenu.remove,
                child: Text(l10n.remotesRemove, style: TextStyle(color: theme.colorScheme.error)),
              ),
            ],
          ),
        ]),
        if (loc != null)
          InkWell(
            onTap: () => launchUrl(Uri.parse(loc.webUrl)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(loc.path, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary)),
                const SizedBox(width: 4),
                Icon(Icons.open_in_new_rounded, size: 12, color: theme.colorScheme.primary),
              ]),
            ),
          ),
        const SizedBox(height: 4),
        url('fetch', remote.fetchUrl),
        if (remote.pushUrl != remote.fetchUrl) url('push', remote.pushUrl),
        if (!github) ...[
          const SizedBox(height: 4),
          Text(l10n.remotesNotGitHubNote, style: theme.textTheme.bodySmall),
        ],
      ]),
    );
  }

  Future<void> _remove(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final command = GitCommands.remoteRemove(remote.name);
    final ok = await confirmDanger(
      context,
      title: l10n.remotesRemoveTitle,
      message: l10n.remotesRemoveMessage(remote.name),
      confirm: l10n.remotesRemove,
      commands: [command],
    );
    if (ok && context.mounted) {
      await RepoActions.report(context, repo.execute(command), done: l10n.doneRemoveRemote(remote.name));
    }
  }
}

/// 원격 추가 / 이름 바꾸기 / URL 바꾸기 — 한 양식을 모드별로 쓴다.
Future<void> showRemoteSheet(BuildContext context, RepoController repo, {Remote? rename, Remote? editUrl}) {
  return showActionSheet<void>(context, (context) => _RemoteSheet(repo: repo, rename: rename, editUrl: editUrl));
}

class _RemoteSheet extends StatefulWidget {
  const _RemoteSheet({required this.repo, this.rename, this.editUrl});

  final RepoController repo;
  final Remote? rename;
  final Remote? editUrl;

  @override
  State<_RemoteSheet> createState() => _RemoteSheetState();
}

class _RemoteSheetState extends State<_RemoteSheet> {
  late final _name = TextEditingController(
      text: widget.rename?.name ?? widget.editUrl?.name ?? (widget.repo.remotes.isEmpty ? 'origin' : ''));
  late final _url = TextEditingController(text: widget.editUrl?.fetchUrl ?? '');

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
    _url.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    _url.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final repo = widget.repo;
    final name = _name.text.trim();
    final url = _url.text.trim();
    final nameOk = name.isNotEmpty && !name.contains(RegExp(r'[\s~^:?*\[\\]'));
    final taken = repo.remotes.any((r) => r.name == name) && name != (widget.rename?.name ?? widget.editUrl?.name);

    final (String title, List<String> command, bool valid, String done) = switch ((widget.rename, widget.editUrl)) {
      (final Remote r, _) => (
          l10n.remotesRename,
          GitCommands.remoteRename(r.name, name),
          nameOk && !taken && name != r.name,
          l10n.doneRenameRemote(name),
        ),
      (_, final Remote r) => (
          l10n.remotesSetUrl,
          GitCommands.remoteSetUrl(r.name, url),
          url.isNotEmpty && url != r.fetchUrl,
          l10n.doneSetRemoteUrl(r.name),
        ),
      _ => (
          l10n.remotesAdd,
          GitCommands.remoteAdd(name, url),
          nameOk && !taken && url.isNotEmpty,
          l10n.doneAddRemote(name),
        ),
    };
    final loc = RemoteLocation.parse(url);

    Future<void> submit() async {
      if (!valid) return;
      Navigator.pop(context);
      await RepoActions.report(context, repo.execute(command), done: done);
    }

    return ActionSheetBody(
      title: title,
      commands: [command],
      confirmLabel: title,
      onConfirm: valid ? submit : null,
      children: [
        if (widget.editUrl == null)
          TextField(
            controller: _name,
            autofocus: true,
            decoration: InputDecoration(
              labelText: l10n.remotesNameLabel,
              errorText: name.isEmpty ? null : (taken ? l10n.remotesNameTaken : (nameOk ? null : l10n.remotesNameInvalid)),
            ),
            onSubmitted: (_) => submit(),
          ),
        if (widget.rename == null) ...[
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _url,
            autofocus: widget.editUrl != null,
            style: AppFonts.mono.copyWith(fontSize: 12),
            decoration: InputDecoration(labelText: l10n.remotesUrlLabel, hintText: 'https://github.com/owner/repo.git'),
            onSubmitted: (_) => submit(),
          ),
          if (loc != null && loc.kind != RemoteHost.github) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(l10n.remotesNotGitHubNote, style: Theme.of(context).textTheme.bodySmall),
          ],
          // HTTPS ↔ SSH 전환 (PLAN.md 3.6 P1이지만 URL 바꾸기에서 한 번에 제공).
          if (loc != null && widget.editUrl != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => _url.text = loc.ssh ? loc.httpsUrl : loc.sshUrl,
                child: Text(loc.ssh ? l10n.remotesUseHttps : l10n.remotesUseSsh),
              ),
            ),
          ],
        ],
      ],
    );
  }
}

/// GitHub에 올리기 (PLAN.md 3.6): `gh repo create --source .`.
Future<void> showPublishToGitHubSheet(BuildContext context, RepoController repo) {
  return showActionSheet<void>(context, (context) => _PublishSheet(repo: repo));
}

class _PublishSheet extends StatefulWidget {
  const _PublishSheet({required this.repo});

  final RepoController repo;

  @override
  State<_PublishSheet> createState() => _PublishSheetState();
}

class _PublishSheetState extends State<_PublishSheet> {
  late final _name = TextEditingController(text: widget.repo.name);
  final _description = TextEditingController();
  RepoVisibility _visibility = RepoVisibility.private;

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
    _description.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final repo = widget.repo;
    final name = _name.text.trim();
    // 원격이 이미 있으면 GitHub 원격은 다른 이름으로 추가한다.
    final remoteName = repo.remotes.any((r) => r.name == 'origin') ? 'github' : 'origin';
    final command = GhCommands.repoCreate(
      name: name.isEmpty ? '<name>' : name,
      visibility: _visibility,
      description: _description.text,
      remote: remoteName,
      push: !repo.status.unborn,
    );
    final valid = name.isNotEmpty && RegExp(r'^[A-Za-z0-9._/-]+$').hasMatch(name);

    Future<void> submit() async {
      if (!valid) return;
      Navigator.pop(context);
      await RepoActions.report(context, repo.execute(command), done: l10n.donePublishToGitHub(name));
    }

    return ActionSheetBody(
      title: l10n.remotesPublishToGitHub,
      commands: [command],
      confirmLabel: l10n.remotesPublishConfirm,
      onConfirm: valid ? submit : null,
      children: [
        TextField(
          controller: _name,
          autofocus: true,
          decoration: InputDecoration(
            labelText: l10n.publishNameLabel,
            helperText: l10n.publishNameHelper,
            errorText: name.isEmpty || valid ? null : l10n.publishNameInvalid,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(controller: _description, decoration: InputDecoration(labelText: l10n.publishDescriptionLabel)),
        const SizedBox(height: AppSpacing.md),
        SegmentedButton<RepoVisibility>(
          segments: [
            ButtonSegment(value: RepoVisibility.private, label: Text(l10n.publishPrivate), icon: const Icon(Icons.lock_outline_rounded, size: 16)),
            ButtonSegment(value: RepoVisibility.public, label: Text(l10n.publishPublic), icon: const Icon(Icons.public_rounded, size: 16)),
          ],
          selected: {_visibility},
          onSelectionChanged: (s) => setState(() => _visibility = s.first),
        ),
        if (repo.status.unborn) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(l10n.publishNoCommitsNote, style: Theme.of(context).textTheme.bodySmall),
        ],
      ],
    );
  }
}
