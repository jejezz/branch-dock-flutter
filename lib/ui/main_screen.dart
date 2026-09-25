import 'dart:async';
import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

import '../app_identity.dart';
import '../git/remotes.dart';
import '../l10n/app_localizations.dart';
import '../repo/environment.dart';
import '../repo/next_action.dart';
import '../release/release_flow.dart';
import '../repo/repo_controller.dart';
import '../settings/settings_menus.dart';
import '../theme/app_theme.dart';
import 'command_bar.dart';
import 'repo_actions.dart';
import 'repo_scope.dart';
import 'services.dart';
import 'start_screen.dart';
import 'status_header.dart';
import 'tabs/branches_tab.dart';
import 'tabs/changes_tab.dart';
import 'tabs/pr_tab.dart';
import 'tabs/release_tab.dart';
import 'tabs/remotes_tab.dart';
import 'tabs/tags_tab.dart';
import 'widgets.dart';
import 'shortcut_label.dart';

/// 앱의 유일한 화면 (UI_UX.md §3): 앱 바 → 상태 헤더 → 추천 배너 → 섹션 탭 →
/// 내용 → 명령 바. 저장소가 없으면 시작 화면.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key, required this.onAbout});

  final VoidCallback onAbout;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin, WindowListener {
  late AppServices _services;
  EnvironmentStatus _env = const EnvironmentStatus();
  RepoController? _repo;
  ReleaseFlow? _flow;
  OpenFailure? _failure;
  String? _failedPath;
  bool _logExpanded = false;
  bool _dragging = false;
  bool _pinned = false;
  final _dismissed = <String>{};
  final _commitFocus = FocusNode();
  late final TabController _tabs = TabController(length: _tabCount, vsync: this);

  /// 변경 · 브랜치 · 태그 · 원격 · 릴리스 · PR (UI_UX.md §3 D, CI 탭은 v0.3.0).
  static const _tabCount = 6;
  static const _tabChanges = 0, _tabBranches = 1, _tabTags = 2, _tabRemotes = 3, _tabRelease = 4;
  bool _started = false;

  bool get _isDesktop => Platform.isMacOS || Platform.isWindows || Platform.isLinux;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _services = ServicesScope.of(context);
    if (!_started) {
      _started = true;
      _start();
    }
  }

  Future<void> _start() async {
    if (_isDesktop) windowManager.addListener(this);
    _tabs.addListener(() {
      final repo = _repo;
      if (repo != null && !_tabs.indexIsChanging) _services.prefs.setLastTab(repo.root, _tabs.index);
    });
    await _checkEnvironment();
    // 편집기 옆에 띄워 두고 쓰는 앱이라 마지막 저장소를 다시 연다.
    final recent = _services.prefs.recent;
    if (_env.hasGit && recent.isNotEmpty) await _open(recent.first, quietFailure: true);
  }

  @override
  void dispose() {
    if (_isDesktop) windowManager.removeListener(this);
    _flow?.dispose();
    _repo?.dispose();
    _tabs.dispose();
    _commitFocus.dispose();
    super.dispose();
  }

  Future<void> _checkEnvironment() async {
    final env = await EnvironmentStatus.check(_services.runner, Directory.systemTemp.path);
    if (mounted) setState(() => _env = env);
  }

  Future<void> _open(String path, {bool quietFailure = false}) async {
    final (repo, failure) = await RepoController.open(_services.runner, path);
    if (!mounted) {
      repo?.dispose();
      return;
    }
    if (repo == null) {
      if (quietFailure) return;
      setState(() {
        _failure = failure;
        _failedPath = path;
      });
      return;
    }
    _flow?.dispose();
    _repo?.dispose();
    await _services.prefs.addRecent(repo.root);
    final flow = ReleaseFlow(repo, ghReady: _env.ghReady);
    setState(() {
      _repo = repo;
      _flow = flow;
      _failure = null;
      _failedPath = null;
      _dismissed.clear();
    });
    _tabs.index = _services.prefs.lastTab(repo.root).clamp(0, _tabs.length - 1);
    if (_isDesktop) windowManager.setTitle('${AppIdentity.displayName} — ${repo.name}');
    // 진행 중이던 릴리스가 있으면 이어서 연다 (UI_UX.md §4.5).
    if (await flow.resume() && mounted) _tabs.index = _tabRelease;
  }

  void _dismiss(String key) => setState(() => _dismissed.add(key));

  void _close() {
    _flow?.dispose();
    _repo?.dispose();
    setState(() {
      _repo = null;
      _flow = null;
    });
    if (_isDesktop) windowManager.setTitle(AppIdentity.displayName);
  }

  Future<void> _pickFolder() async {
    final path = await getDirectoryPath(initialDirectory: _repo?.root);
    if (path != null) await _open(path);
  }

  @override
  void onWindowFocus() {
    // 다른 앱(편집기, 터미널, 브라우저)에서 돌아오면 상태를 다시 읽는다.
    _repo?.refresh();
    _flow?.poll();
  }

  Future<void> _togglePin() async {
    final pinned = !_pinned;
    await windowManager.setAlwaysOnTop(pinned);
    setState(() => _pinned = pinned);
  }

  // --- 단축키 (UI_UX.md §7) ------------------------------------------------

  Map<ShortcutActivator, VoidCallback> _shortcuts(BuildContext context) {
    final mac = defaultTargetPlatform == TargetPlatform.macOS;
    SingleActivator key(LogicalKeyboardKey k, {bool shift = false, bool alt = false}) =>
        SingleActivator(k, meta: mac, control: !mac, shift: shift, alt: alt);
    final repo = _repo;
    return {
      key(LogicalKeyboardKey.keyO): _pickFolder,
      key(LogicalKeyboardKey.keyJ): () => setState(() => _logExpanded = !_logExpanded),
      key(LogicalKeyboardKey.keyT, alt: true): _togglePin,
      if (repo != null) ...{
        key(LogicalKeyboardKey.keyR): repo.refresh,
        const SingleActivator(LogicalKeyboardKey.f5): repo.refresh,
        for (var i = 0; i < _tabCount; i++)
          key(LogicalKeyboardKey(LogicalKeyboardKey.digit1.keyId + i)): () => _tabs.animateTo(i),
        key(LogicalKeyboardKey.keyT): () {
          if (repo.status.unborn) return;
          _tabs.animateTo(_tabTags);
          showCreateTagSheet(context, repo);
        },
        key(LogicalKeyboardKey.keyR, shift: true): () {
          _tabs.animateTo(_tabRelease);
          final flow = _flow;
          if (flow != null && flow.checks.isEmpty && repo.githubRemote != null && _env.ghReady) {
            flow.ghReady = _env.ghReady;
            flow.runChecks();
          }
        },
        key(LogicalKeyboardKey.keyP): () => RepoActions.push(context, repo),
        key(LogicalKeyboardKey.keyP, shift: true): () => RepoActions.pull(context, repo),
        key(LogicalKeyboardKey.keyF, shift: true): () => RepoActions.fetch(context, repo),
        key(LogicalKeyboardKey.keyB): () {
          if (!repo.status.unborn) showCreateBranchSheet(context, repo);
        },
      },
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final repo = _repo;

    final scaffold = Scaffold(
      appBar: _appBar(context, l10n),
      body: DropTarget(
        onDragEntered: (_) => setState(() => _dragging = true),
        onDragExited: (_) => setState(() => _dragging = false),
        onDragDone: (details) {
          setState(() => _dragging = false);
          final dirs = details.files.map((f) => f.path).where((p) => FileSystemEntity.isDirectorySync(p));
          if (dirs.isNotEmpty) _open(dirs.first);
        },
        child: Column(children: [
          Expanded(
            child: repo == null
                ? StartScreen(
                    recent: _services.prefs.recent,
                    environment: _env,
                    failure: _failure,
                    failedPath: _failedPath,
                    dragging: _dragging,
                    onOpenFolder: _pickFolder,
                    onOpenRecent: _open,
                    onRemoveRecent: (p) async {
                      await _services.prefs.removeRecent(p);
                      setState(() {});
                    },
                    onCheckEnvironment: _checkEnvironment,
                  )
                : RepoScope(repo: repo, environment: _env, child: _RepoView(state: this)),
          ),
          CommandBar(
            log: _services.log,
            expanded: _logExpanded,
            onToggle: () => setState(() => _logExpanded = !_logExpanded),
            onCancel: repo?.cancel,
          ),
        ]),
      ),
    );

    return CallbackShortcuts(
      bindings: _shortcuts(context),
      child: Focus(autofocus: true, child: scaffold),
    );
  }

  PreferredSizeWidget _appBar(BuildContext context, AppLocalizations l10n) {
    final repo = _repo;
    return AppBar(
      toolbarHeight: 44,
      titleSpacing: AppSpacing.sm,
      title: repo == null
          ? const Text(AppIdentity.displayName)
          : ListenableBuilder(listenable: repo, builder: (context, _) => _repoSwitcher(context, l10n, repo)),
      actions: [
        if (repo != null)
          IconButton(
            tooltip: l10n.appBarRefresh,
            iconSize: 18,
            icon: const Icon(Icons.refresh_rounded),
            onPressed: repo.refresh,
          ),
        if (_isDesktop)
          IconButton(
            tooltip: _pinned ? l10n.appBarUnpin : l10n.appBarPin,
            iconSize: 18,
            isSelected: _pinned,
            icon: const Icon(Icons.push_pin_outlined),
            selectedIcon: const Icon(Icons.push_pin_rounded),
            onPressed: _togglePin,
          ),
        const ThemeMenuButton(),
        const LanguageMenuButton(),
        IconButton(
          tooltip: l10n.aboutTooltip,
          iconSize: 18,
          icon: const Icon(Icons.info_outline_rounded),
          onPressed: widget.onAbout,
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _repoSwitcher(BuildContext context, AppLocalizations l10n, RepoController repo) {
    final host = repo.primaryHost;
    final others = _services.prefs.recent.where((p) => p != repo.root).toList();
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Flexible(
        child: PopupMenuButton<String>(
          tooltip: repo.root,
          position: PopupMenuPosition.under,
          onSelected: (v) async {
            switch (v) {
              case ':open':
                await _pickFolder();
              case ':editor':
                final cmd = await showEditorCommandSheet(context, _services.prefs.editorCommand);
                if (cmd != null) await _services.prefs.setEditorCommand(cmd);
              case ':env':
                if (context.mounted) await showEnvironmentSheet(context, _env, _checkEnvironment);
              case ':close':
                _close();
              default:
                await _open(v);
            }
          },
          itemBuilder: (context) => [
            for (final p in others)
              PopupMenuItem(
                value: p,
                child: Text(p.split(Platform.pathSeparator).where((s) => s.isNotEmpty).last,
                    style: AppFonts.userContent),
              ),
            if (others.isNotEmpty) const PopupMenuDivider(),
            PopupMenuItem(value: ':open', child: Text('${l10n.menuOpenFolder}  ${shortcutLabel('O')}')),
            PopupMenuItem(value: ':editor', child: Text(l10n.menuEditor)),
            PopupMenuItem(value: ':env', child: Text(l10n.menuEnvironment)),
            PopupMenuItem(value: ':close', child: Text(l10n.menuCloseRepo)),
          ],
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.folder_rounded, size: 18),
              const SizedBox(width: 6),
              Flexible(
                child: Text(repo.name,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).appBarTheme.titleTextStyle?.merge(AppFonts.userContent)),
              ),
              const Icon(Icons.arrow_drop_down_rounded, size: 20),
            ]),
          ),
        ),
      ),
      // GitHub가 아닌 저장소는 처음부터 알 수 있게 호스팅을 붙인다 (UI_UX.md §3 D).
      if (host != null && host != RemoteHost.github) ...[
        const SizedBox(width: 6),
        StatusPill(label: hostLabel(l10n, host)),
      ],
    ]);
  }
}

class _RepoView extends StatelessWidget {
  const _RepoView({required this.state});

  final _MainScreenState state;

  @override
  Widget build(BuildContext context) {
    final repo = RepoScope.of(context);
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    if (!repo.loaded) return const Center(child: CircularProgressIndicator());

    final next = suggestNextAction(
      status: repo.status,
      remotes: repo.remotes,
      headMergedAndGone: repo.headMergedAndGone,
    );
    final showNext = next != null && !state._dismissed.contains(next.key);
    final host = repo.primaryHost;
    final notGitHub = host != null && repo.githubRemote == null;
    final notGitHubKey = 'host:${repo.root}';

    return Column(children: [
      StatusHeader(onBranchTap: () => state._tabs.animateTo(_MainScreenState._tabBranches)),
      _DelayedProgress(visible: repo.busy),
      if (notGitHub && !state._dismissed.contains(notGitHubKey))
        _InfoBanner(
          text: l10n.bannerNotGitHub(hostLabel(l10n, host)),
          onDismiss: () => state._dismiss(notGitHubKey),
        ),
      if (showNext)
        NextActionBanner(
          action: next,
          onDismiss: () => state._dismiss(next.key),
          onShowChanges: () => state._tabs.animateTo(_MainScreenState._tabChanges),
          onShowRemotes: () => state._tabs.animateTo(_MainScreenState._tabRemotes),
        ),
      TabBar(
        controller: state._tabs,
        // 380–439px에서는 탭을 가로로 스크롤한다 (UI_UX.md §2).
        isScrollable: MediaQuery.sizeOf(context).width < 440,
        tabAlignment: MediaQuery.sizeOf(context).width < 440 ? TabAlignment.start : TabAlignment.fill,
        labelPadding: const EdgeInsets.symmetric(horizontal: 10),
        labelStyle: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
        unselectedLabelStyle: theme.textTheme.labelMedium,
        tabs: [
          Tab(
            height: 48,
            icon: Badge(
              isLabelVisible: repo.status.changedCount > 0,
              label: Text('${repo.status.changedCount}'),
              child: const Icon(Icons.edit_note_rounded, size: 20),
            ),
            text: l10n.tabChanges,
          ),
          Tab(height: 48, icon: const Icon(Icons.call_split_rounded, size: 20), text: l10n.tabBranches),
          Tab(height: 48, icon: const Icon(Icons.sell_outlined, size: 20), text: l10n.tabTags),
          Tab(height: 48, icon: const Icon(Icons.cloud_outlined, size: 20), text: l10n.tabRemotes),
          Tab(
            height: 48,
            icon: ListenableBuilder(
              listenable: state._flow!,
              builder: (context, _) {
                final flow = state._flow!;
                // 진행 중인 릴리스가 있으면 점으로 알린다 (UI_UX.md §3 D).
                final active = flow.step != ReleaseStep.check && flow.step != ReleaseStep.done;
                return Badge(isLabelVisible: active, smallSize: 8, child: const Icon(Icons.rocket_launch_outlined, size: 20));
              },
            ),
            text: l10n.tabRelease,
          ),
          Tab(height: 48, icon: const Icon(Icons.merge_rounded, size: 20), text: l10n.tabPr),
        ],
      ),
      Expanded(
        child: TabBarView(
          controller: state._tabs,
          children: [
            ChangesTab(commitFocus: state._commitFocus),
            const BranchesTab(),
            const TagsTab(),
            const RemotesTab(),
            ReleaseTab(flow: state._flow!, onShowChanges: () => state._tabs.animateTo(_MainScreenState._tabChanges)),
            const PrTab(),
          ],
        ),
      ),
    ]);
  }
}

/// 0.5초 이상 걸리는 작업만 진행 표시 (ui-ux.md §6).
class _DelayedProgress extends StatefulWidget {
  const _DelayedProgress({required this.visible});

  final bool visible;

  @override
  State<_DelayedProgress> createState() => _DelayedProgressState();
}

class _DelayedProgressState extends State<_DelayedProgress> {
  Timer? _timer;
  bool _show = false;

  @override
  void didUpdateWidget(_DelayedProgress old) {
    super.didUpdateWidget(old);
    if (widget.visible && !old.visible) {
      _timer = Timer(const Duration(milliseconds: 500), () {
        if (mounted) setState(() => _show = true);
      });
    } else if (!widget.visible) {
      _timer?.cancel();
      _show = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      SizedBox(height: 2, child: _show ? const LinearProgressIndicator(minHeight: 2) : null);
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.text, required this.onDismiss});

  final String text;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 6, 4, 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      child: Row(children: [
        Icon(Icons.info_outline_rounded, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(text, style: theme.textTheme.bodySmall)),
        IconButton(
          tooltip: AppLocalizations.of(context).commonClose,
          visualDensity: VisualDensity.compact,
          iconSize: 16,
          icon: const Icon(Icons.close_rounded),
          onPressed: onDismiss,
        ),
      ]),
    );
  }
}
