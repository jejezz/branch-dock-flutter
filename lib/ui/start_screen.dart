import 'dart:io';

import 'package:flutter/material.dart';

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
            EnvironmentCard(environment: env, onRecheck: onCheckEnvironment)
          else ...[
            if (failure != null)
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
                child: Text(
                  failure == OpenFailure.notARepository
                      ? l10n.startNotARepository(failedPath ?? '')
                      : l10n.startNotFound(failedPath ?? ''),
                ),
              ),
            EmptyState(
              icon: Icons.folder_open_rounded,
              title: l10n.homeEmptyTitle,
              message: l10n.startDropHint,
              action: FilledButton.icon(
                onPressed: env.hasGit ? onOpenFolder : null,
                icon: const Icon(Icons.folder_open_rounded, size: 16),
                label: Text('${l10n.homeEmptyAction}  ${shortcutLabel('O')}'),
              ),
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
              EnvironmentCard(environment: env, onRecheck: onCheckEnvironment),
            ],
          ],
        ],
      ),
    );
  }
}

/// 환경 점검 체크리스트 (UI_UX.md §8): 항목별 ✓/✕, 설치·로그인 명령 복사.
class EnvironmentCard extends StatelessWidget {
  const EnvironmentCard({super.key, required this.environment, required this.onRecheck});

  final EnvironmentStatus environment;
  final VoidCallback onRecheck;

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

    Widget item(bool ok, String title, String detail, {String? command}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(ok ? Icons.check_circle_rounded : Icons.cancel_rounded,
                size: 18, color: toneColor(context, ok ? Tone.success : Tone.danger)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: theme.textTheme.titleSmall),
                Text(detail, style: theme.textTheme.bodySmall),
                if (!ok && command != null) ...[
                  const SizedBox(height: 4),
                  Row(children: [
                    Expanded(child: SelectableText(command, style: AppFonts.mono.copyWith(fontSize: 12))),
                    CopyButton(text: command, size: 14),
                  ]),
                ],
              ]),
            ),
          ]),
        );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.tile),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l10n.envTitle, style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(env.hasGit ? l10n.envGitOnlyNote : l10n.envGitRequired, style: theme.textTheme.bodySmall),
        const SizedBox(height: AppSpacing.sm),
        item(env.hasGit, 'git', env.hasGit ? l10n.envVersion(env.gitVersion!) : l10n.envNotInstalled,
            command: install('git')),
        item(env.hasGh, 'gh (GitHub CLI)', env.hasGh ? l10n.envVersion(env.ghVersion!) : l10n.envNotInstalled,
            command: install('gh')),
        if (env.hasGh)
          item(env.ghLoggedIn, l10n.envLogin,
              env.ghLoggedIn ? l10n.envLoggedInAs(env.ghLogins['github.com'] ?? '') : l10n.envNotLoggedIn,
              command: 'gh auth login'),
        const SizedBox(height: AppSpacing.sm),
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton.icon(
            onPressed: onRecheck,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: Text(l10n.envRecheck),
          ),
        ),
      ]),
    );
  }
}

/// 앱 바 메뉴의 "환경 점검".
Future<void> showEnvironmentSheet(BuildContext context, EnvironmentStatus env, VoidCallback onRecheck) {
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
