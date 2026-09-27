import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../git/commands.dart';
import '../l10n/app_localizations.dart';
import '../repo/environment.dart';
import '../repo/repo_controller.dart';
import '../theme/app_theme.dart';
import 'action_sheet.dart';
import 'widgets.dart';
import 'shortcut_label.dart';

/// 저장소를 열기 전 화면 (UI_UX.md §8): 빈 상태 + 최근 저장소 + 환경 경고.
class StartScreen extends StatelessWidget {
  const StartScreen({
    super.key,
    required this.recent,
    required this.environment,
    required this.onOpenFolder,
    required this.onOpenRecent,
    required this.onRemoveRecent,
    required this.onCheckEnvironment,
    this.onInitRepository,
    this.onClone,
    this.onLogin,
    this.onSetToolPath,
    this.failure,
    this.failedPath,
    this.dragging = false,
  });

  final List<String> recent;
  final EnvironmentStatus environment;
  final VoidCallback onOpenFolder;
  final ValueChanged<String> onOpenRecent;
  final ValueChanged<String> onRemoveRecent;
  final VoidCallback onCheckEnvironment;

  /// 저장소가 아닌 폴더를 git 저장소로 만든다 (PLAN.md 3.1 P1).
  final ValueChanged<String>? onInitRepository;

  /// GitHub에서 복제 (gh 로그인이 있을 때).
  final VoidCallback? onClone;

  /// 로그인 안내 열기.
  final VoidCallback? onLogin;

  /// git / gh 경로 지정 (`git`이 PATH에 없을 때 특히).
  final ValueChanged<String>? onSetToolPath;
  final OpenFailure? failure;
  final String? failedPath;
  final bool dragging;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final env = environment;

    return Container(
      decoration: dragging
          ? BoxDecoration(border: Border.all(color: theme.colorScheme.primary, width: 2))
          : null,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          if (env.checked && !env.hasGit)
            EnvironmentCard(environment: env, onRecheck: onCheckEnvironment, onSetPath: onSetToolPath)
          else ...[
            if (failure != null)
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    failure == OpenFailure.notARepository
                        ? l10n.startNotARepository(failedPath ?? '')
                        : l10n.startNotFound(failedPath ?? ''),
                  ),
                  if (failure == OpenFailure.notARepository && failedPath != null && onInitRepository != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Tooltip(
                      message: GitCommands.init.join(' '),
                      child: OutlinedButton.icon(
                        onPressed: () => onInitRepository!(failedPath!),
                        icon: const Icon(Icons.create_new_folder_outlined, size: 16),
                        label: Text(l10n.startInitRepository),
                      ),
                    ),
                  ],
                ]),
              ),
            EmptyState(
              icon: Icons.folder_open_rounded,
              title: l10n.homeEmptyTitle,
              message: l10n.startDropHint,
              action: Column(children: [
                FilledButton.icon(
                  onPressed: env.hasGit ? onOpenFolder : null,
                  icon: const Icon(Icons.folder_open_rounded, size: 16),
                  label: Text('${l10n.homeEmptyAction}  ${shortcutLabel('O')}'),
                ),
                if (onClone != null && env.ghReady) ...[
                  const SizedBox(height: AppSpacing.sm),
                  TextButton.icon(
                    onPressed: onClone,
                    icon: const Icon(Icons.download_rounded, size: 16),
                    label: Text(l10n.cloneTitle),
                  ),
                ],
              ]),
            ),
            if (recent.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.md, 0, AppSpacing.sm),
                child: Text(l10n.startRecent, style: theme.textTheme.titleSmall),
              ),
              for (final path in recent)
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.folder_outlined, size: 20),
                  title: Text(path.split(Platform.pathSeparator).where((s) => s.isNotEmpty).last,
                      style: AppFonts.userContent.copyWith(fontWeight: FontWeight.w600)),
                  subtitle: Text(path,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.merge(AppFonts.userContent)),
                  trailing: IconButton(
                    tooltip: l10n.startRemoveRecent,
                    iconSize: 16,
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => onRemoveRecent(path),
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
                  onTap: () => onOpenRecent(path),
                ),
            ],
            if (env.checked && !env.ghReady) ...[
              const SizedBox(height: AppSpacing.lg),
              EnvironmentCard(environment: env, onRecheck: onCheckEnvironment, onLogin: onLogin, onSetPath: onSetToolPath),
            ],
          ],
        ],
      ),
    );
  }
}

/// 환경 점검 체크리스트 (UI_UX.md §8): 항목별 ✓/✕, 설치·로그인 명령 복사.
class EnvironmentCard extends StatelessWidget {
  const EnvironmentCard({super.key, required this.environment, required this.onRecheck, this.onLogin, this.onSetPath});

  final EnvironmentStatus environment;
  final VoidCallback onRecheck;

  /// 로그인 안내(SSH/HTTPS)를 연다. 없으면 명령 복사만.
  final VoidCallback? onLogin;

  /// git / gh 경로를 직접 지정한다 (PLAN.md 3.14). 인자는 `git` 또는 `gh`.
  final ValueChanged<String>? onSetPath;

  Future<void> _copyDiagnostics(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    var version = '?';
    try {
      final info = await PackageInfo.fromPlatform();
      version = '${info.version}+${info.buildNumber}';
    } on Object {
      // 테스트처럼 플랫폼 정보가 없으면 버전 없이 복사한다.
    }
    await Clipboard.setData(ClipboardData(text: environment.diagnostics(appVersion: version)));
    if (context.mounted) showDone(context, l10n.envDiagnosticsCopied);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final env = environment;

    String install(String tool) {
      if (Platform.isMacOS) return 'brew install $tool';
      if (Platform.isWindows) return tool == 'git' ? 'winget install --id Git.Git -e' : 'winget install --id GitHub.cli -e';
      return tool == 'git' ? 'sudo apt install git' : 'sudo apt install gh';
    }

    Widget item(
      bool ok,
      String title,
      String detail, {
      String? command,
      String? path,
      bool custom = false,
      String? warning,
      String? tool,
    }) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            !ok ? Icons.cancel_rounded : (warning != null ? Icons.warning_rounded : Icons.check_circle_rounded),
            size: 18,
            color: toneColor(context, !ok ? Tone.danger : (warning != null ? Tone.warning : Tone.success)),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(title, style: theme.textTheme.titleSmall),
                    if (custom) ...[
                      const SizedBox(width: 6),
                      StatusPill(label: l10n.envCustomPath, tone: Tone.primary),
                    ],
                    const Spacer(),
                    if (tool != null && onSetPath != null)
                      SizedBox(
                        height: 24,
                        child: TextButton(onPressed: () => onSetPath!(tool), child: Text(l10n.envSetPath)),
                      ),
                  ],
                ),
                Text(detail, style: theme.textTheme.bodySmall),
                if (path != null)
                  SelectableText(
                    path,
                    style: AppFonts.mono.copyWith(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                  ),
                if (warning != null)
                  Text(warning, style: theme.textTheme.bodySmall?.copyWith(color: toneColor(context, Tone.warning))),
                if (!ok && command != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(child: SelectableText(command, style: AppFonts.mono.copyWith(fontSize: 12))),
                      CopyButton(text: command, size: 14),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    // Material이어야 안의 PATH 펼치기(ExpansionTile)가 배경 위에 그려진다.
    return Material(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.tile),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.envTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(env.hasGit ? l10n.envGitOnlyNote : l10n.envGitRequired, style: theme.textTheme.bodySmall),
            const SizedBox(height: AppSpacing.sm),
            item(
              env.hasGit,
              'git',
              env.hasGit ? l10n.envVersion(env.gitVersion!) : l10n.envNotInstalled,
              command: install('git'),
              path: env.gitPath,
              custom: env.gitCustom,
              warning: env.gitTooOld ? l10n.envGitTooOld(EnvironmentStatus.minGit) : null,
              tool: 'git',
            ),
            item(
              env.hasGh,
              'gh (GitHub CLI)',
              env.hasGh ? l10n.envVersion(env.ghVersion!) : l10n.envNotInstalled,
              command: install('gh'),
              path: env.ghPath,
              custom: env.ghCustom,
              warning: env.ghTooOld ? l10n.envGhTooOld(EnvironmentStatus.minGh) : null,
              tool: 'gh',
            ),
            if (env.hasGh)
              item(
                env.ghLoggedIn,
                l10n.envLogin,
                env.ghLoggedIn ? l10n.envLoggedInAs(env.ghLogins['github.com'] ?? '') : l10n.envNotLoggedIn,
                command: 'gh auth login',
              ),
            if (env.hasGh && !env.ghLoggedIn && onLogin != null)
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  onPressed: onLogin,
                  icon: const Icon(Icons.login_rounded, size: 16),
                  label: Text(l10n.loginTitle),
                ),
              ),
            if (env.checked && env.searchPath.isNotEmpty)
              Theme(
                data: theme.copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  dense: true,
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: EdgeInsets.zero,
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  title: Text(l10n.envSearchPath, style: theme.textTheme.bodySmall),
                  children: [
                    SelectableText(
                      env.searchPath.split(Platform.isWindows ? ';' : ':').where((p) => p.trim().isNotEmpty).join('\n'),
                      style: AppFonts.mono.copyWith(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                if (env.checked)
                  TextButton.icon(
                    onPressed: () => _copyDiagnostics(context),
                    icon: const Icon(Icons.content_copy_rounded, size: 16),
                    label: Text(l10n.envCopyDiagnostics),
                  ),
                OutlinedButton.icon(
                  onPressed: onRecheck,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: Text(l10n.envRecheck),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 앱 바 메뉴의 "환경 점검".
Future<void> showEnvironmentSheet(
  BuildContext context,
  EnvironmentStatus env,
  VoidCallback onRecheck, {
  VoidCallback? onLogin,
  ValueChanged<String>? onSetPath,
}) {
  return showActionSheet<void>(
    context,
    (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
        child: EnvironmentCard(
          environment: env,
          onRecheck: () {
            Navigator.pop(context);
            onRecheck();
          },
          onLogin: onLogin == null
              ? null
              : () {
                  Navigator.pop(context);
                  onLogin();
                },
          onSetPath: onSetPath == null
              ? null
              : (tool) {
                  Navigator.pop(context);
                  onSetPath(tool);
                },
        ),
      ),
    ),
  );
}

/// 파일을 열 편집기 명령 (PLAN.md 3.2). 비우면 OS 기본 앱.
Future<String?> showEditorCommandSheet(BuildContext context, String current) {
  final controller = TextEditingController(text: current);
  return showActionSheet<String>(context, (context) {
    final l10n = AppLocalizations.of(context);
    return StatefulBuilder(
      builder: (context, setState) => ActionSheetBody(
        title: l10n.editorTitle,
        commands: [
          if (controller.text.trim().isNotEmpty) [...controller.text.trim().split(RegExp(r'\s+')), '<file>'],
        ],
        confirmLabel: l10n.commonSave,
        onConfirm: () => Navigator.pop(context, controller.text.trim()),
        children: [
          Text(l10n.editorMessage, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: controller,
            autofocus: true,
            style: AppFonts.mono.copyWith(fontSize: 12),
            decoration: InputDecoration(labelText: l10n.editorLabel, hintText: 'code'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(spacing: 6, children: [
            for (final c in ['code', 'cursor', 'idea', 'subl', 'zed'])
              SmallChip(label: c, onPressed: () => setState(() => controller.text = c)),
          ]),
        ],
      ),
    );
  });
}
