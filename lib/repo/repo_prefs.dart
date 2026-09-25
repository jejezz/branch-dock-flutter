import 'dart:ui';

import 'package:shared_preferences/shared_preferences.dart';

import '../git/commands.dart';

/// 저장소별 기억할 값과 앱 설정 (PLAN.md §5 저장).
class RepoPrefs {
  RepoPrefs(this._prefs);

  static Future<RepoPrefs> load() async => RepoPrefs(await SharedPreferences.getInstance());

  final SharedPreferences _prefs;

  static const _recentKey = 'recent_repos';
  static const _editorKey = 'editor_command';
  static const _boundsKey = 'window_bounds';
  static const maxRecent = 10;

  List<String> get recent => _prefs.getStringList(_recentKey) ?? const [];

  Future<void> addRecent(String path) async {
    final list = [path, ...recent.where((p) => p != path)].take(maxRecent).toList();
    await _prefs.setStringList(_recentKey, list);
  }

  Future<void> removeRecent(String path) =>
      _prefs.setStringList(_recentKey, recent.where((p) => p != path).toList());

  PullMode pullMode(String repo) =>
      PullMode.values.asNameMap()[_prefs.getString('pull_mode:$repo')] ?? PullMode.merge;

  Future<void> setPullMode(String repo, PullMode mode) => _prefs.setString('pull_mode:$repo', mode.name);

  int lastTab(String repo) => _prefs.getInt('last_tab:$repo') ?? 0;
  Future<void> setLastTab(String repo, int tab) => _prefs.setInt('last_tab:$repo', tab);

  /// 파일을 여는 편집기 명령(예: `code`). 비어 있으면 OS 기본 앱.
  String get editorCommand => _prefs.getString(_editorKey) ?? '';
  Future<void> setEditorCommand(String command) => _prefs.setString(_editorKey, command.trim());

  /// 창 크기·위치 (UI_UX.md §2: 필수).
  Rect? get windowBounds {
    final v = _prefs.getStringList(_boundsKey);
    if (v == null || v.length != 4) return null;
    final n = v.map(double.tryParse).toList();
    if (n.contains(null)) return null;
    return Rect.fromLTWH(n[0]!, n[1]!, n[2]!, n[3]!);
  }

  Future<void> setWindowBounds(Rect r) =>
      _prefs.setStringList(_boundsKey, [r.left, r.top, r.width, r.height].map((d) => d.toStringAsFixed(0)).toList());
}
