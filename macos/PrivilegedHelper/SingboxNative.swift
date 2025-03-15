//
//  SingboxNative.swift
//  Runner
//
//  Created by Aleksandr Strizhnev on 20.02.2025.
//

import Foundation

typealias NativePort = UInt64

class SingboxDylib {
    private var lib: UnsafeMutableRawPointer?

    init() throws {
        guard let dylib = dlopen("libcore.dylib", RTLD_NOW) else {
            throw DylibError.loadError(String(cString: dlerror()))
        }
        lib = dylib
    }

    deinit {
        dlclose(lib)
    }

    private func getFunction<T>(_ name: String) throws -> T {
        guard let lib else {
            throw DylibError.loadError("Dylib not loaded")
        }

        guard let symbol = dlsym(lib, name) else {
            throw DylibError.symbolNotFound(name)
        }

        return unsafeBitCast(symbol, to: T.self)
    }

    func setPortListener(listener: @escaping (Int64, UnsafeRawPointer?) -> Void) {
        setDartPortListener(listener)
    }

    func setupOnce() throws -> String {
        do {
            let setupOnce: @convention(c) (UnsafeRawPointer) -> Void = try getFunction("setupOnce")

            setupOnce(
                UnsafeMutableRawPointer(
                    mutating: createDartApi()
                )
            )

            return "initialized"
        } catch {
            return "\(error)"
        }
    }

    func setup(
        baseDir: String,
        workingDir: String,
        tempDir: String,
        port: NativePort,
        debug: Bool
    ) throws -> String {
        let setup:
            @convention(c) (
                UnsafePointer<CChar>,
                UnsafePointer<CChar>,
                UnsafePointer<CChar>,
                NativePort,
                Int32
            ) -> UnsafePointer<CChar> = try getFunction("setup")

        let result = setup(
            strdup(baseDir),
            strdup(workingDir),
            strdup(tempDir),
            port,
            debug ? 1 : 0
        )

        return String(cString: result)
    }

    func changeHiddifyOptions(_ json: String) throws -> String {
        let change: @convention(c) (UnsafePointer<CChar>) -> UnsafePointer<CChar> = try getFunction(
            "changeHiddifyOptions")
        let result = change(strdup(json))

        return String(cString: result)
    }

    func parse(path: String, tempPath: String, debug: Bool) throws -> String {
        let parse:
            @convention(c) (
                UnsafePointer<CChar>,
                UnsafePointer<CChar>,
                Int32
            ) -> UnsafePointer<CChar> = try getFunction("parse")

        return String(
            cString: parse(strdup(path), strdup(tempPath), debug ? 1 : 0)
        )
    }

    func generateConfig(path: String) throws -> String {
        let generateConfig:
            @convention(c) (
                UnsafePointer<CChar>
            ) -> UnsafePointer<CChar> = try getFunction("generateConfig")

        return String(
            cString: generateConfig(strdup(path))
        )
    }

    func start(path: String, disableMemoryLimit: Bool) throws -> String {
        let start:
            @convention(c) (
                UnsafePointer<CChar>,
                Int32
            ) -> UnsafePointer<CChar> = try getFunction("start")

        return String(
            cString: start(strdup(path), disableMemoryLimit ? 1 : 0)
        )
    }

    func restart(path: String, disableMemoryLimit: Bool) throws -> String {
        let restart:
            @convention(c) (
                UnsafePointer<CChar>,
                Int32
            ) -> UnsafePointer<CChar> = try getFunction("restart")

        return String(
            cString: restart(strdup(path), disableMemoryLimit ? 1 : 0)
        )
    }

    func stop() throws -> String {
        let stop: @convention(c) () -> UnsafePointer<CChar> = try getFunction("stop")
        let result = stop()

        return String(cString: result)
    }

    func stopCommandClient(id: Int32) throws -> String {
        let stopClient: @convention(c) (Int32) -> UnsafePointer<CChar> = try getFunction(
            "stopCommandClient")
        let result = stopClient(id)

        return String(cString: result)
    }

    func startCommandClient(id: Int32, port: NativePort) throws -> String {
        let startClient: @convention(c) (Int32, NativePort) -> UnsafePointer<CChar> =
            try getFunction("startCommandClient")
        let result = startClient(id, port)

        return String(cString: result)
    }

    func selectOutbound(
        groupTag: String,
        outboundTag: String
    ) throws -> String {
        let selectOutbound:
            @convention(c) (
                UnsafePointer<CChar>,
                UnsafePointer<CChar>
            ) -> UnsafePointer<CChar> = try getFunction("selectOutbound")

        return String(
            cString: selectOutbound(strdup(groupTag), strdup(outboundTag))
        )
    }

    func generateWarpConfig(
        licenseKey: String,
        previousAccountId: String,
        previousAccessToken: String
    ) throws -> String {
        let generateWarpConfig:
            @convention(c) (
                UnsafePointer<CChar>,
                UnsafePointer<CChar>,
                UnsafePointer<CChar>
            ) -> UnsafePointer<CChar> = try getFunction("generateWarpConfig")

        return String(
            cString: generateWarpConfig(
                strdup(licenseKey),
                strdup(previousAccountId),
                strdup(previousAccessToken)
            )
        )
    }

    func urlTest(groupTag: String) throws -> String {
        let test: @convention(c) (UnsafePointer<CChar>) -> UnsafePointer<CChar> = try getFunction(
            "urlTest")
        let result = test(strdup(groupTag))

        return String(cString: result)
    }
}

enum DylibError: Error {
    case loadError(String)
    case symbolNotFound(String)
}

extension DylibError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .loadError(let message):
            return NSLocalizedString(
                "Failed to load dynamic library: \(message)", comment: "Dylib loading error"
            )
        case .symbolNotFound(let symbol):
            return NSLocalizedString(
                "Symbol '\(symbol)' not found in the dynamic library.",
                comment: "Dylib symbol error"
            )
        }
    }
}
