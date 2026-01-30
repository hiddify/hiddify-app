#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>
#include "flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
    
    ScopedMutex mutex(L"HiddifyNext_Unique_Mutex_ID");
    
    if (!mutex.success()) {
        flutter::DartProject project(L"data");
        project.set_dart_entrypoint_arguments(GetCommandLineArguments());
        FlutterWindow window(project);
        
        if (window.SendAppLinkToInstance(L"Hiddify")) {
            return EXIT_SUCCESS;
        }

        HWND hwnd = ::FindWindowW(L"FLUTTER_RUNNER_WIN32_WINDOW", L"Hiddify");
        if (hwnd) {
            if (::IsIconic(hwnd)) ::ShowWindow(hwnd, SW_RESTORE);
            ::SetForegroundWindow(hwnd);
        }
        return EXIT_SUCCESS;
    }

    if (::IsDebuggerPresent()) {
        CreateAndAttachConsole();
    }

    HRESULT hr = ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED | COINIT_DISABLE_OLE1DDE);

    {
        flutter::DartProject project(L"data");
        project.set_dart_entrypoint_arguments(GetCommandLineArguments());

        FlutterWindow window(project);
        Win32Window::Point origin(10, 10);
        Win32Window::Size size(1280, 720);

        if (!window.Create(L"Hiddify", origin, size)) {
            if (SUCCEEDED(hr)) ::CoUninitialize();
            return EXIT_FAILURE;
        }

        window.SetQuitOnClose(true);

        ::MSG msg;
        while (::GetMessage(&msg, nullptr, 0, 0)) {
            ::TranslateMessage(&msg);
            ::DispatchMessage(&msg);
        }
    }

    if (SUCCEEDED(hr)) ::CoUninitialize();
    return EXIT_SUCCESS;
}
