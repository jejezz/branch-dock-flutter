#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  // 첫 실행 창(440x960, UI_UX.md §2)을 주 모니터 작업 영역 가운데에 둔다.
  // Dart 쪽 center()는 devicePixelRatio를 잘못 읽으면 화면 밖으로 밀려난다.
  const POINT zero = {0, 0};
  HMONITOR primary = MonitorFromPoint(zero, MONITOR_DEFAULTTOPRIMARY);
  MONITORINFO info = {sizeof(info)};
  GetMonitorInfo(primary, &info);
  const double scale = FlutterDesktopGetDpiForMonitor(primary) / 96.0;
  const double area_w = (info.rcWork.right - info.rcWork.left) / scale;
  const double area_h = (info.rcWork.bottom - info.rcWork.top) / scale;
  const double win_w = area_w < 440 ? area_w : 440;
  const double win_h = area_h < 960 ? area_h : 960;
  Win32Window::Point origin(
      static_cast<unsigned int>(info.rcWork.left / scale + (area_w - win_w) / 2),
      static_cast<unsigned int>(info.rcWork.top / scale + (area_h - win_h) / 2));
  Win32Window::Size size(static_cast<unsigned int>(win_w),
                         static_cast<unsigned int>(win_h));
  if (!window.Create(L"Branch Dock", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
