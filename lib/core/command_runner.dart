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
  CommandRunner({required this.log, required this.path, this.gitPath, this.ghPath});

  final CommandLog log;

  /// [resolvePath]가 만든 PATH.
  String path;

  /// 설정에서 직접 지정한 실행 파일 (PLAN.md 3.14). null이면 PATH에서 찾는다.
  String? gitPath;
  String? ghPath;

  /// 명령 이름(`git`, `gh`)을 실제로 실행할 파일로 바꾼다.
  String executableFor(String name) => switch (name) {
        'git' => gitPath ?? name,
        'gh' => ghPath ?? name,
        'bash' when Platform.isWindows => gitBashPath() ??
            (throw const ProcessException(
              'bash',
              [],
              'Git for Windows의 bash를 찾을 수 없습니다. Git을 설치하거나 설정에서 git 경로를 지정하세요.',
            )),
        _ => name,
      };

  /// Windows에서 PATH의 `bash`는 WSL의 `System32\bash.exe`가 먼저 잡히는 일이 많다.
  /// WSL의 git은 `core.autocrlf` 설정이 달라 CRLF 파일을 모두 수정됨으로 보므로
  /// (bump-version.sh의 깨끗한 트리 검사가 실패한다), git과 같은 설치의 bash만 쓴다.
  /// 찾지 못해도 PATH의 bash로 되돌아가지 않는다.
  String? gitBashPath() {
    final sep = Platform.pathSeparator;
    final git = gitPath ?? findExecutable('git', path);
    if (git != null) {
      var dir = File(git).parent;
      for (var i = 0; i < 3; i++) {
        final bash = File('${dir.path}${sep}bin${sep}bash.exe');
        if (bash.existsSync()) return bash.path;
        dir = dir.parent;
      }
    }
    // git이 shim(scoop 등)이거나 PATH에 없을 때의 표준 설치 위치.
    for (final base in [
      Platform.environment['ProgramFiles'],
      Platform.environment['ProgramW6432'],
      Platform.environment['ProgramFiles(x86)'],
      if (Platform.environment['LOCALAPPDATA'] case final l?) '$l${sep}Programs',
    ]) {
      if (base == null) continue;
      final bash = File('$base${sep}Git${sep}bin${sep}bash.exe');
      if (bash.existsSync()) return bash.path;
    }
    return null;
  }

  /// 프로세스에 넘기는 PATH. 지정한 실행 파일의 폴더를 앞에 둔다 — `gh`가 git을
  /// 부르거나 git이 인증 도우미로 `gh`를 부를 때도 같은 파일을 쓰게 한다.
  String get effectivePath {
    final sep = Platform.isWindows ? ';' : ':';
    final dirs = [
      for (final p in [gitPath, ghPath])
        if (p != null) File(p).parent.path,
    ];
    return [...dirs.toSet(), path].join(sep);
  }

  Map<String, String> _env(String executable) => {
        'PATH': effectivePath,
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
        executableFor(args.first),
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

/// [path]의 폴더들에서 [name] 실행 파일을 찾아 전체 경로를 돌려준다. 없으면 null.
/// Windows에서는 `.exe`를 먼저, 그다음 `.cmd`·`.bat`를 찾는다.
String? findExecutable(String name, String path) {
  final windows = Platform.isWindows;
  final names = windows ? ['$name.exe', '$name.cmd', '$name.bat'] : [name];
  for (final ext in names) {
    for (final dir in path.split(windows ? ';' : ':')) {
      if (dir.trim().isEmpty) continue;
      final file = File('${dir.trim()}${Platform.pathSeparator}$ext');
      if (file.existsSync()) return file.path;
    }
  }
  return null;
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
