import 'dart:io';

/// VS Code 받는 곳. 찾지 못하면 이 링크만 보여 준다.
final vscodeDownloadUrl = Uri.parse('https://code.visualstudio.com/');

/// 저장소 폴더를 VS Code로 여는 명령을 만든다. 찾지 못하면 null.
///
/// OS마다 설치 위치와 여는 방식이 다르다.
/// - macOS: `open -b com.microsoft.VSCode <dir>` — `code` 명령을 PATH에
///   설치하지 않아도 열린다. 앱이 흔한 위치에 없으면 Spotlight(`mdfind`)로 찾는다.
/// - Windows: 설치 폴더의 `bin\code.cmd` (사용자·시스템 설치), 그다음 PATH.
/// - Linux: PATH의 `code`, snap·deb 위치, 그다음 flatpak.
Future<List<String>?> vscodeOpenCommand(String dir, {required String path}) async {
  final os = Platform.isMacOS
      ? 'macos'
      : Platform.isWindows
          ? 'windows'
          : 'linux';
  final found = vscodeCommandFor(
    os: os,
    dir: dir,
    path: path,
    env: Platform.environment,
    exists: (p) => FileSystemEntity.typeSync(p) != FileSystemEntityType.notFound,
  );
  if (found != null || os != 'macos') return found;
  try {
    final r = await Process.run('mdfind', ["kMDItemCFBundleIdentifier == '$_macBundleId'"])
        .timeout(const Duration(seconds: 3));
    if (r.exitCode == 0 && (r.stdout as String).trim().isNotEmpty) return _macOpen(dir);
  } on Object {
    // Spotlight가 꺼져 있으면 설치되지 않은 것으로 본다.
  }
  return null;
}

const _macBundleId = 'com.microsoft.VSCode';
const _flatpakId = 'com.visualstudio.code';

List<String> _macOpen(String dir) => ['open', '-b', _macBundleId, dir];

/// [vscodeOpenCommand]에서 파일 확인만으로 끝나는 부분. [os]는 `macos`,
/// `windows`, `linux` 중 하나. 테스트에서 설치 상태를 흉내 낼 수 있게 나눴다.
List<String>? vscodeCommandFor({
  required String os,
  required String dir,
  required String path,
  required Map<String, String> env,
  required bool Function(String path) exists,
}) {
  final home = env['HOME'] ?? env['USERPROFILE'];
  switch (os) {
    case 'macos':
      final apps = [
        '/Applications/Visual Studio Code.app',
        if (home != null) '$home/Applications/Visual Studio Code.app',
      ];
      if (apps.any(exists)) return _macOpen(dir);
      final code = _onPath('code', path, ':', '/', exists);
      return code == null ? null : [code, dir];
    case 'windows':
      final installs = [
        if (env['LOCALAPPDATA'] case final local?) '$local\\Programs\\Microsoft VS Code',
        if (env['ProgramFiles'] case final pf?) '$pf\\Microsoft VS Code',
        if (env['ProgramFiles(x86)'] case final pf?) '$pf\\Microsoft VS Code',
      ];
      for (final i in installs) {
        final cmd = '$i\\bin\\code.cmd';
        if (exists(cmd)) return [cmd, dir];
      }
      final code = _onPath('code.cmd', path, ';', '\\', exists);
      return code == null ? null : [code, dir];
    default:
      final code = _onPath('code', path, ':', '/', exists) ??
          ['/snap/bin/code', '/usr/share/code/bin/code', '/usr/bin/code'].where(exists).firstOrNull;
      if (code != null) return [code, dir];
      final flatpaks = [
        '/var/lib/flatpak/app/$_flatpakId',
        if (home != null) '$home/.local/share/flatpak/app/$_flatpakId',
      ];
      if (flatpaks.any(exists)) return ['flatpak', 'run', _flatpakId, dir];
      return null;
  }
}

String? _onPath(String name, String path, String sep, String slash, bool Function(String) exists) {
  for (final d in path.split(sep)) {
    final dir = d.trim();
    if (dir.isEmpty) continue;
    final file = dir.endsWith(slash) ? '$dir$name' : '$dir$slash$name';
    if (exists(file)) return file;
  }
  return null;
}
