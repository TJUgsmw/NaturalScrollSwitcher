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

    print("NaturalScrollSelfTest passed")
} catch {
    fputs("NaturalScrollSelfTest failed: \(error)\n", stderr)
    exit(1)
}
