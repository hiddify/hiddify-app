#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"


int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  HANDLE hMutexInstance = CreateMutex(NULL, TRUE, L"HiddifyMutex");
  if (GetLastError() == ERROR_ALREADY_EXISTS) {
    flutter::DartProject project(L"data");
    std::vector<std::string> command_line_arguments = GetCommandLineArguments();
    project.set_dart_entrypoint_arguments(std::move(command_line_arguments));
    FlutterWindow window(project);
    if (window.SendAppLinkToInstance(L"Hiddify")) {
      if (hMutexInstance) {
        ReleaseMutex(hMutexInstance);
        CloseHandle(hMutexInstance);
      }
      return EXIT_SUCCESS;
    }

    // Fallback: try to bring any existing window with the title to front.
    HWND hwnd = ::FindWindowW(nullptr, L"Hiddify");
    if (hwnd) {
      WINDOWPLACEMENT place = {sizeof(WINDOWPLACEMENT)};
      GetWindowPlacement(hwnd, &place);
      ShowWindow(hwnd, SW_NORMAL);
      SetForegroundWindow(hwnd);
    }
    if (hMutexInstance) {
      ReleaseMutex(hMutexInstance);
      CloseHandle(hMutexInstance);
    }
    return EXIT_SUCCESS;
  }

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
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"Hiddify", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  if (hMutexInstance) {
    ReleaseMutex(hMutexInstance);
    CloseHandle(hMutexInstance);
  }
  return EXIT_SUCCESS;
}
