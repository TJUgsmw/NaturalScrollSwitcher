import Foundation
import NaturalScrollCore

enum SelfTestError: Error, CustomStringConvertible {
    case failed(String)

    var description: String {
        switch self {
        case let .failed(message):
            return message
        }
    }
}

func expectEqual<T: Equatable>(_ actual: T, _ expected: T, _ message: String) throws {
    guard actual == expected else {
        throw SelfTestError.failed("\(message): expected \(expected), got \(actual)")
    }
}

func expectNil<T>(_ actual: T?, _ message: String) throws {
    guard actual == nil else {
        throw SelfTestError.failed("\(message): expected nil, got \(String(describing: actual))")
    }
}

do {
    var transitions = InputSourceTransitionTracker()
    var delivered = 0
    for _ in 0..<100_000 {
        if transitions.observe(.trackpad) { delivered += 1 }
    }
    try expectEqual(delivered, 1, "a gesture burst should deliver only the first source transition")
    try expectEqual(transitions.observe(.mouse), true, "switching to a mouse should deliver immediately")
    try expectEqual(transitions.observe(.mouse), false, "repeated mouse events should not refresh the menu")
    try expectEqual(transitions.observe(.trackpad), true, "switching back to a trackpad should still deliver")
    transitions.reset(to: .mouse)
    try expectEqual(transitions.observe(.trackpad), true, "trackpad input must override a manual mouse selection")
    transitions.reset()
    try expectEqual(transitions.observe(.trackpad), true, "restarting detection must observe the first device again")

    let logDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: logDirectory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: logDirectory) }
    let logURL = logDirectory.appendingPathComponent("events.log")
    try Data(String(repeating: "legacy diagnostic entry\n", count: 1_000).utf8).write(to: logURL)
    let boundedLog = BoundedDiagnosticsLog(url: logURL, maximumBytes: 2_048)
    boundedLog.append("upgrade entry")
    boundedLog.flush()
    try expectEqual(
        try Data(contentsOf: logURL).count <= 2_048,
        true,
        "upgrading must trim an oversized legacy log without loading all of it"
    )
    for index in 0..<500 {
        boundedLog.append("entry-\(index) \(String(repeating: "x", count: 80))")
    }
    boundedLog.append(String(repeating: "large-message", count: 1_000))
    boundedLog.append("final-entry")
    boundedLog.flush()
    let boundedData = try Data(contentsOf: logURL)
    try expectEqual(boundedData.count <= 2_048, true, "the log must stay bounded after repeated writes")
    let boundedText = String(decoding: boundedData, as: UTF8.self)
    try expectEqual(boundedText.hasSuffix("final-entry\n"), true, "log compaction must preserve the newest entry")

    try expectEqual(
        ScrollEventClassifier.classify(
            eventTypeRawValue: ScrollEventClassifier.scrollWheelEventTypeRawValue,
            isContinuousScroll: false
        ),
        .mouse,
        "non-continuous scroll should be mouse"
    )

    try expectEqual(
        ScrollEventClassifier.classify(
            ScrollEventSnapshot(
                eventTypeRawValue: ScrollEventClassifier.scrollWheelEventTypeRawValue,
                isContinuousScroll: true,
                pointDeltaAxis1: 4,
                scrollPhase: 1
            )
        ),
        .trackpad,
        "continuous scroll with touch phase should be trackpad"
    )

    try expectEqual(
        ScrollEventClassifier.classify(
            ScrollEventSnapshot(
                eventTypeRawValue: ScrollEventClassifier.scrollWheelEventTypeRawValue,
                isContinuousScroll: true,
                deltaAxis1: 1,
                scrollPhase: 1,
                recentMouseWheelInput: true
            )
        ),
        .mouse,
        "recent HID mouse wheel input should override touch-like scroll fields"
    )

    try expectEqual(
        ScrollEventClassifier.classify(
            ScrollEventSnapshot(
                eventTypeRawValue: ScrollEventClassifier.scrollWheelEventTypeRawValue,
                isContinuousScroll: false,
                deltaAxis1: 1,
                scrollPhase: 1
            )
        ),
        .mouse,
        "discrete wheel input should remain mouse even if scroll phase is present"
    )

    try expectEqual(
        ScrollEventClassifier.classify(
            ScrollEventSnapshot(
                eventTypeRawValue: ScrollEventClassifier.scrollWheelEventTypeRawValue,
                isContinuousScroll: true,
                deltaAxis1: 1,
                fixedPointDeltaAxis1: 65_536,
                scrollPhase: 1
            )
        ),
        .trackpad,
        "touch-phase scroll without recent HID mouse input should remain trackpad"
    )

    try expectEqual(
        ScrollEventClassifier.classify(
            eventTypeRawValue: ScrollEventClassifier.gestureEventTypeRawValue,
            isContinuousScroll: nil
        ),
        .trackpad,
        "gesture event should be trackpad"
    )

    try expectNil(
        ScrollEventClassifier.classify(eventTypeRawValue: -1, isContinuousScroll: false),
        "unknown event should be ignored"
    )

    let defaultConfiguration = NaturalScrollConfiguration()
    try expectEqual(
        defaultConfiguration.naturalScrollEnabled(for: .mouse),
        false,
        "default mouse natural scrolling should be off"
    )
    try expectEqual(
        defaultConfiguration.naturalScrollEnabled(for: .trackpad),
        true,
        "default trackpad natural scrolling should be on"
    )

    let customConfiguration = NaturalScrollConfiguration(
        mouseNaturalScrollEnabled: true,
        trackpadNaturalScrollEnabled: false
    )
    try expectEqual(
        customConfiguration.naturalScrollEnabled(for: .mouse),
        true,
        "custom mouse natural scrolling should be configurable"
    )
    try expectEqual(
        customConfiguration.naturalScrollEnabled(for: .trackpad),
        false,
        "custom trackpad natural scrolling should be configurable"
    )

    let defaultCorrection = ScrollEventClassifier.decision(
        for: ScrollEventSnapshot(
            eventTypeRawValue: ScrollEventClassifier.scrollWheelEventTypeRawValue,
            isContinuousScroll: true,
            deltaAxis1: 1
        ),
        configuration: NaturalScrollConfiguration()
    )
    try expectEqual(
        defaultCorrection,
        ScrollEventDecision(source: .mouse, shouldInvertEvent: true),
        "default mouse scrolling should be corrected against the trackpad baseline"
    )

    let alreadySyncedMouseCorrection = ScrollEventClassifier.decision(
        for: ScrollEventSnapshot(
            eventTypeRawValue: ScrollEventClassifier.scrollWheelEventTypeRawValue,
            isContinuousScroll: true,
            deltaAxis1: 1,
            eventNaturalScrollEnabled: false
        ),
        configuration: NaturalScrollConfiguration(
            mouseNaturalScrollEnabled: false,
            trackpadNaturalScrollEnabled: true,
            systemNaturalScrollEnabled: false
        )
    )
    try expectEqual(
        alreadySyncedMouseCorrection,
        ScrollEventDecision(source: .mouse, shouldInvertEvent: false),
        "mouse scrolling should pass through once the system setting already matches the mouse preference"
    )

    let pendingMouseCorrection = ScrollEventClassifier.decision(
        for: ScrollEventSnapshot(
            eventTypeRawValue: ScrollEventClassifier.scrollWheelEventTypeRawValue,
            isContinuousScroll: true,
            deltaAxis1: 1,
            eventNaturalScrollEnabled: true
        ),
        configuration: NaturalScrollConfiguration(
            mouseNaturalScrollEnabled: false,
            trackpadNaturalScrollEnabled: true,
            systemNaturalScrollEnabled: true
        )
    )
    try expectEqual(
        pendingMouseCorrection,
        ScrollEventDecision(source: .mouse, shouldInvertEvent: true),
        "mouse scrolling should be corrected while the system setting is still on the trackpad preference"
    )

    let naturalMouseCorrection = ScrollEventClassifier.decision(
        for: ScrollEventSnapshot(
            eventTypeRawValue: ScrollEventClassifier.scrollWheelEventTypeRawValue,
            isContinuousScroll: true,
            deltaAxis1: 1,
            eventNaturalScrollEnabled: true
        ),
        configuration: NaturalScrollConfiguration(
            mouseNaturalScrollEnabled: true,
            trackpadNaturalScrollEnabled: true
        )
    )
    try expectEqual(
        naturalMouseCorrection,
        ScrollEventDecision(source: .mouse, shouldInvertEvent: false),
        "mouse scrolling should pass through when mouse and trackpad preferences match"
    )

    let trackpadCorrection = ScrollEventClassifier.decision(
        for: ScrollEventSnapshot(
            eventTypeRawValue: ScrollEventClassifier.scrollWheelEventTypeRawValue,
            isContinuousScroll: true,
            pointDeltaAxis1: 5,
            scrollPhase: 2
        ),
        configuration: NaturalScrollConfiguration()
    )
    try expectEqual(
        trackpadCorrection,
        ScrollEventDecision(source: .trackpad, shouldInvertEvent: false),
        "trackpad scrolling should not be event-corrected"
    )

    let pendingTrackpadCorrection = ScrollEventClassifier.decision(
        for: ScrollEventSnapshot(
            eventTypeRawValue: ScrollEventClassifier.scrollWheelEventTypeRawValue,
            isContinuousScroll: true,
            pointDeltaAxis1: 5,
            scrollPhase: 2,
            eventNaturalScrollEnabled: false
        ),
        configuration: NaturalScrollConfiguration(
            mouseNaturalScrollEnabled: false,
            trackpadNaturalScrollEnabled: true,
            systemNaturalScrollEnabled: false
        )
    )
    try expectEqual(
        pendingTrackpadCorrection,
        ScrollEventDecision(source: .trackpad, shouldInvertEvent: true),
        "trackpad scrolling should be corrected if the current baseline is still the mouse preference"
    )

    let staleDefaultsMouseCorrection = ScrollEventClassifier.decision(
        for: ScrollEventSnapshot(
            eventTypeRawValue: ScrollEventClassifier.scrollWheelEventTypeRawValue,
            isContinuousScroll: true,
            deltaAxis1: 1,
            eventNaturalScrollEnabled: true
        ),
        configuration: NaturalScrollConfiguration(
            mouseNaturalScrollEnabled: false,
            trackpadNaturalScrollEnabled: true,
            systemNaturalScrollEnabled: false
        )
    )
    try expectEqual(
        staleDefaultsMouseCorrection,
        ScrollEventDecision(source: .mouse, shouldInvertEvent: true),
        "event direction should override stale defaults when System Settings has not refreshed the input pipeline"
    )

    try expectEqual(
        NaturalScrollRunMode.resolve(
            inputMonitoringAllowed: true,
            accessibilityTrusted: true
        ),
        .globalFallback,
        "input monitoring should use live system switching even when accessibility is granted"
    )
    try expectEqual(
        NaturalScrollRunMode.resolve(
            inputMonitoringAllowed: true,
            accessibilityTrusted: false
        ),
        .globalFallback,
        "input monitoring without accessibility should use global fallback"
    )
    try expectEqual(
        NaturalScrollRunMode.resolve(
            inputMonitoringAllowed: false,
            accessibilityTrusted: true
        ),
        .manualOnly,
        "missing input monitoring should use manual only mode"
    )
    try expectEqual(
        NaturalScrollRunMode.resolve(
            inputMonitoringAllowed: false,
            accessibilityTrusted: false
        ),
        .manualOnly,
        "missing input monitoring and accessibility should use manual only mode"
    )

    try expectEqual(
        AppLanguage(preferredLanguages: ["zh-Hans"]),
        .simplifiedChinese,
        "zh-Hans should select Simplified Chinese"
    )
    try expectEqual(
        AppLanguage(preferredLanguages: ["zh-CN"]),
        .simplifiedChinese,
        "zh-CN should select Simplified Chinese"
    )
    try expectEqual(
        AppLanguage(preferredLanguages: ["en"]),
        .english,
        "en should select English"
    )
    try expectEqual(
        AppLanguage(preferredLanguages: ["fr"]),
        .english,
        "non-Chinese languages should fall back to English"
    )

    let chineseLocalizer = AppLocalizer(language: .simplifiedChinese)
    try expectEqual(
        chineseLocalizer.automaticSwitching,
        "自动切换",
        "Chinese localizer should provide Chinese menu text"
    )
    try expectEqual(
        chineseLocalizer.sourceTitle(.trackpad, naturalScrollEnabled: true),
        "触控板: 自然滚动开启",
        "Chinese localizer should format trackpad state"
    )

    let englishLocalizer = AppLocalizer(language: .english)
    try expectEqual(
        englishLocalizer.automaticSwitching,
        "Automatic Switching",
        "English localizer should provide English menu text"
    )
    try expectEqual(
        englishLocalizer.sourceTitle(.mouse, naturalScrollEnabled: false),
        "Mouse: Natural Off",
        "English localizer should format mouse state"
    )
    try expectEqual(
        chineseLocalizer.statusBarTitle(enabled: true),
        "开",
        "Chinese status bar title should be compact"
    )
    try expectEqual(
        chineseLocalizer.runModeTitle(.globalFallback),
        "全局设置回退",
        "Chinese localizer should name the fallback run mode"
    )
    try expectEqual(
        englishLocalizer.statusBarTitle(enabled: false),
        "Off",
        "English status bar title should be compact"
    )
    try expectEqual(
        englishLocalizer.runModeTitle(.eventCorrection),
        "Event Correction",
        "English localizer should name the event correction run mode"
    )

    print("NaturalScrollSelfTest passed")
} catch {
    fputs("NaturalScrollSelfTest failed: \(error)\n", stderr)
    exit(1)
}
