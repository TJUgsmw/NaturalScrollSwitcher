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
            eventTypeRawValue: ScrollEventClassifier.scrollWheelEventTypeRawValue,
            isContinuousScroll: true
        ),
        .trackpad,
        "continuous scroll should be trackpad"
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
        englishLocalizer.statusBarTitle(enabled: false),
        "Off",
        "English status bar title should be compact"
    )

    print("NaturalScrollSelfTest passed")
} catch {
    fputs("NaturalScrollSelfTest failed: \(error)\n", stderr)
    exit(1)
}
