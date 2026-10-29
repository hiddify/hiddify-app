import UIKit
import Flutter
import HiddifyCore
import Sentry
@main
@objc class AppDelegate: FlutterAppDelegate {
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        setupFileManager()
        registerHandlers()
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    func setupFileManager() {
        try? FileManager.default.createDirectory(at: FilePath.workingDirectory, withIntermediateDirectories: true)
        FileManager.default.changeCurrentDirectoryPath(FilePath.sharedDirectory.path)
    }
    
    func registerHandlers() {
        // The registrar is missing when iOS launches the app without a Flutter engine (a launch in
        // the background, for one): skip the handlers instead of crashing the launch.
        func register(_ name: String, _ register: (FlutterPluginRegistrar) -> Void) {
            guard let registrar = self.registrar(forPlugin: name) else {
                NSLog("hiddify: no Flutter registrar for \(name), handler not registered")
                return
            }
            register(registrar)
        }
        register(MethodHandler.name) { MethodHandler.register(with: $0) }
        register(PlatformMethodHandler.name) { PlatformMethodHandler.register(with: $0) }
        register(FileMethodHandler.name) { FileMethodHandler.register(with: $0) }
        register(StatusEventHandler.name) { StatusEventHandler.register(with: $0) }
        register(AlertsEventHandler.name) { AlertsEventHandler.register(with: $0) }
//        LogsEventHandler.register(with: self.registrar(forPlugin: LogsEventHandler.name)!)
//        GroupsEventHandler.register(with: self.registrar(forPlugin: GroupsEventHandler.name)!)
//        ActiveGroupsEventHandler.register(with: self.registrar(forPlugin: ActiveGroupsEventHandler.name)!)
//        StatsEventHandler.register(with: self.registrar(forPlugin: StatsEventHandler.name)!)
    }
}

