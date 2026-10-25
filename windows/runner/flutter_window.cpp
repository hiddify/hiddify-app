#include "flutter_window.h"

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <cmath>
#include <optional>
#include <string>
#include <shobjidl.h>

#include "flutter/generated_plugin_registrant.h"

namespace {

// 16x16 status overlay for the Windows taskbar button (white ring + fill).
HICON CreateStatusOverlayIcon(UINT32 fill_argb) {
  const int size = 16;
  BITMAPINFO bmi = {};
  bmi.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
  bmi.bmiHeader.biWidth = size;
  bmi.bmiHeader.biHeight = -size;  // top-down
  bmi.bmiHeader.biPlanes = 1;
  bmi.bmiHeader.biBitCount = 32;
  bmi.bmiHeader.biCompression = BI_RGB;

  void* bits = nullptr;
  HDC screen = GetDC(nullptr);
  HBITMAP color = CreateDIBSection(screen, &bmi, DIB_RGB_COLORS, &bits, nullptr, 0);
  ReleaseDC(nullptr, screen);
  if (!color || !bits) {
    return nullptr;
  }

  auto* pixels = static_cast<UINT32*>(bits);
  const float cx = (size - 1) * 0.5f;
  const float cy = (size - 1) * 0.5f;
  const float outer_r = size * 0.48f;
  const float inner_r = size * 0.34f;
  for (int y = 0; y < size; ++y) {
    for (int x = 0; x < size; ++x) {
      const float dx = x - cx;
      const float dy = y - cy;
      const float d = sqrtf(dx * dx + dy * dy);
      UINT32 px = 0x00000000;
      if (d <= outer_r) {
        // White ring + fill — readable on light and dark taskbars.
        if (d >= inner_r) {
          px = 0xFFFFFFFFu;
        } else {
          px = fill_argb;
        }
      }
      pixels[y * size + x] = px;
    }
  }

  ICONINFO info = {};
  info.fIcon = TRUE;
  info.hbmColor = color;
  info.hbmMask = CreateBitmap(size, size, 1, 1, nullptr);
  HICON icon = CreateIconIndirect(&info);
  DeleteObject(info.hbmMask);
  DeleteObject(color);
  return icon;
}

}  // namespace

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {
  if (overlay_icon_ok_) {
    DestroyIcon(overlay_icon_ok_);
    overlay_icon_ok_ = nullptr;
  }
  if (overlay_icon_error_) {
    DestroyIcon(overlay_icon_error_);
    overlay_icon_error_ = nullptr;
  }
}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());
  RegisterDesktopStatusChannel();

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    // this->Show(); window_manager hidden at launch
    "";
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::RegisterDesktopStatusChannel() {
  auto channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      flutter_controller_->engine()->messenger(), "com.hiddify.app/desktop_status",
      &flutter::StandardMethodCodec::GetInstance());

  channel->SetMethodCallHandler(
      [this](const flutter::MethodCall<flutter::EncodableValue>& call,
             std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        if (call.method_name() == "setStatus" ||
            call.method_name() == "setConnected") {
          std::string status = "none";
          if (const auto* args =
                  std::get_if<flutter::EncodableMap>(call.arguments())) {
            if (call.method_name() == "setStatus") {
              auto it = args->find(flutter::EncodableValue("status"));
              if (it != args->end()) {
                if (const auto* s = std::get_if<std::string>(&it->second)) {
                  status = *s;
                }
              }
            } else {
              auto it = args->find(flutter::EncodableValue("connected"));
              if (it != args->end()) {
                if (const auto* flag = std::get_if<bool>(&it->second)) {
                  status = *flag ? "ok" : "none";
                }
              }
            }
          }
          SetTaskbarStatusOverlay(status);
          result->Success();
          return;
        }
        result->NotImplemented();
      });

  // Channel keeps itself alive via the engine messenger; release local unique_ptr
  // ownership after installing the handler by leaking intentionally into engine.
  channel.release();
}

void FlutterWindow::SetTaskbarStatusOverlay(const std::string& status) {
  HWND hwnd = GetHandle();
  if (!hwnd) {
    return;
  }

  std::string normalized = status;
  if (normalized != "ok" && normalized != "error") {
    normalized = "none";
  }
  if (normalized == overlay_status_) {
    return;
  }
  overlay_status_ = normalized;

  ITaskbarList3* taskbar = nullptr;
  if (FAILED(CoCreateInstance(CLSID_TaskbarList, nullptr, CLSCTX_INPROC_SERVER,
                              IID_PPV_ARGS(&taskbar))) ||
      !taskbar) {
    return;
  }
  taskbar->HrInit();

  if (normalized == "ok") {
    if (!overlay_icon_ok_) {
      overlay_icon_ok_ = CreateStatusOverlayIcon(0xFF34C759u);  // green
    }
    if (overlay_icon_ok_) {
      taskbar->SetOverlayIcon(hwnd, overlay_icon_ok_, L"Connected");
    }
  } else if (normalized == "error") {
    if (!overlay_icon_error_) {
      overlay_icon_error_ = CreateStatusOverlayIcon(0xFFE53935u);  // red
    }
    if (overlay_icon_error_) {
      taskbar->SetOverlayIcon(hwnd, overlay_icon_error_, L"No ping");
    }
  } else {
    taskbar->SetOverlayIcon(hwnd, nullptr, L"");
  }
  taskbar->Release();
}

void FlutterWindow::OnDestroy() {
  SetTaskbarStatusOverlay("none");
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
