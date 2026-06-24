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

    let naturalMouseCorrection = ScrollEventClassifier.decision(
        for: ScrollEventSnapshot(
            eventTypeRawValue: ScrollEventClassifier.scrollWheelEventTypeRawValue,
            isContinuousScroll: true,
            deltaAxis1: 1
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

    try expectEqual(
        NaturalScrollRunMode.resolve(
            inputMonitoringAllowed: true,
            accessibilityTrusted: true
        ),
        .eventCorrection,
        "full permissions should enable event correction"
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
