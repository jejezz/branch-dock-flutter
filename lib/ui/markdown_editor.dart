import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

/// 릴리스 노트 편집기 (UI_UX.md §4.5 ⑥): `편집 | 미리 보기`.
class MarkdownEditor extends StatefulWidget {
  const MarkdownEditor({super.key, required this.controller, this.label, this.minLines = 6});

  final TextEditingController controller;
  final String? label;
  final int minLines;

  @override
  State<MarkdownEditor> createState() => _MarkdownEditorState();
}

class _MarkdownEditorState extends State<MarkdownEditor> {
  bool _preview = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        if (widget.label != null) Expanded(child: Text(widget.label!, style: theme.textTheme.labelMedium)) else const Spacer(),
        SegmentedButton<bool>(
          showSelectedIcon: false,
          style: const ButtonStyle(visualDensity: VisualDensity.compact),
          segments: [
            ButtonSegment(value: false, label: Text(l10n.notesEditTab)),
            ButtonSegment(value: true, label: Text(l10n.notesPreviewTab)),
          ],
          selected: {_preview},
          onSelectionChanged: (s) => setState(() => _preview = s.first),
        ),
      ]),
      const SizedBox(height: AppSpacing.sm),
      if (_preview)
        Container(
          constraints: const BoxConstraints(minHeight: 120),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: widget.controller.text.trim().isEmpty
              ? Text(l10n.notesEmpty, style: theme.textTheme.bodySmall)
              : MarkdownBody(
                  data: widget.controller.text,
                  selectable: true,
                  styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                    p: theme.textTheme.bodyMedium?.merge(AppFonts.userContent),
                    code: AppFonts.mono.copyWith(fontSize: 12),
                  ),
                  onTapLink: (text, href, title) {
                    if (href != null) launchUrl(Uri.parse(href));
                  },
                ),
        )
      else
        TextField(
          controller: widget.controller,
          minLines: widget.minLines,
          maxLines: 18,
          style: AppFonts.mono.copyWith(fontSize: 12),
          decoration: const InputDecoration(),
        ),
    ]);
  }
}
