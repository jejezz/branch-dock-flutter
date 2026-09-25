import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../git/commands.dart';
import '../../git/history.dart';
import '../../l10n/app_localizations.dart';
import '../../repo/repo_controller.dart';
import '../../theme/app_theme.dart';
import '../repo_scope.dart';
import '../widgets.dart';
import 'branches_tab.dart';
import 'tags_tab.dart';

/// 기록 탭 (PLAN.md 3.11): 현재 브랜치의 커밋 목록. 브랜치·태그 표시, 아직
/// 올리지 않은 커밋 강조. 커밋 메뉴에서 여기서 브랜치 만들기·태그 달기.
class HistoryTab extends StatefulWidget {
  const HistoryTab({super.key});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  List<LogEntry>? _entries;
  Set<String> _unpushed = const {};
  String? _loadedFor;
  bool _loading = false;

  Future<void> _load(RepoController repo) async {
    if (_loading) return;
    _loading = true;
    final key = '${repo.status.head}@${repo.status.oid}';
    final results = await Future.wait([
      repo.read(GitCommands.history()),
      if (repo.status.hasUpstream) repo.read(GitCommands.unpushed),
    ]);
    _loading = false;
    if (!mounted) return;
    setState(() {
      _entries = results[0].ok ? LogEntry.parse(results[0].stdout) : const [];
      _unpushed = results.length > 1 && results[1].ok
          ? results[1].stdout.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toSet()
          : const {};
      _loadedFor = key;
    });
  }

  @override
  Widget build(BuildContext context) {
    final repo = RepoScope.of(context);
    final l10n = AppLocalizations.of(context);
    final key = '${repo.status.head}@${repo.status.oid}';
    // 커밋·전환·pull로 HEAD가 바뀌면 다시 읽는다.
    if (key != _loadedFor && !_loading && !repo.status.unborn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _load(repo);
      });
    }
    if (repo.status.unborn) {
      return EmptyState(icon: Icons.history_rounded, title: l10n.branchesUnbornTitle);
    }
    final entries = _entries;
    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      children: [
        SectionHeader(
          title: l10n.historyTitle,
          trailing: Text(
            _unpushed.isEmpty ? '' : l10n.historyUnpushed(_unpushed.length),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(color: toneColor(context, Tone.primary)),
          ),
        ),
        if (entries == null)
          const Padding(padding: EdgeInsets.all(AppSpacing.xl), child: Center(child: CircularProgressIndicator()))
        else
          for (final e in entries) _CommitRow(entry: e, unpushed: _unpushed.contains(e.hash), repo: repo),
      ],
    );
  }
}

enum _CommitMenu { copy, branch, tag, github }

class _CommitRow extends StatelessWidget {
  const _CommitRow({required this.entry, required this.unpushed, required this.repo});

  final LogEntry entry;
  final bool unpushed;
  final RepoController repo;

  Future<void> _onMenu(BuildContext context, _CommitMenu m) async {
    final l10n = AppLocalizations.of(context);
    switch (m) {
      case _CommitMenu.copy:
        await Clipboard.setData(ClipboardData(text: entry.hash));
        if (context.mounted) showDone(context, l10n.commonCopied);
      case _CommitMenu.branch:
        await showCreateBranchSheet(context, repo, base: entry.shortHash);
      case _CommitMenu.tag:
        await showCreateTagSheet(context, repo, target: entry.shortHash);
      case _CommitMenu.github:
        final loc = repo.githubRemote?.location;
        if (loc != null) await launchUrl(Uri.parse('${loc.webUrl}/commit/${entry.hash}'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final e = entry;
    final primary = toneColor(context, Tone.primary);
    return Container(
      decoration: BoxDecoration(
        // 아직 올리지 않은 커밋은 왼쪽 줄로 강조한다.
        border: Border(left: BorderSide(color: unpushed ? primary : Colors.transparent, width: 3)),
      ),
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 5, 0, 5),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(e.shortHash,
              style: AppFonts.mono.copyWith(fontSize: 11.5, color: unpushed ? primary : theme.colorScheme.onSurfaceVariant)),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(e.subject, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppFonts.userContent.copyWith(fontSize: 13)),
            if (e.branches.isNotEmpty || e.tags.isNotEmpty || e.isHead) ...[
              const SizedBox(height: 3),
              Wrap(spacing: 4, runSpacing: 4, children: [
                if (e.isHead && e.branches.isEmpty) StatusPill(label: 'HEAD', tone: Tone.warning),
                for (final b in e.branches)
                  StatusPill(label: b, tone: b.contains('/') ? Tone.neutral : Tone.primary, icon: Icons.call_split_rounded),
                for (final t in e.tags) StatusPill(label: t, tone: Tone.success, icon: Icons.sell_outlined),
              ]),
            ],
            const SizedBox(height: 2),
            Text('${e.author} · ${relativeTime(l10n, e.date)}${unpushed ? ' · ${l10n.historyNotPushed}' : ''}',
                style: theme.textTheme.labelSmall),
          ]),
        ),
        PopupMenuButton<_CommitMenu>(
          tooltip: l10n.commonMore,
          icon: const Icon(Icons.more_horiz_rounded, size: 18),
          enabled: !repo.busy,
          onSelected: (m) => _onMenu(context, m),
          itemBuilder: (context) => [
            PopupMenuItem(value: _CommitMenu.copy, child: Text(l10n.historyCopyHash)),
            PopupMenuItem(value: _CommitMenu.branch, child: Text(l10n.historyBranchHere)),
            PopupMenuItem(value: _CommitMenu.tag, child: Text(l10n.historyTagHere)),
            if (repo.githubRemote != null) PopupMenuItem(value: _CommitMenu.github, child: Text(l10n.prOpenOnGitHub)),
          ],
        ),
      ]),
    );
  }
}
