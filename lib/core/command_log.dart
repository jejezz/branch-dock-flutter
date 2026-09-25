import 'package:flutter/foundation.dart';

/// 앱이 실행한 명령 하나 — 명령 바와 로그 패널에 보인다 (PLAN.md 3.12).
class CommandLogEntry {
  CommandLogEntry({required this.args, required this.started});

  /// 실행 파일 이름(`git`, `gh`)을 포함한 전체 인자.
  final List<String> args;
  final DateTime started;

  final StringBuffer _output = StringBuffer();
  int? exitCode;
  Duration? duration;
  bool cancelled = false;

  bool get running => exitCode == null && !cancelled;
  bool get succeeded => exitCode == 0;
  String get output => _output.toString();

  /// 사람이 읽고 복사해서 터미널에 붙여 넣을 수 있는 형태.
  String get commandLine => formatCommandLine(args);

  void append(String text) => _output.write(text);
}

/// 셸에 그대로 붙여 넣을 수 있도록 공백·특수 문자가 있는 인자만 따옴표로 감싼다.
String formatCommandLine(List<String> args) => args.map(_quote).join(' ');

final _safe = RegExp(r'^[A-Za-z0-9_\-./:=@,+%^~]+$');

String _quote(String arg) {
  if (arg.isNotEmpty && _safe.hasMatch(arg)) return arg;
  return "'${arg.replaceAll("'", r"'\''")}'";
}

/// 최근 명령 기록. 오래된 것부터 버린다.
class CommandLog extends ChangeNotifier {
  CommandLog({this.capacity = 200});

  final int capacity;
  final List<CommandLogEntry> _entries = [];

  List<CommandLogEntry> get entries => List.unmodifiable(_entries);
  CommandLogEntry? get last => _entries.isEmpty ? null : _entries.last;

  CommandLogEntry start(List<String> args) {
    final entry = CommandLogEntry(args: args, started: DateTime.now());
    _entries.add(entry);
    if (_entries.length > capacity) _entries.removeAt(0);
    notifyListeners();
    return entry;
  }

  void update() => notifyListeners();

  void clear() {
    _entries.clear();
    notifyListeners();
  }
}
