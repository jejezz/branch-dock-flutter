import 'package:flutter/material.dart';

import '../git/commands.dart';
import '../git/commits.dart';
import '../git/refs.dart';
import '../l10n/app_localizations.dart';
import '../repo/repo_controller.dart';
import '../theme/app_theme.dart';
import 'action_sheet.dart';
import 'help/concepts.dart';
import 'repo_actions.dart';
import 'widgets.dart';

/// 병합 미리 보기: 들어올 커밋과 fast-forward 가능 여부.
typedef MergePreview = ({List<Commit> commits, bool canFastForward});

Future<MergePreview> loadMergePreview(RepoController repo, Branch source) async {
  final incoming = await repo.read(GitCommands.incoming(source.name));
  final ff = await repo.read(GitCommands.isAncestor('HEAD', source.name));
  return (commits: incoming.ok ? Commit.parse(incoming.stdout) : const <Commit>[], canFastForward: ff.ok);
}

/// 다른 브랜치를 현재 브랜치로 병합 (PLAN.md 3.5): 방식 비교, 들어올 커밋 미리 보기.
Future<void> showMergeSheet(BuildContext context, RepoController repo, Branch source) async {
  final preview = await loadMergePreview(repo, source);
  if (!context.mounted) return;
  await showMergeSheetWith(context, repo, source, preview);
}

Future<void> showMergeSheetWith(BuildContext context, RepoController repo, Branch source, MergePreview preview) async {
  final l10n = AppLocalizations.of(context);
  if (preview.commits.isEmpty) {
    showDone(context, l10n.mergeNothing(source.name, repo.status.head ?? 'HEAD'));
    return;
  }
  await showActionSheet<void>(
    context,
    (context) =>
        _MergeSheet(repo: repo, source: source, commits: preview.commits, canFastForward: preview.canFastForward),
  );
}

class _MergeSheet extends StatefulWidget {
  const _MergeSheet({required this.repo, required this.source, required this.commits, required this.canFastForward});

  final RepoController repo;
  final Branch source;
  final List<Commit> commits;
  final bool canFastForward;

  @override
  State<_MergeSheet> createState() => _MergeSheetState();
}

class _MergeSheetState extends State<_MergeSheet> {
  late MergeMode _mode = widget.canFastForward ? MergeMode.fastForward : MergeMode.mergeCommit;
  late final _message = TextEditingController();

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

  String _defaultMessage(AppLocalizations l10n) => switch (_mode) {
        MergeMode.squash => widget.commits.length == 1 ? widget.commits.first.subject : 'feat: ${widget.source.shortName}',
        _ => "Merge branch '${widget.source.name}'",
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final into = widget.repo.status.head ?? 'HEAD';
    final message = _message.text.trim().isEmpty ? _defaultMessage(l10n) : _message.text.trim();
    final commands = GitCommands.merge(widget.source.name, _mode, message: _mode == MergeMode.fastForward ? '' : message);

    Widget option(MergeMode mode, String title, String when, Concept concept, {bool enabled = true, String? disabled}) {
      final selected = _mode == mode;
      return ListTile(
        enabled: enabled,
        contentPadding: const EdgeInsets.only(left: 4),
        leading: Icon(selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
            color: selected ? theme.colorScheme.primary : null),
        title: Text(title),
        subtitle: Text(enabled ? when : disabled ?? when),
        trailing: HelpButton(concept: concept),
        onTap: enabled ? () => setState(() => _mode = mode) : null,
      );
    }

    Future<void> submit() async {
      Navigator.pop(context);
      await RepoActions.report(
        context,
        widget.repo.executeAll(commands),
        done: l10n.doneMerge(widget.source.name, into),
      );
    }

    return ActionSheetBody(
      title: l10n.mergeTitle(widget.source.name, into),
      commands: commands,
      confirmLabel: l10n.mergeConfirm,
      onConfirm: submit,
      children: [
        Text(l10n.mergeIncoming(widget.commits.length), style: theme.textTheme.labelMedium),
        const SizedBox(height: 4),
        Container(
          constraints: const BoxConstraints(maxHeight: 140),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 4),
            children: [
              for (final c in widget.commits.take(20))
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 2),
                  child: Text.rich(
                    TextSpan(children: [
                      TextSpan(text: '${c.shortHash}  ', style: AppFonts.mono.copyWith(fontSize: 11.5)),
                      TextSpan(text: c.subject),
                    ]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.merge(AppFonts.userContent),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        option(MergeMode.fastForward, l10n.mergeFastForward, l10n.mergeFastForwardWhen, Concept.fastForward,
            enabled: widget.canFastForward, disabled: l10n.mergeFastForwardDisabled),
        option(MergeMode.mergeCommit, l10n.mergeMergeCommit, l10n.mergeMergeCommitWhen, Concept.mergeCommit),
        option(MergeMode.squash, l10n.mergeSquash, l10n.mergeSquashWhen, Concept.squash),
        if (_mode != MergeMode.fastForward) ...[
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _message,
            style: AppFonts.userContent.copyWith(fontSize: 13),
            decoration: InputDecoration(labelText: l10n.mergeMessageLabel, hintText: _defaultMessage(l10n)),
          ),
        ],
        if (_mode == MergeMode.squash) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(l10n.mergeSquashNote(widget.source.name), style: theme.textTheme.bodySmall),
        ],
      ],
    );
  }
}
