import Foundation

public struct AppLocalizer: Sendable {
    public let language: AppLanguage

    public init(language: AppLanguage = AppLanguage()) {
        self.language = language
    }

    public var unknown: String {
        switch language {
        case .english:
            return "Unknown"
        case .simplifiedChinese:
            return "未知"
        }
    }

    public var starting: String {
        switch language {
        case .english:
            return "Starting"
        case .simplifiedChinese:
            return "正在启动"
        }
    }

    public var noSwitchYet: String {
        switch language {
        case .english:
            return "No switch yet"
        case .simplifiedChinese:
            return "尚未切换"
        }
    }

    public var statusTooltip: String {
        switch language {
        case .english:
            return "NaturalScrollSwitcher"
        case .simplifiedChinese:
            return "自然滚动切换器"
        }
    }

    public func statusBarTitle(enabled: Bool?) -> String {
        guard let enabled else {
            return "?"
        }

        switch language {
        case .english:
            return enabled ? "On" : "Off"
        case .simplifiedChinese:
            return enabled ? "开" : "关"
        }
    }

    public var currentPrefix: String {
        switch language {
        case .english:
            return "Current"
        case .simplifiedChinese:
            return "当前模式"
        }
    }

    public var systemSettingPrefix: String {
        switch language {
        case .english:
            return "System setting"
        case .simplifiedChinese:
            return "系统设置"
        }
    }

    public var runModePrefix: String {
        switch language {
        case .english:
            return "Run mode"
        case .simplifiedChinese:
            return "运行模式"
        }
    }

    public var automaticSwitching: String {
        switch language {
        case .english:
            return "Automatic Switching"
        case .simplifiedChinese:
            return "自动切换"
        }
    }

    public var mouseNaturalScrolling: String {
        switch language {
        case .english:
            return "Mouse Natural Scrolling"
        case .simplifiedChinese:
            return "鼠标自然滚动"
        }
    }

    public var trackpadNaturalScrolling: String {
        switch language {
        case .english:
            return "Trackpad Natural Scrolling"
        case .simplifiedChinese:
            return "触控板自然滚动"
        }
    }

    public var requestPermissions: String {
        switch language {
        case .english:
            return "Request Permissions..."
        case .simplifiedChinese:
            return "请求权限..."
        }
    }

    public var openInputMonitoringSettings: String {
        switch language {
        case .english:
            return "Open Input Monitoring Settings"
        case .simplifiedChinese:
            return "打开输入监控设置"
        }
    }

    public var openAccessibilitySettings: String {
        switch language {
        case .english:
            return "Open Accessibility Settings"
        case .simplifiedChinese:
            return "打开辅助功能设置"
        }
    }

    public var quit: String {
        switch language {
        case .english:
            return "Quit"
        case .simplifiedChinese:
            return "退出"
        }
    }

    public func sourceName(_ source: InputSource) -> String {
        switch (language, source) {
        case (.english, .mouse):
            return "Mouse"
        case (.english, .trackpad):
            return "Trackpad"
        case (.simplifiedChinese, .mouse):
            return "鼠标"
        case (.simplifiedChinese, .trackpad):
            return "触控板"
        }
    }

    public func naturalState(_ enabled: Bool) -> String {
        switch language {
        case .english:
            return enabled ? "Natural On" : "Natural Off"
        case .simplifiedChinese:
            return enabled ? "自然滚动开启" : "自然滚动关闭"
        }
    }

    public func sourceTitle(_ source: InputSource, naturalScrollEnabled: Bool) -> String {
        "\(sourceName(source)): \(naturalState(naturalScrollEnabled))"
    }

    public func switchToSourceTitle(_ source: InputSource, naturalScrollEnabled: Bool) -> String {
        switch language {
        case .english:
            return "Switch to \(sourceTitle(source, naturalScrollEnabled: naturalScrollEnabled))"
        case .simplifiedChinese:
            return "切换到\(sourceTitle(source, naturalScrollEnabled: naturalScrollEnabled))"
        }
    }

    public func permissionsTitle(inputAccess: Bool, accessibilityTrusted: Bool) -> String {
        switch language {
        case .english:
            let input = inputAccess ? "Input OK" : "Input Missing"
            let accessibility = accessibilityTrusted ? "AX OK" : "AX Missing"
            return "Permissions: \(input), \(accessibility)"
        case .simplifiedChinese:
            let input = inputAccess ? "输入监控已授权" : "输入监控未授权"
            let accessibility = accessibilityTrusted ? "辅助功能已授权" : "辅助功能未授权"
            return "权限：\(input)，\(accessibility)"
        }
    }

    public func listenerTitle(status: String, writeStatus: String) -> String {
        switch language {
        case .english:
            return "Listener: \(status); \(writeStatus)"
        case .simplifiedChinese:
            return "监听：\(status)；\(writeStatus)"
        }
    }

    public func recentActionTitle(_ action: String) -> String {
        switch language {
        case .english:
            return "Recent action: \(action)"
        case .simplifiedChinese:
            return "最近动作：\(action)"
        }
    }

    public func runModeTitle(_ mode: NaturalScrollRunMode) -> String {
        switch (language, mode) {
        case (.english, .eventCorrection):
            return "Event Correction"
        case (.english, .globalFallback):
            return "Global Fallback"
        case (.english, .manualOnly):
            return "Manual Only"
        case (.simplifiedChinese, .eventCorrection):
            return "事件修正"
        case (.simplifiedChinese, .globalFallback):
            return "全局设置回退"
        case (.simplifiedChinese, .manualOnly):
            return "仅手动"
        }
    }

    public func alreadyApplied(_ source: InputSource, naturalScrollEnabled: Bool) -> String {
        switch language {
        case .english:
            return "Already \(sourceTitle(source, naturalScrollEnabled: naturalScrollEnabled))"
        case .simplifiedChinese:
            return "已是\(sourceTitle(source, naturalScrollEnabled: naturalScrollEnabled))"
        }
    }

    public func didApply(_ source: InputSource, naturalScrollEnabled: Bool) -> String {
        switch language {
        case .english:
            return "Set \(sourceTitle(source, naturalScrollEnabled: naturalScrollEnabled))"
        case .simplifiedChinese:
            return "已设置为\(sourceTitle(source, naturalScrollEnabled: naturalScrollEnabled))"
        }
    }

    public func didWriteSystemSetting(source: InputSource, naturalScrollEnabled: Bool) -> String {
        switch language {
        case .english:
            return "Wrote system setting for \(sourceTitle(source, naturalScrollEnabled: naturalScrollEnabled))"
        case .simplifiedChinese:
            return "已按\(sourceTitle(source, naturalScrollEnabled: naturalScrollEnabled))写入系统设置"
        }
    }

    public func writeFailed(observedValue: Bool?) -> String {
        let observed = observedValue.map(naturalState) ?? unknown
        switch language {
        case .english:
            return "Write failed, observed \(observed)"
        case .simplifiedChinese:
            return "写入失败，当前为\(observed)"
        }
    }

    public func preferenceChanged(source: InputSource, enabled: Bool) -> String {
        switch language {
        case .english:
            return "\(sourceName(source)) preference: \(naturalState(enabled))"
        case .simplifiedChinese:
            return "\(sourceName(source))偏好：\(naturalState(enabled))"
        }
    }

    public func eventAction(source: InputSource, corrected: Bool) -> String {
        switch (language, source, corrected) {
        case (.english, .mouse, true):
            return "Corrected mouse scroll"
        case (.english, .mouse, false):
            return "Mouse scroll passed through"
        case (.english, .trackpad, true):
            return "Corrected trackpad scroll"
        case (.english, .trackpad, false):
            return "Trackpad scroll passed through"
        case (.simplifiedChinese, .mouse, true):
            return "已修正鼠标滚动"
        case (.simplifiedChinese, .mouse, false):
            return "鼠标滚动未修正"
        case (.simplifiedChinese, .trackpad, true):
            return "已修正触控板滚动"
        case (.simplifiedChinese, .trackpad, false):
            return "触控板滚动未修正"
        }
    }

    public func passThroughAction(source: InputSource) -> String {
        eventAction(source: source, corrected: false)
    }

    public func trackpadBaselineSynced(enabled: Bool) -> String {
        switch language {
        case .english:
            return "Synced trackpad baseline: \(naturalState(enabled))"
        case .simplifiedChinese:
            return "已同步触控板基线：\(naturalState(enabled))"
        }
    }

    public func trackpadBaselineAlreadySynced(enabled: Bool) -> String {
        switch language {
        case .english:
            return "Trackpad baseline already \(naturalState(enabled))"
        case .simplifiedChinese:
            return "触控板基线已是\(naturalState(enabled))"
        }
    }

    public var eventTapUnavailable: String {
        switch language {
        case .english:
            return "Event tap unavailable"
        case .simplifiedChinese:
            return "事件监听不可用"
        }
    }

    public var runLoopSourceUnavailable: String {
        switch language {
        case .english:
            return "Run loop source unavailable"
        case .simplifiedChinese:
            return "运行循环监听不可用"
        }
    }

    public var listening: String {
        switch language {
        case .english:
            return "Listening"
        case .simplifiedChinese:
            return "正在监听"
        }
    }

    public func listening(mode: NaturalScrollRunMode) -> String {
        switch language {
        case .english:
            return "Listening: \(runModeTitle(mode))"
        case .simplifiedChinese:
            return "正在监听：\(runModeTitle(mode))"
        }
    }

    public var stopped: String {
        switch language {
        case .english:
            return "Stopped"
        case .simplifiedChinese:
            return "已停止"
        }
    }

    public var eventTapReenabled: String {
        switch language {
        case .english:
            return "Event tap re-enabled"
        case .simplifiedChinese:
            return "事件监听已恢复"
        }
    }

    public var waitingForInputMonitoringPermission: String {
        switch language {
        case .english:
            return "Waiting for Input Monitoring permission"
        case .simplifiedChinese:
            return "等待输入监控权限"
        }
    }

    public var waitingForRequiredPermissions: String {
        switch language {
        case .english:
            return "Waiting for Input Monitoring and Accessibility permissions"
        case .simplifiedChinese:
            return "等待输入监控和辅助功能权限"
        }
    }

    public var waitingForAutoDetectionPermission: String {
        switch language {
        case .english:
            return "Waiting for Input Monitoring permission"
        case .simplifiedChinese:
            return "等待输入监控权限"
        }
    }

    public var eventCorrectionUnavailableUsingFallback: String {
        switch language {
        case .english:
            return "Event correction unavailable; using global fallback"
        case .simplifiedChinese:
            return "事件修正不可用，使用全局设置回退"
        }
    }
}
