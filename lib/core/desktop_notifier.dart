import 'dart:io';

/// CI 완료 같은 알림을 OS 알림으로 띄운다 (PLAN.md 3.8.5 완료 알림).
///
/// 네이티브 플러그인 대신 OS에 이미 있는 명령을 쓴다 — 플러그인은 Linux
/// 빌드에 libnotify-dev를 요구해서 규약 릴리스 워크플로를 바꿔야 한다.
/// - macOS: `osascript` (display notification)
/// - Linux: `notify-send` (libnotify-bin, 대부분의 데스크톱에 있음)
/// - Windows: PowerShell 토스트
/// 실패해도 조용히 넘어간다. 알림은 부가 기능이다.
class DesktopNotifier {
  DesktopNotifier({required this.path});

  /// CommandRunner와 같은 PATH.
  final String path;

  Future<void> notify(String title, String body) async {
    try {
      if (Platform.isMacOS) {
        // 인자로 넘겨 따옴표 이스케이프 문제를 피한다.
        await Process.run('osascript', [
          '-e', 'on run argv',
          '-e', 'display notification (item 2 of argv) with title (item 1 of argv)',
          '-e', 'end run',
          title,
          body,
        ]);
      } else if (Platform.isLinux) {
        await Process.run('notify-send', ['--app-name=Branch Dock', title, body], environment: {'PATH': path});
      } else if (Platform.isWindows) {
        await Process.run(
          'powershell',
          ['-NoProfile', '-NonInteractive', '-Command', _windowsToast],
          environment: {'BD_TITLE': title, 'BD_BODY': body},
        );
      }
    } on Object {
      // 알림 명령이 없어도 앱은 계속 동작한다.
    }
  }

  static const _windowsToast = r'''
[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] > $null
$t = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent([Windows.UI.Notifications.ToastTemplateType]::ToastText02)
$x = $t.GetElementsByTagName('text')
$x.Item(0).AppendChild($t.CreateTextNode($env:BD_TITLE)) > $null
$x.Item(1).AppendChild($t.CreateTextNode($env:BD_BODY)) > $null
$id = '{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe'
[Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($id).Show([Windows.UI.Notifications.ToastNotification]::new($t))
''';
}
