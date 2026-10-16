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
