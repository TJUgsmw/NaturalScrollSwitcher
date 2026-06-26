import AppKit
import Foundation
import NaturalScrollCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let preferences = NaturalScrollPreferences()
    private let settings = AppSettings()
    private let localizer = AppLocalizer()
    private let monitor = EventTapMonitor()
    private let diagnosticsLogger = EventDiagnosticsLogger()

    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let menu = NSMenu()
    private let modeItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    private let runModeItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    private let systemSettingItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    private let autoSwitchItem = NSMenuItem(title: "", action: #selector(toggleAutomaticSwitching), keyEquivalent: "")
    private let mouseNaturalItem = NSMenuItem(title: "", action: #selector(toggleMouseNaturalScrolling), keyEquivalent: "")
    private let trackpadNaturalItem = NSMenuItem(title: "", action: #selector(toggleTrackpadNaturalScrolling), keyEquivalent: "")
    private let forceMouseDirectionItem = NSMenuItem(title: "", action: #selector(toggleForceMouseDirectionCorrection), keyEquivalent: "")
    private let permissionItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    private let tapStatusItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    private let actionItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    private let requestPermissionsItem = NSMenuItem(title: "", action: #selector(requestPermissions), keyEquivalent: "")
    private let openInputSettingsItem = NSMenuItem(title: "", action: #selector(openInputMonitoringSettings), keyEquivalent: "")
    private let openAccessibilitySettingsItem = NSMenuItem(title: "", action: #selector(openAccessibilitySettings), keyEquivalent: "")
    private let switchMouseItem = NSMenuItem(title: "", action: #selector(switchToMouse), keyEquivalent: "")
    private let switchTrackpadItem = NSMenuItem(title: "", action: #selector(switchToTrackpad), keyEquivalent: "")
    private let quitItem = NSMenuItem(title: "", action: #selector(quit), keyEquivalent: "q")

    private var autoSwitchEnabled = true
    private var permissionState = PermissionManager.currentState()
    private var lastInputSource: InputSource?
    private var lastTapMessage = ""
    private var lastWriteStatus = ""
    private var lastActionStatus = ""
    private var activeRunMode: NaturalScrollRunMode = .manualOnly
    private var lastSyncedTrackpadBaseline: Bool?
    private var permissionTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        lastTapMessage = localizer.starting
        lastWriteStatus = localizer.noSwitchYet
        lastActionStatus = localizer.noSwitchYet
        configureMenu()
        configureMonitor()
        startPermissionPolling()
        refreshRuntimeState()
    }

    func applicationWillTerminate(_ notification: Notification) {
        permissionTimer?.invalidate()
        monitor.stop()
    }

    private func configureMenu() {
        configureStatusButton()

        [modeItem, runModeItem, systemSettingItem, permissionItem, tapStatusItem, actionItem].forEach { item in
            item.isEnabled = false
        }

        for item in [
            autoSwitchItem,
            mouseNaturalItem,
            trackpadNaturalItem,
            forceMouseDirectionItem,
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
        menu.addItem(runModeItem)
        menu.addItem(systemSettingItem)
        menu.addItem(permissionItem)
        menu.addItem(tapStatusItem)
        menu.addItem(actionItem)
        menu.addItem(.separator())
        menu.addItem(autoSwitchItem)
        menu.addItem(mouseNaturalItem)
        menu.addItem(trackpadNaturalItem)
        menu.addItem(forceMouseDirectionItem)
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

    private func configureStatusButton() {
        guard let button = statusItem.button else {
            return
        }

        button.title = localizer.statusBarTitle(enabled: nil)
        button.toolTip = localizer.statusTooltip
        button.imagePosition = .imageLeading
        button.imageScaling = .scaleProportionallyDown

        guard let url = Bundle.main.url(forResource: "StatusTemplate", withExtension: "png"),
              let image = NSImage(contentsOf: url) else {
            return
        }

        image.isTemplate = true
        image.size = NSSize(width: 18, height: 18)
        button.image = image
    }

    private func configureMonitor() {
        monitor.onInputEvent = { [weak self] observation in
            self?.handleInputEvent(observation)
        }

        monitor.onTapStatus = { [weak self] status in
            guard let self else {
                return
            }
            if case let .listening(mode) = status {
                self.activeRunMode = mode
                self.refreshMonitorConfiguration()
            }
            self.lastTapMessage = self.localizedTapStatus(status)
            self.updateMenu()
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
        refreshMonitorConfiguration()
        let desiredRunMode = NaturalScrollRunMode.resolve(
            inputMonitoringAllowed: permissionState.listenEventAccess,
            accessibilityTrusted: permissionState.accessibilityTrusted
        )

        if autoSwitchEnabled && desiredRunMode != .manualOnly {
            var monitorStarted = monitor.isRunning
            if !monitor.isRunning {
                monitorStarted = monitor.start(preferredRunMode: desiredRunMode)
            } else {
                let usingFallbackForRejectedEditableTap = desiredRunMode == .eventCorrection &&
                    monitor.activeRunMode == .globalFallback
                let shouldRestart = monitor.activeRunMode != desiredRunMode &&
                    (!usingFallbackForRejectedEditableTap || changed)
                if shouldRestart {
                    monitorStarted = monitor.start(preferredRunMode: desiredRunMode)
                }
            }

            guard monitorStarted else {
                activeRunMode = .manualOnly
                updateMenu()
                return
            }

            activeRunMode = monitor.activeRunMode ?? desiredRunMode
            refreshMonitorConfiguration()
            if activeRunMode == .globalFallback && desiredRunMode == .eventCorrection {
                lastTapMessage = localizer.eventCorrectionUnavailableUsingFallback
            }
        } else if monitor.isRunning {
            monitor.stop()
            activeRunMode = .manualOnly
        } else if !permissionState.canUseEventTap {
            activeRunMode = .manualOnly
            lastTapMessage = localizer.waitingForAutoDetectionPermission
        } else {
            activeRunMode = .manualOnly
        }

        if changed {
            updateMenu()
        } else {
            updateMenu()
        }
    }

    private func handleInputEvent(_ observation: ScrollEventObservation) {
        guard autoSwitchEnabled else {
            return
        }

        lastInputSource = observation.source
        lastActionStatus = localizer.eventAction(
            source: observation.source,
            corrected: observation.action != .passedThrough
        )
        diagnosticsLogger.logObservation(
            observation,
            runMode: activeRunMode,
            systemValue: preferences.currentValue()
        )
        switch activeRunMode {
        case .eventCorrection:
            applySystemSetting(for: observation.source)
        case .globalFallback:
            applySystemSetting(for: observation.source)
        case .manualOnly:
            break
        }

        updateMenu()
    }

    private func applySystemSetting(for source: InputSource) {
        let desiredValue = settings.naturalScrollEnabled(for: source)
        if preferences.currentValue() == desiredValue {
            lastWriteStatus = localizer.alreadyApplied(source, naturalScrollEnabled: desiredValue)
            lastActionStatus = localizer.passThroughAction(source: source)
            refreshMonitorConfiguration()
            diagnosticsLogger.log(
                "setting already source=\(source.rawValue) desired=\(desiredValue) observed=\(preferences.currentValue().map(String.init) ?? "unknown")"
            )
            return
        }

        let result = preferences.setNaturalScrollEnabled(desiredValue)
        if result.succeeded {
            refreshMonitorConfiguration()
            lastWriteStatus = localizer.didApply(source, naturalScrollEnabled: desiredValue)
            lastActionStatus = localizer.didWriteSystemSetting(
                source: source,
                naturalScrollEnabled: desiredValue
            )
            diagnosticsLogger.log(
                "setting wrote source=\(source.rawValue) desired=\(desiredValue) observed=\(result.observedValue.map(String.init) ?? "unknown") refreshed=\(result.refreshedPreferencesDaemon)"
            )
        } else {
            lastWriteStatus = localizer.writeFailed(observedValue: result.observedValue)
            diagnosticsLogger.log(
                "setting failed source=\(source.rawValue) desired=\(desiredValue) observed=\(result.observedValue.map(String.init) ?? "unknown") refreshed=\(result.refreshedPreferencesDaemon)"
            )
        }
    }

    private func syncTrackpadBaselineIfNeeded(force: Bool) {
        let baseline = settings.configuration.trackpadNaturalScrollEnabled
        guard force || lastSyncedTrackpadBaseline != baseline || preferences.currentValue() != baseline else {
            lastWriteStatus = localizer.trackpadBaselineAlreadySynced(enabled: baseline)
            return
        }

        let result = preferences.setNaturalScrollEnabled(baseline)
        if result.succeeded {
            lastSyncedTrackpadBaseline = baseline
            lastWriteStatus = localizer.trackpadBaselineSynced(enabled: baseline)
            diagnosticsLogger.log(
                "baseline wrote source=trackpad desired=\(baseline) observed=\(result.observedValue.map(String.init) ?? "unknown") refreshed=\(result.refreshedPreferencesDaemon)"
            )
        } else {
            lastWriteStatus = localizer.writeFailed(observedValue: result.observedValue)
            diagnosticsLogger.log(
                "baseline failed source=trackpad desired=\(baseline) observed=\(result.observedValue.map(String.init) ?? "unknown") refreshed=\(result.refreshedPreferencesDaemon)"
            )
        }
    }

    private func refreshMonitorConfiguration() {
        var configuration = settings.configuration
        configuration.systemNaturalScrollEnabled = preferences.currentValue()
        monitor.configuration = configuration
    }

    private func updateMenu() {
        let configuration = settings.configuration
        let currentModeTitle = lastInputSource.map {
            localizer.sourceTitle($0, naturalScrollEnabled: configuration.naturalScrollEnabled(for: $0))
        } ?? localizer.unknown
        modeItem.title = "\(localizer.currentPrefix): \(currentModeTitle)"
        runModeItem.title = "\(localizer.runModePrefix): \(localizer.runModeTitle(activeRunMode))"
        let systemValue = preferences.currentValue().map(localizer.naturalState) ?? localizer.unknown
        systemSettingItem.title = "\(localizer.systemSettingPrefix): \(systemValue)"
        permissionItem.title = localizer.permissionsTitle(
            inputAccess: permissionState.listenEventAccess,
            accessibilityTrusted: permissionState.accessibilityTrusted
        )
        tapStatusItem.title = localizer.listenerTitle(status: lastTapMessage, writeStatus: lastWriteStatus)
        actionItem.title = localizer.recentActionTitle(lastActionStatus)
        autoSwitchItem.title = localizer.automaticSwitching
        autoSwitchItem.state = autoSwitchEnabled ? .on : .off
        mouseNaturalItem.title = localizer.mouseNaturalScrolling
        mouseNaturalItem.state = configuration.mouseNaturalScrollEnabled ? .on : .off
        trackpadNaturalItem.title = localizer.trackpadNaturalScrolling
        trackpadNaturalItem.state = configuration.trackpadNaturalScrollEnabled ? .on : .off
        forceMouseDirectionItem.title = localizer.forceMouseDirectionCorrection
        forceMouseDirectionItem.state = configuration.forceMouseDirectionCorrection ? .on : .off
        switchMouseItem.title = localizer.switchToSourceTitle(
            .mouse,
            naturalScrollEnabled: configuration.mouseNaturalScrollEnabled
        )
        switchTrackpadItem.title = localizer.switchToSourceTitle(
            .trackpad,
            naturalScrollEnabled: configuration.trackpadNaturalScrollEnabled
        )
        requestPermissionsItem.title = localizer.requestPermissions
        openInputSettingsItem.title = localizer.openInputMonitoringSettings
        openAccessibilitySettingsItem.title = localizer.openAccessibilitySettings
        quitItem.title = localizer.quit

        switch lastInputSource {
        case .mouse:
            statusItem.button?.title = localizer.statusBarTitle(enabled: configuration.mouseNaturalScrollEnabled)
        case .trackpad:
            statusItem.button?.title = localizer.statusBarTitle(enabled: configuration.trackpadNaturalScrollEnabled)
        case nil:
            statusItem.button?.title = localizer.statusBarTitle(enabled: preferences.currentValue())
        }

        requestPermissionsItem.isHidden = permissionState.allPermissionsGranted
        openInputSettingsItem.isHidden = permissionState.listenEventAccess
        openAccessibilitySettingsItem.isHidden = permissionState.accessibilityTrusted
    }

    private func localizedTapStatus(_ status: EventTapStatus) -> String {
        switch status {
        case .eventTapUnavailable:
            return localizer.eventTapUnavailable
        case .runLoopSourceUnavailable:
            return localizer.runLoopSourceUnavailable
        case let .listening(mode):
            return localizer.listening(mode: mode)
        case .stopped:
            return localizer.stopped
        case .reenabled:
            return localizer.eventTapReenabled
        }
    }

    @objc private func toggleAutomaticSwitching() {
        autoSwitchEnabled.toggle()
        refreshRuntimeState()
    }

    @objc private func toggleMouseNaturalScrolling() {
        let enabled = !settings.configuration.mouseNaturalScrollEnabled
        settings.setNaturalScrollEnabled(enabled, for: .mouse)
        refreshMonitorConfiguration()
        lastWriteStatus = localizer.preferenceChanged(source: .mouse, enabled: enabled)
        if lastInputSource == .mouse {
            applySystemSetting(for: .mouse)
            updateMenu()
        } else {
            updateMenu()
        }
    }

    @objc private func toggleTrackpadNaturalScrolling() {
        let enabled = !settings.configuration.trackpadNaturalScrollEnabled
        settings.setNaturalScrollEnabled(enabled, for: .trackpad)
        refreshMonitorConfiguration()
        lastWriteStatus = localizer.preferenceChanged(source: .trackpad, enabled: enabled)
        if lastInputSource == .trackpad {
            applySystemSetting(for: .trackpad)
        }
        updateMenu()
    }

    @objc private func toggleForceMouseDirectionCorrection() {
        let enabled = !settings.configuration.forceMouseDirectionCorrection
        settings.setForceMouseDirectionCorrection(enabled)
        refreshMonitorConfiguration()
        lastWriteStatus = localizer.forceMouseDirectionCorrection
        updateMenu()
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
        lastInputSource = .mouse
        applySystemSetting(for: .mouse)
        updateMenu()
    }

    @objc private func switchToTrackpad() {
        lastInputSource = .trackpad
        applySystemSetting(for: .trackpad)
        updateMenu()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
