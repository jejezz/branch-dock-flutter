import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../core/command_runner.dart';
import '../l10n/app_localizations.dart';
import '../repo/environment.dart';
import '../theme/app_theme.dart';
import 'action_sheet.dart';
import 'widgets.dart';

/// git / gh 실행 파일을 직접 지정한다 (PLAN.md 3.14). 저장하기 전에 그 파일이
/// 정말 [tool]인지 `--version`으로 확인한다. 돌려주는 값: 저장하지 않았으면 null,
/// PATH에서 찾기로 되돌렸으면 빈 문자열, 아니면 경로.
Future<String?> showToolPathSheet(BuildContext context, {required String tool, required CommandRunner runner, String? current}) {
  return showActionSheet<String>(context, (context) => _ToolPathSheet(tool: tool, runner: runner, current: current));
}

class _ToolPathSheet extends StatefulWidget {
  const _ToolPathSheet({required this.tool, required this.runner, this.current});

  final String tool;
  final CommandRunner runner;
  final String? current;

  @override
  State<_ToolPathSheet> createState() => _ToolPathSheetState();
}

class _ToolPathSheetState extends State<_ToolPathSheet> {
  late final _path = TextEditingController(text: widget.current ?? '');

  /// 확인한 경로와 그 결과. 입력이 바뀌면 다시 확인해야 한다.
  String? _checkedPath;
  String? _version;
  bool _checking = false;

  String get _text => _path.text.trim();
  bool get _checked => _checkedPath == _text;

  @override
  void initState() {
    super.initState();
    _path.addListener(() => setState(() {}));
    if (_text.isNotEmpty) _verify();
  }

  @override
  void dispose() {
    _path.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final path = _text;
    if (path.isEmpty) return;
    setState(() => _checking = true);
    final version = await EnvironmentStatus.probe(widget.runner, widget.tool, path, Directory.systemTemp.path);
    if (!mounted) return;
    setState(() {
      _checking = false;
      _checkedPath = path;
      _version = version;
    });
  }

  Future<void> _browse() async {
    final file = await openFile(initialDirectory: _text.isEmpty ? null : File(_text).parent.path);
    if (file == null || !mounted) return;
    _path.text = file.path;
    await _verify();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final tool = widget.tool;
    final empty = _text.isEmpty;
    final ok = _checked && _version != null;
    final String? status = empty
        ? null
        : _checking
            ? null
            : !_checked
                ? l10n.toolPathNeedsCheck
                : ok
                    ? l10n.toolPathOk(tool, _version!)
                    : l10n.toolPathBad(tool);

    return ActionSheetBody(
      title: l10n.toolPathTitle(tool),
      commands: [if (!empty) [_text, '--version']],
      confirmLabel: l10n.commonSave,
      // 비우면 PATH에서 찾기로 되돌린다. 경로는 확인을 통과해야 저장한다.
      onConfirm: empty || ok ? () => Navigator.pop(context, _text) : null,
      children: [
        Text(l10n.toolPathWhy(tool), style: theme.textTheme.bodySmall),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _path,
          autofocus: true,
          style: AppFonts.mono.copyWith(fontSize: 12),
          decoration: InputDecoration(
            labelText: l10n.toolPathLabel,
            hintText: Platform.isWindows ? r'C:\Program Files\Git\cmd\git.exe' : '/opt/homebrew/bin/$tool',
            suffixIcon: IconButton(
              tooltip: l10n.toolPathBrowse,
              icon: const Icon(Icons.folder_open_rounded, size: 18),
              onPressed: _browse,
            ),
          ),
          onSubmitted: (_) => _verify(),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(children: [
          if (_checking)
            const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
          else if (status != null)
            Icon(ok ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                size: 16, color: toneColor(context, ok ? Tone.success : (_checked ? Tone.danger : Tone.warning))),
          const SizedBox(width: 6),
          Expanded(child: Text(status ?? '', style: theme.textTheme.bodySmall)),
          TextButton(onPressed: empty || _checking ? null : _verify, child: Text(l10n.toolPathVerify)),
        ]),
        if (!empty)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _path.clear(),
              icon: const Icon(Icons.search_rounded, size: 16),
              label: Text(l10n.toolPathUsePath),
            ),
          ),
      ],
    );
  }
}
