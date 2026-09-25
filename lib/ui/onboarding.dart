import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../git/commands.dart';
import '../github/onboarding.dart';
import '../l10n/app_localizations.dart';
import '../repo/environment.dart';
import '../theme/app_theme.dart';
import 'action_sheet.dart';
import 'services.dart';
import 'widgets.dart';

/// 로그인 안내 (PLAN.md 3.1, UI_UX.md §8): SSH | HTTPS. SSH를 고르면 5단계 —
/// 키 확인 → 로그인(기기 코드) → 공개 키 올리기 → 연결 확인 → 프로토콜.
/// 키와 암호 문구는 앱이 받지 않는다. 키 만들기는 명령을 복사해 터미널에서.
Future<void> showLoginSheet(
  BuildContext context,
  EnvironmentStatus env, {
  required VoidCallback onChanged,
  bool preferSsh = false,
}) {
  return showActionSheet<void>(
    context,
    (context) => _LoginSheet(env: env, onChanged: onChanged, preferSsh: preferSsh),
  );
}

/// SSH로 작업 중이거나 원격이 SSH 주소면 SSH를 권한다.
bool sshPreferred({bool remoteIsSsh = false}) =>
    remoteIsSsh || (Platform.environment['SSH_CONNECTION']?.isNotEmpty ?? false);

class _LoginSheet extends StatefulWidget {
  const _LoginSheet({required this.env, required this.onChanged, required this.preferSsh});

  final EnvironmentStatus env;
  final VoidCallback onChanged;
  final bool preferSsh;

  @override
  State<_LoginSheet> createState() => _LoginSheetState();
}

class _LoginSheetState extends State<_LoginSheet> {
  late bool _ssh = widget.preferSsh;
  late bool _loggedIn = widget.env.ghLoggedIn;
  List<String> _keys = findPublicKeys();
  String? _selectedKey;

  Process? _login;
  String? _code;
  String _loginOutput = '';
  String? _keyUpload;
  bool? _sshOk;
  bool _checkingSsh = false;

  @override
  void initState() {
    super.initState();
    _selectedKey = _keys.firstOrNull;
  }

  @override
  void dispose() {
    _login?.kill();
    super.dispose();
  }

  Map<String, String> get _env => {'PATH': ServicesScope.of(context).runner.path, 'NO_COLOR': '1'};

  /// `gh auth login --web`을 띄우고 출력에서 일회용 코드를 읽는다.
  /// 사용자가 브라우저에서 코드를 넣으면 프로세스가 끝난다.
  Future<void> _startLogin() async {
    final command = GhCommands.authLogin(ssh: _ssh);
    setState(() {
      _code = null;
      _loginOutput = '';
    });
    final p = await Process.start(command.first, command.sublist(1), environment: _env, runInShell: Platform.isWindows);
    _login = p;
    await p.stdin.close();
    void onData(String chunk) {
      if (!mounted) return;
      setState(() {
        _loginOutput += chunk;
        _code ??= parseDeviceCode(_loginOutput);
      });
    }

    final a = p.stdout.transform(utf8.decoder).listen(onData).asFuture<void>();
    final b = p.stderr.transform(utf8.decoder).listen(onData).asFuture<void>();
    final code = await p.exitCode;
    await Future.wait([a, b]);
    _login = null;
    if (!mounted) return;
    if (code == 0 && !_ssh) {
      // HTTPS: git push도 gh 인증을 쓰게 한다.
      await Process.run(GhCommands.authSetupGit.first, GhCommands.authSetupGit.sublist(1), environment: _env);
    }
    setState(() => _loggedIn = code == 0 || _loggedIn);
    widget.onChanged();
  }

  Future<void> _uploadKey() async {
    final key = _selectedKey;
    if (key == null) return;
    final host = Platform.localHostname;
    final command = GhCommands.sshKeyAdd(key, 'Branch Dock ($host)');
    final r = await Process.run(command.first, command.sublist(1), environment: _env);
    if (!mounted) return;
    final out = '${r.stdout}${r.stderr}';
    setState(() => _keyUpload = r.exitCode == 0 || out.contains('already') ? 'ok' : out.trim());
  }

  Future<void> _checkSsh() async {
    setState(() => _checkingSsh = true);
    final r = await Process.run(sshTestCommand.first, sshTestCommand.sublist(1), environment: _env);
    if (!mounted) return;
    setState(() {
      _checkingSsh = false;
      _sshOk = sshAuthenticated('${r.stdout}${r.stderr}');
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    Widget step(int n, bool? ok, String title, String detail, List<Widget> body) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: ok == true ? toneColor(context, Tone.success) : theme.colorScheme.outline),
                color: ok == true ? toneColor(context, Tone.success).withValues(alpha: 0.15) : null,
              ),
              child: ok == true
                  ? Icon(Icons.check_rounded, size: 13, color: toneColor(context, Tone.success))
                  : Text('$n', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text(title, style: theme.textTheme.titleSmall),
                if (detail.isNotEmpty) Text(detail, style: theme.textTheme.bodySmall),
                ...body,
              ]),
            ),
          ]),
        );

    final loginStep = step(
      _ssh ? 2 : 1,
      _loggedIn,
      l10n.loginStepLogin,
      _loggedIn ? l10n.loginLoggedIn : l10n.loginStepLoginWhy,
      [
        if (!_loggedIn || _login != null) ...[
          const SizedBox(height: AppSpacing.sm),
          CommandPreview(commands: [GhCommands.authLogin(ssh: _ssh)]),
          const SizedBox(height: AppSpacing.sm),
          if (_login == null)
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: _startLogin,
                icon: const Icon(Icons.login_rounded, size: 16),
                label: Text(l10n.loginStart),
              ),
            )
          else ...[
            if (_code != null)
              Row(children: [
                SelectableText(_code!, style: AppFonts.mono.copyWith(fontSize: 22, fontWeight: FontWeight.w700)),
                CopyButton(text: _code!),
              ]),
            Text(l10n.loginDeviceHowTo, style: theme.textTheme.bodySmall),
            const SizedBox(height: 4),
            Wrap(spacing: AppSpacing.sm, children: [
              OutlinedButton.icon(
                onPressed: () => launchUrl(Uri.parse(deviceLoginUrl)),
                icon: const Icon(Icons.open_in_new_rounded, size: 14),
                label: const Text(deviceLoginUrl),
              ),
              TextButton(onPressed: () => _login?.kill(), child: Text(l10n.commonCancel)),
            ]),
          ],
        ],
      ],
    );

    final keyCommand = 'ssh-keygen -t ed25519 -C "you@example.com"';
    final addKey = _selectedKey == null ? null : GhCommands.sshKeyAdd(_selectedKey!, 'Branch Dock');

    return ActionSheetBody(
      title: l10n.loginTitle,
      commands: const [],
      confirmLabel: l10n.commonClose,
      onConfirm: () => Navigator.pop(context),
      children: [
        SegmentedButton<bool>(
          segments: [
            ButtonSegment(value: true, label: Text(l10n.loginSsh)),
            ButtonSegment(value: false, label: Text(l10n.loginHttps)),
          ],
          selected: {_ssh},
          onSelectionChanged: _login != null ? null : (s) => setState(() => _ssh = s.first),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (widget.preferSsh && _ssh)
          Row(children: [
            StatusPill(label: l10n.loginSshRecommended, tone: Tone.primary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(l10n.loginSshWhy, style: theme.textTheme.bodySmall)),
          ]),
        const SizedBox(height: AppSpacing.md),
        if (_ssh) ...[
          step(1, _keys.isNotEmpty, l10n.loginStepKey, _keys.isEmpty ? l10n.loginStepKeyMissing : l10n.loginStepKeyFound, [
            if (_keys.isEmpty) ...[
              Row(children: [
                Expanded(child: SelectableText(keyCommand, style: AppFonts.mono.copyWith(fontSize: 12))),
                CopyButton(text: keyCommand),
              ]),
              TextButton(
                onPressed: () => setState(() {
                  _keys = findPublicKeys();
                  _selectedKey = _keys.firstOrNull;
                }),
                child: Text(l10n.envRecheck),
              ),
            ] else
              DropdownButton<String>(
                value: _selectedKey,
                isExpanded: true,
                items: [
                  for (final k in _keys)
                    DropdownMenuItem(value: k, child: Text(k.split('/').last, style: AppFonts.mono.copyWith(fontSize: 12))),
                ],
                onChanged: (v) => setState(() => _selectedKey = v),
              ),
          ]),
          loginStep,
          step(3, _keyUpload == 'ok', l10n.loginStepUpload, l10n.loginStepUploadWhy, [
            if (addKey != null) ...[
              const SizedBox(height: 4),
              CommandPreview(commands: [addKey]),
              const SizedBox(height: 4),
              if (_keyUpload != null && _keyUpload != 'ok') ...[
                Text(_keyUpload!, style: AppFonts.mono.copyWith(fontSize: 11, color: theme.colorScheme.error)),
                if (_keyUpload!.contains('admin:public_key')) ...[
                  Text(l10n.loginNeedsKeyScope, style: theme.textTheme.bodySmall),
                  Row(children: [
                    Expanded(
                      child: SelectableText('gh auth refresh -h github.com -s admin:public_key',
                          style: AppFonts.mono.copyWith(fontSize: 12)),
                    ),
                    const CopyButton(text: 'gh auth refresh -h github.com -s admin:public_key'),
                  ]),
                ],
              ],
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton(
                  onPressed: _loggedIn && _keyUpload != 'ok' ? _uploadKey : null,
                  child: Text(l10n.loginUploadKey),
                ),
              ),
            ],
          ]),
          step(4, _sshOk, l10n.loginStepTest, _sshOk == false ? l10n.loginSshFailed : l10n.loginStepTestWhy, [
            const SizedBox(height: 4),
            CommandPreview(commands: [sshTestCommand]),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton(
                onPressed: _checkingSsh ? null : _checkSsh,
                child: Text(_checkingSsh ? l10n.loginChecking : l10n.loginTest),
              ),
            ),
          ]),
          step(5, null, l10n.loginStepProtocol, l10n.loginStepProtocolWhy, [
            const SizedBox(height: 4),
            CommandPreview(commands: [GhCommands.setGitProtocolSsh]),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton(
                onPressed: () async {
                  final c = GhCommands.setGitProtocolSsh;
                  await Process.run(c.first, c.sublist(1), environment: _env);
                  if (context.mounted) showDone(context, l10n.doneProtocolSsh);
                },
                child: Text(l10n.loginUseSshProtocol),
              ),
            ),
            const SizedBox(height: 4),
            Text(l10n.loginAgentTip, style: theme.textTheme.bodySmall),
          ]),
        ] else
          loginStep,
      ],
    );
  }
}

/// GitHub에서 복제 (PLAN.md 3.1): 내 저장소 목록에서 고르고 폴더를 정한다.
Future<String?> showCloneSheet(BuildContext context) =>
    showActionSheet<String>(context, (context) => const _CloneSheet());

class _CloneSheet extends StatefulWidget {
  const _CloneSheet();

  @override
  State<_CloneSheet> createState() => _CloneSheetState();
}

class _CloneSheetState extends State<_CloneSheet> {
  List<RepoSummary>? _repos;
  final _filter = TextEditingController();
  RepoSummary? _chosen;
  String? _parent;
  bool _cloning = false;

  @override
  void initState() {
    super.initState();
    _filter.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _filter.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final services = ServicesScope.of(context);
    final r = await services.runner.run(GhCommands.repoList(), workingDirectory: Directory.systemTemp.path, quiet: true);
    if (!mounted) return;
    setState(() => _repos = r.ok ? RepoSummary.parseList(r.stdout) : const []);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final q = _filter.text.trim().toLowerCase();
    final repos = (_repos ?? const <RepoSummary>[]).where((r) => q.isEmpty || r.nameWithOwner.toLowerCase().contains(q)).toList();
    final target = _chosen == null || _parent == null ? null : '$_parent${Platform.pathSeparator}${_chosen!.name}';
    final exists = target != null && FileSystemEntity.typeSync(target) != FileSystemEntityType.notFound;
    final command = GhCommands.repoClone(_chosen?.nameWithOwner ?? 'owner/repo', target ?? '<folder>');

    return ActionSheetBody(
      title: l10n.cloneTitle,
      commands: [command],
      confirmLabel: _cloning ? l10n.cloneRunning : l10n.cloneConfirm,
      onConfirm: target == null || exists || _cloning
          ? null
          : () async {
              setState(() => _cloning = true);
              final services = ServicesScope.of(context);
              final r = await services.runner.run(command, workingDirectory: _parent!);
              if (!context.mounted) return;
              setState(() => _cloning = false);
              if (r.ok) {
                Navigator.pop(context, target);
              } else {
                showCommandError(context, r);
              }
            },
      children: [
        TextField(
          controller: _filter,
          decoration: InputDecoration(isDense: true, prefixIcon: const Icon(Icons.search_rounded, size: 18), hintText: l10n.cloneSearch),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 220,
          child: _repos == null
              ? const Center(child: CircularProgressIndicator())
              : repos.isEmpty
                  ? Center(child: Text(l10n.cloneEmpty, style: theme.textTheme.bodySmall))
                  : ListView(children: [
                      for (final r in repos)
                        ListTile(
                          dense: true,
                          selected: _chosen?.nameWithOwner == r.nameWithOwner,
                          leading: Icon(r.private ? Icons.lock_outline_rounded : Icons.public_rounded, size: 16),
                          title: Text(r.nameWithOwner, style: AppFonts.userContent),
                          subtitle: r.description.isEmpty
                              ? null
                              : Text(r.description, maxLines: 1, overflow: TextOverflow.ellipsis),
                          onTap: () => setState(() => _chosen = r),
                        ),
                    ]),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(children: [
          Expanded(
            child: Text(_parent ?? l10n.cloneNoFolder,
                maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall?.merge(AppFonts.userContent)),
          ),
          TextButton(
            onPressed: () async {
              final dir = await getDirectoryPath();
              if (dir != null) setState(() => _parent = dir);
            },
            child: Text(l10n.cloneChooseFolder),
          ),
        ]),
        if (exists) Text(l10n.cloneExists(target), style: TextStyle(color: theme.colorScheme.error)),
      ],
    );
  }
}
