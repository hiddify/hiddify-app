#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
build_dir="$(mktemp -d "${TMPDIR:-/tmp}/wir-foreground-setup-mode-test.XXXXXX")"
trap 'rm -rf "$build_dir"' EXIT
mkdir -p "$build_dir/module-cache"

handler_source="$repo_root/ios/Runner/Handlers/MethodHandler.swift"
setup_body="$(
  awk '
    /^[[:space:]]*case "setup":/ { found=1; next }
    found && /^[[:space:]]*case "start":/ { exit }
    found { print }
  ' "$handler_source"
)"

if [[ -z "$setup_body" ]]; then
  printf '%s\n' 'ERROR: setup case body was not found'
  exit 1
fi

{
  cat <<'SWIFT'
import Dispatch
import Foundation

struct FlutterMethodCall {
    let method: String
    let arguments: Any?

    init(method: String, arguments: Any? = nil) {
        self.method = method
        self.arguments = arguments
    }
}

typealias FlutterResult = (Any?) -> Void

struct FlutterError {
    let code: String
    let message: String?
    let details: Any?

    init(code: String, message: String?, details: Any?) {
        self.code = code
        self.message = message
        self.details = details
    }
}

final class VPNConfig {
    static let shared = VPNConfig()
    var baseDir = ""
    var workingDir = ""
    var tempDir = ""
}

final class VPNManager {
    static let shared = VPNManager()
    static var setupCallCount = 0

    func setup() async throws {
        VPNManager.setupCallCount += 1
    }
}

final class MobileSetupOptions {
    var basePath = ""
    var workingDir = ""
    var tempDir = ""
    var listen = ""
    var secret = ""
    var debug = false
    var mode = 0
    var fixAndroidStack = false
}

enum MobileSetupState {
    static var callCount = 0
    static var lastOptions: MobileSetupOptions?

    static func reset() {
        callCount = 0
        lastOptions = nil
    }
}

func MobileSetup(
    _ options: MobileSetupOptions,
    _ context: Any?,
    _ error: UnsafeMutablePointer<NSError?>
) {
    MobileSetupState.callCount += 1
    MobileSetupState.lastOptions = options
}

final class MethodHandlerHarness {
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "setup":
SWIFT
  printf '%s\n' "$setup_body"
  cat <<'SWIFT'
        default:
            result(nil)
        }
    }
}

struct ForegroundSetupModeTest {
    static func invoke(
        _ handler: MethodHandlerHarness,
        arguments: Any?
    ) -> (result: Any?, completed: Bool) {
        let semaphore = DispatchSemaphore(value: 0)
        var result: Any?
        handler.handle(
            FlutterMethodCall(method: "setup", arguments: arguments)
        ) { value in
            result = value
            semaphore.signal()
        }
        let completed = semaphore.wait(timeout: .now() + .seconds(2)) == .success
        return (result, completed)
    }

    static func expect(
        _ condition: Bool,
        _ message: String,
        failures: inout Int
    ) {
        if !condition {
            print("FAIL: \(message)")
            failures += 1
        }
    }

    static func main() {
        let handler = MethodHandlerHarness()
        var failures = 0

        for (requestedMode, grpcPort) in [(3, 30103), (1, 30101)] {
            MobileSetupState.reset()
            VPNManager.setupCallCount = 0

            let arguments: [String: Any?] = [
                "baseDir": "/synthetic/base",
                "workingDir": "/synthetic/working",
                "tempDir": "/synthetic/temp",
                "mode": requestedMode,
                "grpcPort": grpcPort
            ]
            let invocation = invoke(handler, arguments: arguments)
            let capturedMode = MobileSetupState.lastOptions?.mode ?? -1
            let capturedListen = MobileSetupState.lastOptions?.listen ?? "<nil>"

            print(
                "mode request=\(requestedMode) capturedMode=\(capturedMode) " +
                "capturedListen=\(capturedListen) mobileSetupCalls=\(MobileSetupState.callCount) " +
                "vpnManagerSetupCalls=\(VPNManager.setupCallCount)"
            )
            expect(invocation.completed, "mode=\(requestedMode) completion", failures: &failures)
            expect((invocation.result as? Bool) == true, "mode=\(requestedMode) success result", failures: &failures)
            expect(capturedMode == requestedMode, "mode=\(requestedMode) forwarded mode", failures: &failures)
            expect(capturedListen == "127.0.0.1:\(grpcPort)", "mode=\(requestedMode) forwarded listen", failures: &failures)
            expect(MobileSetupState.callCount == 1, "mode=\(requestedMode) MobileSetup call count", failures: &failures)
            expect(VPNManager.setupCallCount == 1, "mode=\(requestedMode) VPNManager setup call count", failures: &failures)
        }

        MobileSetupState.reset()
        VPNManager.setupCallCount = 0
        let invalidInvocation = invoke(
            handler,
            arguments: ["baseDir": "/synthetic/base"] as [String: Any?]
        )
        print(
            "invalidArgs mobileSetupCalls=\(MobileSetupState.callCount) " +
            "vpnManagerSetupCalls=\(VPNManager.setupCallCount)"
        )
        expect(invalidInvocation.completed, "invalid args completion", failures: &failures)
        expect(invalidInvocation.result is FlutterError, "invalid args error result", failures: &failures)
        expect(MobileSetupState.callCount == 0, "invalid args MobileSetup call count", failures: &failures)
        expect(VPNManager.setupCallCount == 0, "invalid args VPNManager setup call count", failures: &failures)

        if failures > 0 {
            print("FAILURES=\(failures)")
            exit(1)
        }
        print("PASS")
    }
}

ForegroundSetupModeTest.main()
SWIFT
} > "$build_dir/ForegroundSetupModeTest.swift"

if ! swiftc \
  -swift-version 5 \
  -module-cache-path "$build_dir/module-cache" \
  "$build_dir/ForegroundSetupModeTest.swift" \
  -o "$build_dir/ForegroundSetupModeTest" \
  2>"$build_dir/compiler.log"; then
  printf '%s\n' 'ERROR: Swift harness compilation failed'
  cat "$build_dir/compiler.log" >&2
  exit 1
fi

"$build_dir/ForegroundSetupModeTest"
