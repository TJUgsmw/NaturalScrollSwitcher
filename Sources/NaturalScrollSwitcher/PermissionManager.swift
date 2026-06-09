import AppKit
import ApplicationServices
import CoreGraphics
import Foundation

struct PermissionState: Equatable {
    let listenEventAccess: Bool
    let accessibilityTrusted: Bool

    var canUseEventTap: Bool {
        listenEventAccess
    }

    var allPermissionsGranted: Bool {
        listenEventAccess && accessibilityTrusted
    }
}

enum PermissionManager {
    static func currentState() -> PermissionState {
        PermissionState(
            listenEventAccess: CGPreflightListenEventAccess(),
            accessibilityTrusted: AXIsProcessTrusted()
        )
    }

    @discardableResult
    static func requestPermissions() -> PermissionState {
        _ = CGRequestListenEventAccess()

        let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options = [promptKey: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)

        return currentState()
    }

    static func openInputMonitoringSettings() {
        openPrivacyPane(anchor: "Privacy_ListenEvent")
    }

    static func openAccessibilitySettings() {
        openPrivacyPane(anchor: "Privacy_Accessibility")
    }

    private static func openPrivacyPane(anchor: String) {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?\(anchor)") else {
            return
        }
        NSWorkspace.shared.open(url)
    }
}
