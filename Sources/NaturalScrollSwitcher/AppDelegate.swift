import AppKit
import Foundation
import NaturalScrollCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let preferences = NaturalScrollPreferences()
    private let monitor = EventTapMonitor()

    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let menu = NSMenu()
    private let modeItem = NSMenuItem(title: "Current: Unknown", action: nil, keyEquivalent: "")
    private let systemSettingItem = NSMenuItem(title: "System setting: Unknown", action: nil, keyEquivalent: "")
    private let autoSwitchItem = NSMenuItem(title: "Automatic Switching", action: #selector(toggleAutomaticSwitching), keyEquivalent: "")
    private let permissionItem = NSMenuItem(title: "Permissions: Checking", action: nil, keyEquivalent: "")
    private let tapStatusItem = NSMenuItem(title: "Listener: Starting", action: nil, keyEquivalent: "")
    private let requestPermissionsItem = NSMenuItem(title: "Request Permissions...", action: #selector(requestPermissions), keyEquivalent: "")
    private let openInputSettingsItem = NSMenuItem(title: "Open Input Monitoring Settings", action: #selector(openInputMonitoringSettings), keyEquivalent: "")
    private let openAccessibilitySettingsItem = NSMenuItem(title: "Open Accessibility Settings", action: #selector(openAccessibilitySettings), keyEquivalent: "")
    private let switchMouseItem = NSMenuItem(title: "Switch to Mouse: Natural Off", action: #selector(switchToMouse), keyEquivalent: "")
    private let switchTrackpadItem = NSMenuItem(title: "Switch to Trackpad: Natural On", action: #selector(switchToTrackpad), keyEquivalent: "")
    private let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")

    private var autoSwitchEnabled = true
    private var permissionState = PermissionManager.currentState()
    private var lastInputSource: InputSource?
    private var lastTapMessage = "Starting"
    private var lastWriteStatus = "No switch yet"
    private var permissionTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        configureMenu()
        configureMonitor()
        requestPermissions()
        startPermissionPolling()
        refreshRuntimeState()
    }

    func applicationWillTerminate(_ notification: Notification) {
        permissionTimer?.invalidate()
        monitor.stop()
    }

    private func configureMenu() {
        statusItem.button?.title = "NS ?"

        [modeItem, systemSettingItem, permissionItem, tapStatusItem].forEach { item in
            item.isEnabled = false
        }

        for item in [
            autoSwitchItem,
            requestPermissionsItem,
            openInputSettingsItem,
            openAccessibilitySettingsItem,
            switchMouseItem,
            switchTrackpadItem,
            quitItem
        ] {
            item.target = self
        }

        menu.addItem(modeItem)
        menu.addItem(systemSettingItem)
        menu.addItem(permissionItem)
        menu.addItem(tapStatusItem)
        menu.addItem(.separator())
        menu.addItem(autoSwitchItem)
        menu.addItem(switchMouseItem)
        menu.addItem(switchTrackpadItem)
        menu.addItem(.separator())
        menu.addItem(requestPermissionsItem)
        menu.addItem(openInputSettingsItem)
        menu.addItem(openAccessibilitySettingsItem)
        menu.addItem(.separator())
        menu.addItem(quitItem)

        statusItem.menu = menu
        updateMenu()
    }

    private func configureMonitor() {
        monitor.onInputSource = { [weak self] source in
            self?.handleInputSource(source)
        }

        monitor.onTapMessage = { [weak self] message in
            self?.lastTapMessage = message
            self?.updateMenu()
        }
    }

    private func startPermissionPolling() {
        permissionTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refreshRuntimeState()
            }
        }
    }

    private func refreshRuntimeState() {
        let newState = PermissionManager.currentState()
        let changed = newState != permissionState
        permissionState = newState

        if autoSwitchEnabled && permissionState.canUseEventTap {
            if !monitor.isRunning {
                _ = monitor.start()
            }
        } else if monitor.isRunning {
            monitor.stop()
        } else if !permissionState.canUseEventTap {
            lastTapMessage = "Waiting for Input Monitoring permission"
        }

        if changed {
            updateMenu()
        } else {
            updateMenu()
        }
    }

    private func handleInputSource(_ source: InputSource) {
        guard autoSwitchEnabled else {
            return
        }
        apply(source: source, userInitiated: false)
    }

    private func apply(source: InputSource, userInitiated: Bool) {
        if !userInitiated && lastInputSource == source {
            return
        }

        let desiredValue = source.naturalScrollEnabled
        if preferences.currentValue() == desiredValue {
            lastInputSource = source
            lastWriteStatus = "Already \(source.menuTitle)"
            updateMenu()
            return
        }

        let result = preferences.setNaturalScrollEnabled(desiredValue)
        if result.succeeded {
            lastInputSource = source
            lastWriteStatus = "Set \(source.menuTitle)"
        } else {
            let observed = result.observedValue.map { $0 ? "On" : "Off" } ?? "Unknown"
            lastWriteStatus = "Write failed, observed \(observed)"
        }

        updateMenu()
    }

    private func updateMenu() {
        modeItem.title = "Current: \(lastInputSource?.menuTitle ?? "Unknown")"
        let systemValue = preferences.currentValue().map { $0 ? "Natural On" : "Natural Off" } ?? "Unknown"
        systemSettingItem.title = "System setting: \(systemValue)"
        permissionItem.title = permissionState.menuTitle
        tapStatusItem.title = "Listener: \(lastTapMessage); \(lastWriteStatus)"
        autoSwitchItem.state = autoSwitchEnabled ? .on : .off

        switch lastInputSource {
        case .mouse:
            statusItem.button?.title = "NS Off"
        case .trackpad:
            statusItem.button?.title = "NS On"
        case nil:
            statusItem.button?.title = preferences.currentValue() == true ? "NS On" : "NS Off"
        }

        requestPermissionsItem.isHidden = permissionState.canUseEventTap
        openInputSettingsItem.isHidden = permissionState.listenEventAccess
        openAccessibilitySettingsItem.isHidden = permissionState.accessibilityTrusted
    }

    @objc private func toggleAutomaticSwitching() {
        autoSwitchEnabled.toggle()
        refreshRuntimeState()
    }

    @objc private func requestPermissions() {
        permissionState = PermissionManager.requestPermissions()
        refreshRuntimeState()
    }

    @objc private func openInputMonitoringSettings() {
        PermissionManager.openInputMonitoringSettings()
    }

    @objc private func openAccessibilitySettings() {
        PermissionManager.openAccessibilitySettings()
    }

    @objc private func switchToMouse() {
        apply(source: .mouse, userInitiated: true)
    }

    @objc private func switchToTrackpad() {
        apply(source: .trackpad, userInitiated: true)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
