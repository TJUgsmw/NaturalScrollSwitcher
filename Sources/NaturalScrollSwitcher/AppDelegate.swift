import AppKit
import Foundation
import NaturalScrollCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let preferences = NaturalScrollPreferences()
    private let settings = AppSettings()
    private let monitor = EventTapMonitor()

    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let menu = NSMenu()
    private let modeItem = NSMenuItem(title: "Current: Unknown", action: nil, keyEquivalent: "")
    private let systemSettingItem = NSMenuItem(title: "System setting: Unknown", action: nil, keyEquivalent: "")
    private let autoSwitchItem = NSMenuItem(title: "Automatic Switching", action: #selector(toggleAutomaticSwitching), keyEquivalent: "")
    private let mouseNaturalItem = NSMenuItem(title: "Mouse Natural Scrolling", action: #selector(toggleMouseNaturalScrolling), keyEquivalent: "")
    private let trackpadNaturalItem = NSMenuItem(title: "Trackpad Natural Scrolling", action: #selector(toggleTrackpadNaturalScrolling), keyEquivalent: "")
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
            mouseNaturalItem,
            trackpadNaturalItem,
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
        menu.addItem(mouseNaturalItem)
        menu.addItem(trackpadNaturalItem)
        menu.addItem(.separator())
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

        let desiredValue = settings.naturalScrollEnabled(for: source)
        let sourceTitle = source.menuTitle(naturalScrollEnabled: desiredValue)
        if preferences.currentValue() == desiredValue {
            lastInputSource = source
            lastWriteStatus = "Already \(sourceTitle)"
            updateMenu()
            return
        }

        let result = preferences.setNaturalScrollEnabled(desiredValue)
        if result.succeeded {
            lastInputSource = source
            lastWriteStatus = "Set \(sourceTitle)"
        } else {
            let observed = result.observedValue.map { $0 ? "On" : "Off" } ?? "Unknown"
            lastWriteStatus = "Write failed, observed \(observed)"
        }

        updateMenu()
    }

    private func updateMenu() {
        let configuration = settings.configuration
        let currentModeTitle = lastInputSource.map {
            $0.menuTitle(naturalScrollEnabled: configuration.naturalScrollEnabled(for: $0))
        } ?? "Unknown"
        modeItem.title = "Current: \(currentModeTitle)"
        let systemValue = preferences.currentValue().map { $0 ? "Natural On" : "Natural Off" } ?? "Unknown"
        systemSettingItem.title = "System setting: \(systemValue)"
        permissionItem.title = permissionState.menuTitle
        tapStatusItem.title = "Listener: \(lastTapMessage); \(lastWriteStatus)"
        autoSwitchItem.state = autoSwitchEnabled ? .on : .off
        mouseNaturalItem.state = configuration.mouseNaturalScrollEnabled ? .on : .off
        trackpadNaturalItem.state = configuration.trackpadNaturalScrollEnabled ? .on : .off
        switchMouseItem.title = "Switch to \(InputSource.mouse.menuTitle(naturalScrollEnabled: configuration.mouseNaturalScrollEnabled))"
        switchTrackpadItem.title = "Switch to \(InputSource.trackpad.menuTitle(naturalScrollEnabled: configuration.trackpadNaturalScrollEnabled))"

        switch lastInputSource {
        case .mouse:
            statusItem.button?.title = configuration.mouseNaturalScrollEnabled ? "NS On" : "NS Off"
        case .trackpad:
            statusItem.button?.title = configuration.trackpadNaturalScrollEnabled ? "NS On" : "NS Off"
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

    @objc private func toggleMouseNaturalScrolling() {
        let enabled = !settings.configuration.mouseNaturalScrollEnabled
        settings.setNaturalScrollEnabled(enabled, for: .mouse)
        lastWriteStatus = "Mouse preference: Natural \(enabled ? "On" : "Off")"
        if lastInputSource == .mouse {
            apply(source: .mouse, userInitiated: true)
        } else {
            updateMenu()
        }
    }

    @objc private func toggleTrackpadNaturalScrolling() {
        let enabled = !settings.configuration.trackpadNaturalScrollEnabled
        settings.setNaturalScrollEnabled(enabled, for: .trackpad)
        lastWriteStatus = "Trackpad preference: Natural \(enabled ? "On" : "Off")"
        if lastInputSource == .trackpad {
            apply(source: .trackpad, userInitiated: true)
        } else {
            updateMenu()
        }
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
