#ifndef RUNNER_FLUTTER_WINDOW_H_
#define RUNNER_FLUTTER_WINDOW_H_

#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <string>

#include "win32_window.h"

// A window that does nothing but host a Flutter view.
class FlutterWindow : public Win32Window {
 public:
  // Creates a new FlutterWindow hosting a Flutter view running |project|.
  explicit FlutterWindow(const flutter::DartProject& project);
  virtual ~FlutterWindow();

 protected:
  // Win32Window:
  bool OnCreate() override;
  void OnDestroy() override;
  LRESULT MessageHandler(HWND window, UINT const message, WPARAM const wparam,
                         LPARAM const lparam) noexcept override;

 private:
  void RegisterDesktopStatusChannel();
  // status: "none" | "ok" | "error"
  void SetTaskbarStatusOverlay(const std::string& status);
  // Windows ends the session, or a setup closes the app through the Restart Manager.
  void EndSession(HWND hwnd);

  // Tells Dart the session ends ("endSession"), so the app exits as from the tray's Exit.
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> session_channel_;
  bool ending_session_ = false;

  // The project to run.
  flutter::DartProject project_;

  // The Flutter instance hosted by this window.
  std::unique_ptr<flutter::FlutterViewController> flutter_controller_;

  HICON overlay_icon_ok_ = nullptr;
  HICON overlay_icon_error_ = nullptr;
  std::string overlay_status_ = "none";
};

#endif  // RUNNER_FLUTTER_WINDOW_H_

