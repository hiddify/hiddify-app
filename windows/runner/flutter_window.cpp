#include "flutter_window.h"
#include <optional>
#include "flutter/generated_plugin_registrant.h"
#include <dwmapi.h>
#include <versionhelpers.h>

#pragma comment(lib, "dwmapi.lib")

#ifndef DWMWA_USE_IMMERSIVE_DARK_MODE
#define DWMWA_USE_IMMERSIVE_DARK_MODE 20
#endif

#ifndef DWMWA_SYSTEM_BACKDROP_TYPE
#define DWMWA_SYSTEM_BACKDROP_TYPE 38
#endif

#ifndef DWMWA_MICA_EFFECT
#define DWMWA_MICA_EFFECT 1029
#endif

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
    if (!Win32Window::OnCreate()) return false;

    RECT frame = GetClientArea();

    flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
        frame.right - frame.left, frame.bottom - frame.top, project_);

    if (!flutter_controller_->engine() || !flutter_controller_->view()) return false;

    RegisterPlugins(flutter_controller_->engine());
    SetChildContent(flutter_controller_->view()->GetNativeWindow());

    flutter_controller_->engine()->SetNextFrameCallback([this]() {
        this->Show();
    });

    HWND hwnd = GetHandle();
    
    BOOL use_dark_mode = TRUE;
    ::DwmSetWindowAttribute(hwnd, DWMWA_USE_IMMERSIVE_DARK_MODE, &use_dark_mode, sizeof(use_dark_mode));

    if (IsWindows11OrGreater()) {
        int backdrop_type = 4;
        ::DwmSetWindowAttribute(hwnd, DWMWA_SYSTEM_BACKDROP_TYPE, &backdrop_type, sizeof(backdrop_type));
    } else if (IsWindows10OrGreater()) {
        int mica_value = 1;
        ::DwmSetWindowAttribute(hwnd, DWMWA_MICA_EFFECT, &mica_value, sizeof(mica_value));
    }

    MARGINS margins = {-1};
    ::DwmExtendFrameIntoClientArea(hwnd, &margins);

    flutter_controller_->ForceRedraw();
    return true;
}

void FlutterWindow::OnDestroy() {
    if (flutter_controller_) {
        flutter_controller_ = nullptr;
    }
    Win32Window::OnDestroy();
}

LRESULT FlutterWindow::MessageHandler(HWND hwnd, UINT const message, WPARAM const wparam, LPARAM const lparam) noexcept {
    if (flutter_controller_) {
        std::optional<LRESULT> result = flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam, lparam);
        if (result) return *result;
    }

    switch (message) {
        case WM_FONTCHANGE:
            if (flutter_controller_ && flutter_controller_->engine()) {
                flutter_controller_->engine()->ReloadSystemFonts();
            }
            break;
        case WM_DPICHANGED:
            if (flutter_controller_) {
                RECT* const prcNewWindow = reinterpret_cast<RECT*>(lparam);
                ::SetWindowPos(hwnd, nullptr, prcNewWindow->left, prcNewWindow->top, 
                    prcNewWindow->right - prcNewWindow->left, 
                    prcNewWindow->bottom - prcNewWindow->top, 
                    SWP_NOZORDER | SWP_NOACTIVATE);
            }
            break;
        case WM_NCCALCSIZE:
            if (wparam == TRUE) return 0;
            break;
    }

    return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
