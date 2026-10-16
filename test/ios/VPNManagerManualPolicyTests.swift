import Darwin
import Foundation
import NetworkExtension

@main
struct VPNManagerManualPolicyTests {
    private static var failureCount = 0

    static func main() async {
        await existingProfileIsMadeManualBeforeExplicitStart()
        await newlyCreatedProfileIsMadeManualBeforeExplicitStart()
        await disconnectKeepsManualPolicyAndStopsTunnel()
        await setupFailurePreventsStart(operation: "load-all")
        await setupFailurePreventsStart(operation: "save")
        await setupFailurePreventsStart(operation: "load")
        await policyFailurePreventsStart(operation: "save")
        await policyFailurePreventsStart(operation: "load")
        await startFailureIsReported()
        await retryAfterPolicySaveFailureCanStart()
        await setupRecoversSystemStatus()
        await statusRefreshDoesNotCreateAProfile()
        await statusRefreshReportsLoadFailure()

        if failureCount == 0 {
            print("PASS: VPNManager manual system control behavior")
            exit(EXIT_SUCCESS)
        }
        print("FAIL: \(failureCount) assertion(s)")
        exit(EXIT_FAILURE)
    }

    private static func existingProfileIsMadeManualBeforeExplicitStart() async {
        let persisted = seededOnDemandManager()
        FakeNetworkExtensionState.reset(loadedManagers: [persisted])

        do {
            let subject = VPNManager()
            try await subject.setup()
            try await subject.connect(with: "/safe/config.json", grpcServiceModePort: 17079)

            expectManualPolicyWasSavedBeforeStart("existing profile")
            expect(FakeNetworkExtensionState.startCount == 1, "existing profile: explicit manual start still occurs")
            expect(
                FakeNetworkExtensionState.lastStartOptions?["Config"] as? String == "/safe/config.json",
                "existing profile: explicit start keeps the selected config"
            )
        } catch {
            fail("existing profile: unexpected error \(error)")
        }
    }

    private static func newlyCreatedProfileIsMadeManualBeforeExplicitStart() async {
        FakeNetworkExtensionState.reset()

        do {
            let subject = VPNManager()
            try await subject.setup()
            try await subject.connect(with: "/safe/new-config.json", grpcServiceModePort: 17079)

            expectManualPolicyWasSavedBeforeStart("new profile")
            expect(FakeNetworkExtensionState.startCount == 1, "new profile: explicit manual start still occurs")
        } catch {
            fail("new profile: unexpected error \(error)")
        }
    }

    private static func disconnectKeepsManualPolicyAndStopsTunnel() async {
        let persisted = seededOnDemandManager()
        FakeNetworkExtensionState.reset(loadedManagers: [persisted])

        do {
            let subject = VPNManager()
            try await subject.setup()
            try await subject.connect(with: "/safe/config.json", grpcServiceModePort: 17079)
            subject.disconnect()

            expect(FakeNetworkExtensionState.stopCount == 1, "disconnect: tunnel is explicitly stopped")
            expect(persisted.isOnDemandEnabled == false, "disconnect: On Demand remains disabled")
            expect((persisted.onDemandRules ?? []).isEmpty, "disconnect: On Demand rules remain empty")
        } catch {
            fail("disconnect: unexpected error \(error)")
        }
    }

    private static func seededOnDemandManager() -> NETunnelProviderManager {
        let manager = NETunnelProviderManager()
        manager.isEnabled = true
        manager.isOnDemandEnabled = true
        manager.onDemandRules = [NEOnDemandRuleConnect()]
        return manager
    }

    private static func setupRecoversSystemStatus() async {
        for status: NEVPNStatus in [.disconnected, .connecting, .connected, .reasserting, .disconnecting] {
            let persisted = seededOnDemandManager()
            persisted.connection.status = status
            FakeNetworkExtensionState.reset(loadedManagers: [persisted])
            let subject = VPNManager()
            do {
                try await subject.setup()
                expect(subject.state == status, "setup: existing system status is recovered")
                persisted.connection.status = .disconnected
                try await subject.setup()
                expect(subject.state == .disconnected, "resume: external system stop replaces old status")
                expect(FakeNetworkExtensionState.startCount == 0, "status: reading status never starts tunnel")
                expect(FakeNetworkExtensionState.saveSnapshots.isEmpty, "status: existing profile is not rewritten")
            } catch {
                fail("status: unexpected setup failure")
            }
        }
    }

    private static func statusRefreshDoesNotCreateAProfile() async {
        let persisted = seededOnDemandManager()
        persisted.connection.status = .connected
        FakeNetworkExtensionState.reset(loadedManagers: [persisted])
        let subject = VPNManager()
        do {
            let connected = try await subject.refreshStatus()
            expect(connected == .connected, "refresh: connected system tunnel is recovered")
            FakeNetworkExtensionState.loadedManagers = []
            let missing = try await subject.refreshStatus()
            expect(missing == .invalid, "refresh: deleted system profile clears stale status")
            expect(FakeNetworkExtensionState.saveSnapshots.isEmpty, "refresh: no profile is created or rewritten")
            expect(FakeNetworkExtensionState.startCount == 0, "refresh: tunnel is never started")
        } catch {
            fail("refresh: unexpected failure")
        }
    }

    private static func statusRefreshReportsLoadFailure() async {
        let persisted = seededOnDemandManager()
        persisted.connection.status = .connected
        FakeNetworkExtensionState.reset(loadedManagers: [persisted])
        let subject = VPNManager()
        do {
            _ = try await subject.refreshStatus()
            let failure = NSError(domain: "test.vpn.status", code: 5)
            FakeNetworkExtensionState.loadAllError = failure
            do {
                _ = try await subject.refreshStatus()
                fail("refresh: load failure must reach caller")
            } catch {
                expect((error as NSError) === failure, "refresh: original failure reaches caller")
                expect(subject.state == .connected, "refresh: load failure does not invent disconnected state")
            }
        } catch {
            fail("refresh: unexpected initial failure")
        }
    }

    private static func setupFailurePreventsStart(operation: String) async {
        FakeNetworkExtensionState.reset()
        let error = NSError(domain: "test.vpn.preferences", code: 1)
        switch operation {
        case "load-all": FakeNetworkExtensionState.loadAllError = error
        case "save": FakeNetworkExtensionState.saveError = error
        default: FakeNetworkExtensionState.loadError = error
        }
        let subject = VPNManager()
        var reportedError: NSError?
        do {
            try await subject.setup()
            try await subject.connect(with: "/safe/config.json", grpcServiceModePort: 17079)
        } catch {
            reportedError = error as NSError
        }
        expect(reportedError === error, "setup \(operation): original failure reaches caller")
        expect(FakeNetworkExtensionState.startCount == 0, "setup \(operation): tunnel is not started")
    }

    private static func policyFailurePreventsStart(operation: String) async {
        FakeNetworkExtensionState.reset(loadedManagers: [seededOnDemandManager()])
        let subject = VPNManager()
        do {
            try await subject.setup()
        } catch {
            fail("policy \(operation): unexpected setup failure")
            return
        }
        let error = NSError(domain: "test.vpn.preferences", code: 2)
        if operation == "save" {
            FakeNetworkExtensionState.saveError = error
        } else {
            FakeNetworkExtensionState.loadError = error
        }
        var reportedError: NSError?
        do {
            try await subject.connect(with: "/safe/config.json", grpcServiceModePort: 17079)
        } catch {
            reportedError = error as NSError
        }
        expect(reportedError === error, "policy \(operation): original failure reaches caller")
        expect(FakeNetworkExtensionState.startCount == 0, "policy \(operation): tunnel is not started")
    }

    private static func startFailureIsReported() async {
        FakeNetworkExtensionState.reset(loadedManagers: [seededOnDemandManager()])
        let subject = VPNManager()
        let failure = NSError(domain: "test.vpn.start", code: 3)
        do {
            try await subject.setup()
            FakeNetworkExtensionState.startError = failure
            do {
                try await subject.connect(with: "/safe/config.json", grpcServiceModePort: 17079)
                fail("start: rejected command must not return success")
            } catch {
                expect((error as NSError) === failure, "start: original failure reaches caller")
            }
            expect(FakeNetworkExtensionState.startCount == 1, "start: only one start is attempted")
        } catch {
            fail("start: unexpected setup failure")
        }
    }

    private static func retryAfterPolicySaveFailureCanStart() async {
        FakeNetworkExtensionState.reset(loadedManagers: [seededOnDemandManager()])
        let subject = VPNManager()
        do {
            try await subject.setup()
            FakeNetworkExtensionState.saveError = NSError(domain: "test.vpn.preferences", code: 4)
            do {
                try await subject.connect(with: "/safe/config.json", grpcServiceModePort: 17079)
                fail("retry: failed first attempt must report failure")
            } catch {}
            FakeNetworkExtensionState.saveError = nil
            try await subject.connect(with: "/safe/config.json", grpcServiceModePort: 17079)
            expect(FakeNetworkExtensionState.startCount == 1, "retry: only successful attempt starts tunnel")
            expectManualPolicyWasSavedBeforeStart("retry")
        } catch {
            fail("retry: unexpected error")
        }
    }

    private static func expectManualPolicyWasSavedBeforeStart(_ context: String) {
        guard let startIndex = FakeNetworkExtensionState.events.firstIndex(of: "start") else {
            fail("\(context): missing explicit start")
            return
        }
        guard let saveIndex = FakeNetworkExtensionState.events[..<startIndex].lastIndex(of: "save") else {
            fail("\(context): policy was not saved before start")
            return
        }

        let snapshotIndex = FakeNetworkExtensionState.events[..<saveIndex].filter { $0 == "save" }.count
        guard FakeNetworkExtensionState.saveSnapshots.indices.contains(snapshotIndex) else {
            fail("\(context): missing saved policy snapshot")
            return
        }
        let snapshot = FakeNetworkExtensionState.saveSnapshots[snapshotIndex]
        expect(snapshot.isEnabled, "\(context): VPN manager remains enabled")
        expect(snapshot.isOnDemandEnabled == false, "\(context): saved policy disables On Demand")
        expect(snapshot.onDemandRuleCount == 0, "\(context): saved policy clears On Demand rules")
    }

    private static func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
        if !condition() {
            fail(message)
        }
    }

    private static func fail(_ message: String) {
        failureCount += 1
        print("ASSERTION FAILED: \(message)")
    }
}
