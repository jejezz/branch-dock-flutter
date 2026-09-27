import 'package:branch_dock/core/vscode.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  List<String>? find(String os, Set<String> files, {String path = '', Map<String, String> env = const {}}) =>
      vscodeCommandFor(os: os, dir: '/repo', path: path, env: env, exists: files.contains);

  group('macOS', () {
    test('앱이 있으면 번들 ID로 연다 (code 명령이 없어도)', () {
      expect(find('macos', {'/Applications/Visual Studio Code.app'}),
          ['open', '-b', 'com.microsoft.VSCode', '/repo']);
      expect(find('macos', {'/Users/me/Applications/Visual Studio Code.app'}, env: {'HOME': '/Users/me'}),
          ['open', '-b', 'com.microsoft.VSCode', '/repo']);
    });

    test('앱이 다른 곳에 있으면 PATH의 code를 쓴다', () {
      expect(find('macos', {'/opt/homebrew/bin/code'}, path: '/usr/bin:/opt/homebrew/bin'),
          ['/opt/homebrew/bin/code', '/repo']);
    });

    test('없으면 null', () => expect(find('macos', {}, path: '/usr/bin'), isNull));
  });

  group('Windows', () {
    const env = {'LOCALAPPDATA': r'C:\Users\me\AppData\Local', 'ProgramFiles': r'C:\Program Files'};

    test('사용자 설치를 먼저 찾는다', () {
      expect(
        find('windows', {
          r'C:\Users\me\AppData\Local\Programs\Microsoft VS Code\bin\code.cmd',
          r'C:\Program Files\Microsoft VS Code\bin\code.cmd',
        }, env: env),
        [r'C:\Users\me\AppData\Local\Programs\Microsoft VS Code\bin\code.cmd', '/repo'],
      );
    });

    test('시스템 설치', () {
      expect(find('windows', {r'C:\Program Files\Microsoft VS Code\bin\code.cmd'}, env: env),
          [r'C:\Program Files\Microsoft VS Code\bin\code.cmd', '/repo']);
    });

    test('다른 위치면 PATH의 code.cmd', () {
      expect(find('windows', {r'D:\VSCode\bin\code.cmd'}, path: r'C:\Windows;D:\VSCode\bin', env: env),
          [r'D:\VSCode\bin\code.cmd', '/repo']);
    });

    test('없으면 null', () => expect(find('windows', {}, path: r'C:\Windows', env: env), isNull));
  });

  group('Linux', () {
    test('PATH의 code', () {
      expect(find('linux', {'/usr/local/bin/code'}, path: '/usr/local/bin'), ['/usr/local/bin/code', '/repo']);
    });

    test('snap', () => expect(find('linux', {'/snap/bin/code'}), ['/snap/bin/code', '/repo']));

    test('flatpak', () {
      expect(find('linux', {'/home/me/.local/share/flatpak/app/com.visualstudio.code'}, env: {'HOME': '/home/me'}),
          ['flatpak', 'run', 'com.visualstudio.code', '/repo']);
    });

    test('없으면 null', () => expect(find('linux', {}, path: '/usr/bin'), isNull));
  });
}
