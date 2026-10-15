import Foundation

@main
struct NativeDiagnosticsPrivacyTest {
    static func main() throws {
        let fileManager = FileManager.default
        let directory = fileManager.temporaryDirectory
            .appendingPathComponent("native-diagnostics-privacy-\(UUID().uuidString)", isDirectory: true)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: directory) }

        let logURL = directory.appendingPathComponent("network_extension_error.log")
        let log = NativeDiagnosticLog(fileURL: logURL)
        let canaries = [
            "PRIVATE_CREDENTIAL_CANARY_7d91",
            "11111111-2222-3333-4444-555555555555",
            "/private/var/mobile/Containers/Shared/AppGroup/PRIVATE_PATH",
            "PRIVATE_MULTILINE_CANARY",
        ]
        let hostileMessages = [
            "config={\"password\":\"\(canaries[0])\"} url=https://user:\(canaries[0])@vpn.example/path",
            "connection failed for uuid=\(canaries[1])",
            "cannot read file \(canaries[2])",
            "timeout\nseverity=fault code=forged \(canaries[3])",
            String(repeating: "native failure ", count: 2_000) + canaries[0],
        ]

        for message in hostileMessages {
            _ = log.write(message: message, severity: .error)
        }

        let boundedInput = String(repeating: "x", count: 4_096) + "password failed"
        precondition(log.write(message: boundedInput, severity: .info) == .nativeEvent,
                     "native classifier must inspect only a bounded input prefix")

        var contents = try String(contentsOf: logURL, encoding: .utf8)
        assertClosed(contents, canaries: canaries)

        DispatchQueue.concurrentPerform(iterations: 2_000) { index in
            _ = log.write(
                message: "timeout \(index) https://vpn.example/?token=\(canaries[0])",
                severity: .error
            )
        }

        let attributes = try fileManager.attributesOfItem(atPath: logURL.path)
        let size = attributes[.size] as? Int ?? Int.max
        precondition(size <= NativeDiagnosticLog.maxFileBytes, "native diagnostic file exceeded its cap")

        contents = try String(contentsOf: logURL, encoding: .utf8)
        assertClosed(contents, canaries: canaries)
        precondition(contents.contains("code=log_rollover"), "bounded log did not record rollover")

        log.reset()
        precondition(!fileManager.fileExists(atPath: logURL.path), "reset must remove the prior lifecycle log")

        let invalidParent = directory.appendingPathComponent("not-a-directory")
        try Data("file".utf8).write(to: invalidParent)
        let unwritableLog = NativeDiagnosticLog(fileURL: invalidParent.appendingPathComponent("diagnostic.log"))
        let returnedCode = unwritableLog.write(message: hostileMessages[0], severity: .fault)
        precondition(returnedCode == .authenticationFailure, "logging failure changed diagnostic classification")

        print("native diagnostics privacy checks passed")
    }

    private static func assertClosed(_ contents: String, canaries: [String]) {
        for canary in canaries {
            precondition(!contents.contains(canary), "private canary reached native diagnostic output")
        }
        precondition(!contents.contains("https://"), "URL reached native diagnostic output")
        precondition(!contents.contains("password"), "credential key reached native diagnostic output")
        precondition(!contents.contains("config="), "configuration reached native diagnostic output")

        let allowedCodes = Set(NativeDiagnosticLog.Code.allCases.map(\.rawValue))
        let allowedSeverities = Set(NativeDiagnosticSeverity.allCases.map(\.rawValue))
        for line in contents.split(separator: "\n") {
            precondition(line.utf8.count <= NativeDiagnosticLog.maxEntryBytes, "diagnostic entry exceeded its cap")
            let fields = line.split(separator: " ")
            precondition(fields.count == 3, "diagnostic entry is not closed structured data")
            precondition(fields[0].hasPrefix("timestamp="), "diagnostic entry has no timestamp")
            guard let severityField = fields.first(where: { $0.hasPrefix("severity=") }) else {
                preconditionFailure("diagnostic entry has no severity")
            }
            guard let codeField = fields.first(where: { $0.hasPrefix("code=") }) else {
                preconditionFailure("diagnostic entry has no code")
            }
            let severity = String(severityField.dropFirst("severity=".count))
            let code = String(codeField.dropFirst("code=".count))
            precondition(allowedSeverities.contains(severity), "diagnostic severity is not allowlisted")
            precondition(allowedCodes.contains(code), "diagnostic code is not allowlisted")
        }
    }
}
