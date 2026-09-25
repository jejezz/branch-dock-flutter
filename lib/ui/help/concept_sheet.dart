import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import 'commit_graph.dart';
import 'concepts.dart';

/// 개념 카드 시트 (UI_UX.md §6.1): 낱말 뜻 ↓ git에서는 → 왜·언제 → 그림 → 링크.
Future<void> showConceptSheet(BuildContext context, Concept concept) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.85),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet))),
    builder: (context) => _ConceptSheet(concept: concept),
  );
}

class _ConceptSheet extends StatelessWidget {
  const _ConceptSheet({required this.concept});

  final Concept concept;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final card = conceptCard(l10n, concept);

    Widget block(String label, String body, {IconData? icon}) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              if (icon != null) ...[Icon(icon, size: 14, color: theme.colorScheme.primary), const SizedBox(width: 6)],
              Text(label, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.primary)),
            ]),
            const SizedBox(height: 4),
            Text(body, style: theme.textTheme.bodyMedium?.copyWith(height: 1.5)),
          ],
        );

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(card.title, style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.lg),
          block(l10n.helpSectionWord, card.word, icon: Icons.menu_book_rounded),
          // 두 뜻이 이어진다는 것을 눈으로 보여 준다.
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Icon(Icons.arrow_downward_rounded, size: 18, color: theme.colorScheme.onSurfaceVariant),
          ),
          block(l10n.helpSectionInGit, card.inGit, icon: Icons.call_split_rounded),
          const SizedBox(height: AppSpacing.lg),
          block(l10n.helpSectionWhy, card.why, icon: Icons.lightbulb_outline_rounded),
          const SizedBox(height: AppSpacing.lg),
          for (final scene in card.scenes) ...[
            Text(scene.caption, style: theme.textTheme.labelMedium),
            const SizedBox(height: 4),
            CommitGraph(scene: scene),
            const SizedBox(height: AppSpacing.md),
          ],
          Text(l10n.helpSectionLinks, style: theme.textTheme.labelMedium),
          for (final link in card.links)
            TextButton.icon(
              style: TextButton.styleFrom(padding: EdgeInsets.zero, alignment: Alignment.centerLeft),
              onPressed: () => launchUrl(Uri.parse(link.url)),
              icon: const Icon(Icons.open_in_new_rounded, size: 14),
              label: Text(link.title),
            ),
        ]),
      ),
    );
  }
}
