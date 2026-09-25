import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'command_log.dart';

/// 명령 실행 결과.
class CommandResult {
  const CommandResult(this.exitCode, this.stdout, this.stderr);

  final int exitCode;
  final String stdout;
  final String stderr;

  bool get ok => exitCode == 0;

  /// 오류 설명에 쓰는 합친 출력.
  String get combined => [stdout, stderr].where((s) => s.trim().isNotEmpty).join('\n');
}

/// 취소 가능한 실행 핸들.
class CancelToken {
  Process? _process;
  bool _cancelled = false;

  bool get cancelled => _cancelled;

  void cancel() {
    _cancelled = true;
    _process?.kill();
  }
}

const _utf8 = Utf8Codec(allowMalformed: true);

/// `git`, `gh`를 셸 없이 인자 목록으로 실행한다 (PLAN.md §5).
///
/// - macOS GUI 앱은 로그인 셸의 PATH를 받지 못하므로 [resolvePath]가 만든
///   PATH를 모든 프로세스에 넘긴다. `gh`가 git 인증 도우미로 다시 불릴 때도
///   같은 PATH가 필요하다.
/// - 대화형 프롬프트를 막는다. 입력이 필요한 작업은 앱이 먼저 값을 받는다.
class CommandRunner {
  CommandRunner({required this.log, required this.path});

  final CommandLog log;

  /// [resolvePath]가 만든 PATH.
  String path;

  Map<String, String> _env(String executable) => {
        'PATH': path,
        'GIT_TERMINAL_PROMPT': '0',
        'GIT_EDITOR': 'true',
        'GH_PROMPT_DISABLED': '1',
        'GH_NO_UPDATE_NOTIFIER': '1',
        // 오류 문구를 영어로 고정해야 오류 설명(error_hints.dart)이 맞는다.
        // 내용(커밋 메시지, 파일 이름)은 바이트 그대로라 영향이 없다.
        if (executable == 'git') 'LC_ALL': 'C',
        if (executable == 'gh') 'NO_COLOR': '1',
      };

  /// 명령을 실행하고 로그에 남긴다. [quiet]면 로그에 남기지 않는다
  /// (상태 새로 고침처럼 자주 도는 읽기 명령).
  Future<CommandResult> run(
    List<String> args, {
    required String workingDirectory,
    bool quiet = false,
    CancelToken? cancel,
    String? stdin,
  }) async {
    final entry = quiet ? null : log.start(args);
    final watch = Stopwatch()..start();
    try {
      final process = await Process.start(
        args.first,
        args.sublist(1),
        workingDirectory: workingDirectory,
        environment: _env(args.first),
        runInShell: Platform.isWindows,
      );
      cancel?._process = process;
      if (stdin != null) {
        process.stdin.add(_utf8.encode(stdin));
      }
      await process.stdin.close();

      final out = StringBuffer();
      final err = StringBuffer();
      final outDone = process.stdout.transform(_utf8.decoder).listen((chunk) {
        out.write(chunk);
        if (entry != null) {
          entry.append(chunk);
          log.update();
        }
      }).asFuture<void>();
      final errDone = process.stderr.transform(_utf8.decoder).listen((chunk) {
        err.write(chunk);
        if (entry != null) {
          entry.append(chunk);
          log.update();
        }
      }).asFuture<void>();
      final code = await process.exitCode;
      await Future.wait([outDone, errDone]);
      if (entry != null) {
        entry
          ..exitCode = code
          ..cancelled = cancel?.cancelled ?? false
          ..duration = watch.elapsed;
        log.update();
      }
      return CommandResult(code, out.toString(), err.toString());
    } on ProcessException catch (e) {
      entry
        ?..append(e.message)
        ..exitCode = 127
        ..duration = watch.elapsed;
      log.update();
      return CommandResult(127, '', e.message);
    }
  }
}

/// `git`, `gh`를 찾을 PATH를 만든다.
///
/// 순서: 이 프로세스의 PATH → 로그인 셸의 PATH(macOS·Linux) → 흔한 설치 위치.
/// Finder에서 띄운 macOS 앱의 PATH는 `/usr/bin:/bin:/usr/sbin:/sbin`뿐이라
/// Homebrew로 설치한 `gh`를 찾지 못한다.
Future<String> resolvePath() async {
  final sep = Platform.isWindows ? ';' : ':';
  final parts = <String>[];
  void addAll(String? value) {
    if (value == null) return;
    for (final p in value.split(sep)) {
      final t = p.trim();
      if (t.isNotEmpty && !parts.contains(t)) parts.add(t);
    }
  }

  addAll(Platform.environment['PATH']);
  if (!Platform.isWindows) {
    final shell = Platform.environment['SHELL'] ?? '/bin/zsh';
    try {
      final r = await Process.run(shell, ['-lc', r'printf %s "$PATH"'])
          .timeout(const Duration(seconds: 3));
      if (r.exitCode == 0) addAll(r.stdout as String);
    } on Object {
      // 셸이 느리거나 없으면 흔한 위치로 충분하다.
    }
    addAll(['/opt/homebrew/bin', '/usr/local/bin', '/usr/bin', '/bin', '/home/linuxbrew/.linuxbrew/bin']
        .join(sep));
  } else {
    final pf = Platform.environment['ProgramFiles'] ?? r'C:\Program Files';
    final local = Platform.environment['LOCALAPPDATA'];
    addAll([
      '$pf\\Git\\cmd',
      '$pf\\GitHub CLI',
      if (local != null) '$local\\Microsoft\\WinGet\\Links',
    ].join(sep));
  }
  return parts.join(sep);
}
