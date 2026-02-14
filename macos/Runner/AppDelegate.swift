import Cocoa
import FlutterMacOS
import ServiceManagement
import UserNotifications

@main
class AppDelegate: FlutterAppDelegate {
    override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // https://github.com/leanflutter/window_manager/issues/214
        return false
    }

    override func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Request notification authorization
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge]) {
            granted, error in
            if let error = error {
                print("Error requesting notification authorization: \(error)")
            }
        }

        if #available(macOS 13.0, *) {
            let service = SMAppService.daemon(plistName: "app.hiddify.com.daemon.plist")

            if service.status != .enabled {
                do {
                    try service.register()
                } catch {
                    print(error)
                }
            }
        }
    }

    override func applicationWillTerminate(_ notification: Notification) {
        if #available(macOS 13.0, *) {
            let service = SMAppService.daemon(plistName: "app.hiddify.com.daemon.plist")

            do {
                try service.unregister()
            } catch {
                print(error)
            }
        }
    }

    // // window manager restore from dock: https://leanflutter.dev/blog/click-dock-icon-to-restore-after-closing-the-window
    // override func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
    //     if !flag {
    //         for window in NSApp.windows {
    //             if !window.isVisible {
    //                 window.setIsVisible(true)
    //             }
    //             window.makeKeyAndOrderFront(self)
    //             NSApp.activate(ignoringOtherApps: true)
    //         }
    //     }
    //     return true
    // }
}
