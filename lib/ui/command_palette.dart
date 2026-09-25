import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

/// 명령 팔레트 항목 (PLAN.md 3.12 P2).
class PaletteItem {
  const PaletteItem({
    required this.title,
    required this.onRun,
    this.icon = Icons.chevron_right_rounded,
    this.group = '',
    this.shortcut,
    this.keywords = '',
    this.enabled = true,
  });

  final String title;
  final VoidCallback onRun;
  final IconData icon;

  /// 묶음 이름 (동작 / 탭 / 브랜치 / 저장소). 오른쪽에 흐리게 보인다.
  final String group;
  final String? shortcut;

  /// 검색에만 쓰는 말 (영어 명령 이름 등).
  final String keywords;
  final bool enabled;

  /// 검색어의 낱말이 모두 제목·묶음·키워드 안에 있으면 맞다 (대소문자 무시).
  bool matches(String query) {
    final hay = '$title $group $keywords'.toLowerCase();
    return query.toLowerCase().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).every(hay.contains);
  }
}

/// ⌘K: 위에서 떨어지는 검색 상자. ↑↓로 고르고 Enter로 실행, Esc로 닫는다.
Future<void> showCommandPalette(BuildContext context, List<PaletteItem> items) async {
  final chosen = await showDialog<PaletteItem>(
    context: context,
    barrierColor: Colors.black26,
    builder: (context) => _Palette(items: items),
  );
  chosen?.onRun();
}

class _Palette extends StatefulWidget {
  const _Palette({required this.items});

  final List<PaletteItem> items;

  @override
  State<_Palette> createState() => _PaletteState();
}

class _PaletteState extends State<_Palette> {
  final _query = TextEditingController();
  final _scroll = ScrollController();
  int _index = 0;

  List<PaletteItem> get _matches => widget.items.where((i) => i.enabled && i.matches(_query.text)).toList();

  @override
  void initState() {
    super.initState();
    _query.addListener(() => setState(() => _index = 0));
  }

  @override
  void dispose() {
    _query.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _move(int delta) {
    final n = _matches.length;
    if (n == 0) return;
    setState(() => _index = (_index + delta) % n < 0 ? n - 1 : (_index + delta) % n);
    // 고른 항목이 보이게 스크롤한다 (행 높이 40).
    final target = _index * 40.0;
    if (_scroll.hasClients) {
      final view = _scroll.position.viewportDimension;
      if (target < _scroll.offset) _scroll.jumpTo(target);
      if (target + 40 > _scroll.offset + view) _scroll.jumpTo(target + 40 - view);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final matches = _matches;
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 56, left: AppSpacing.md, right: AppSpacing.md),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 520, maxHeight: MediaQuery.sizeOf(context).height * 0.7),
          child: Material(
            color: theme.colorScheme.surfaceContainerHighest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.tile),
              side: BorderSide(color: theme.colorScheme.outline),
            ),
            clipBehavior: Clip.antiAlias,
            child: CallbackShortcuts(
              bindings: {
                const SingleActivator(LogicalKeyboardKey.arrowDown): () => _move(1),
                const SingleActivator(LogicalKeyboardKey.arrowUp): () => _move(-1),
                const SingleActivator(LogicalKeyboardKey.escape): () => Navigator.pop(context),
              },
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(
                  controller: _query,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: l10n.paletteHint,
                    prefixIcon: const Icon(Icons.search_rounded, size: 18),
                    border: InputBorder.none,
                    filled: false,
                  ),
                  onSubmitted: (_) {
                    if (matches.isNotEmpty) Navigator.pop(context, matches[_index.clamp(0, matches.length - 1)]);
                  },
                ),
                const Divider(height: 1),
                Flexible(
                  child: matches.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Text(l10n.paletteEmpty, style: theme.textTheme.bodySmall),
                        )
                      : ListView.builder(
                          controller: _scroll,
                          shrinkWrap: true,
                          itemExtent: 40,
                          itemCount: matches.length,
                          itemBuilder: (context, i) {
                            final item = matches[i];
                            final selected = i == _index;
                            return InkWell(
                              onTap: () => Navigator.pop(context, item),
                              child: Container(
                                color: selected ? theme.colorScheme.primary.withValues(alpha: 0.14) : null,
                                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                                child: Row(children: [
                                  Icon(item.icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Text(item.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.bodyMedium?.merge(AppFonts.userContent)),
                                  ),
                                  if (item.shortcut != null)
                                    Padding(
                                      padding: const EdgeInsets.only(left: AppSpacing.sm),
                                      child: Text(item.shortcut!, style: theme.textTheme.labelSmall),
                                    ),
                                  if (item.group.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(left: AppSpacing.sm),
                                      child: Text(item.group, style: theme.textTheme.labelSmall),
                                    ),
                                ]),
                              ),
                            );
                          },
                        ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
