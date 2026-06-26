import Foundation

public struct ScrollEventSnapshot: Equatable, Sendable {
    public var eventTypeRawValue: Int64
    public var isContinuousScroll: Bool?
    public var deltaAxis1: Int64
    public var deltaAxis2: Int64
    public var deltaAxis3: Int64
    public var fixedPointDeltaAxis1: Int64
    public var fixedPointDeltaAxis2: Int64
    public var fixedPointDeltaAxis3: Int64
    public var pointDeltaAxis1: Int64
    public var pointDeltaAxis2: Int64
    public var pointDeltaAxis3: Int64
    public var scrollPhase: Int64
    public var momentumPhase: Int64
    public var recentMouseWheelInput: Bool

    public init(
        eventTypeRawValue: Int64,
        isContinuousScroll: Bool?,
        deltaAxis1: Int64 = 0,
        deltaAxis2: Int64 = 0,
        deltaAxis3: Int64 = 0,
        fixedPointDeltaAxis1: Int64 = 0,
        fixedPointDeltaAxis2: Int64 = 0,
        fixedPointDeltaAxis3: Int64 = 0,
        pointDeltaAxis1: Int64 = 0,
        pointDeltaAxis2: Int64 = 0,
        pointDeltaAxis3: Int64 = 0,
        scrollPhase: Int64 = 0,
        momentumPhase: Int64 = 0,
        recentMouseWheelInput: Bool = false
    ) {
        self.eventTypeRawValue = eventTypeRawValue
        self.isContinuousScroll = isContinuousScroll
        self.deltaAxis1 = deltaAxis1
        self.deltaAxis2 = deltaAxis2
        self.deltaAxis3 = deltaAxis3
        self.fixedPointDeltaAxis1 = fixedPointDeltaAxis1
        self.fixedPointDeltaAxis2 = fixedPointDeltaAxis2
        self.fixedPointDeltaAxis3 = fixedPointDeltaAxis3
        self.pointDeltaAxis1 = pointDeltaAxis1
        self.pointDeltaAxis2 = pointDeltaAxis2
        self.pointDeltaAxis3 = pointDeltaAxis3
        self.scrollPhase = scrollPhase
        self.momentumPhase = momentumPhase
        self.recentMouseWheelInput = recentMouseWheelInput
    }

    public var hasWheelSteps: Bool {
        deltaAxis1 != 0 || deltaAxis2 != 0 || deltaAxis3 != 0
    }

    public var hasPixelDeltas: Bool {
        fixedPointDeltaAxis1 != 0 ||
            fixedPointDeltaAxis2 != 0 ||
            fixedPointDeltaAxis3 != 0 ||
            pointDeltaAxis1 != 0 ||
            pointDeltaAxis2 != 0 ||
            pointDeltaAxis3 != 0
    }

    public var hasPointDeltas: Bool {
        pointDeltaAxis1 != 0 || pointDeltaAxis2 != 0 || pointDeltaAxis3 != 0
    }

    public var hasInvertibleDeltas: Bool {
        hasWheelSteps || hasPixelDeltas
    }

    public var hasTouchScrollPhase: Bool {
        scrollPhase != 0 || momentumPhase != 0
    }
}

public struct ScrollEventDecision: Equatable, Sendable {
    public var source: InputSource
    public var shouldInvertEvent: Bool

    public init(source: InputSource, shouldInvertEvent: Bool) {
        self.source = source
        self.shouldInvertEvent = shouldInvertEvent
    }
}

public enum ScrollEventClassifier {
    public static let scrollWheelEventTypeRawValue: Int64 = 22
    public static let gestureEventTypeRawValue: Int64 = 29

    public static func classify(_ snapshot: ScrollEventSnapshot) -> InputSource? {
        if snapshot.eventTypeRawValue == gestureEventTypeRawValue {
            return .trackpad
        }

        guard snapshot.eventTypeRawValue == scrollWheelEventTypeRawValue else {
            return nil
        }

        if snapshot.recentMouseWheelInput {
            return .mouse
        }

        if snapshot.isContinuousScroll == false {
            return .mouse
        }

        if snapshot.hasTouchScrollPhase {
            return .trackpad
        }

        if snapshot.hasWheelSteps {
            return .mouse
        }

        if snapshot.isContinuousScroll == true && snapshot.hasPixelDeltas {
            return .trackpad
        }

        return nil
    }

    public static func classify(
        eventTypeRawValue: Int64,
        isContinuousScroll: Bool?
    ) -> InputSource? {
        classify(
            ScrollEventSnapshot(
                eventTypeRawValue: eventTypeRawValue,
                isContinuousScroll: isContinuousScroll
            )
        )
    }

    public static func decision(
        for snapshot: ScrollEventSnapshot,
        configuration: NaturalScrollConfiguration
    ) -> ScrollEventDecision? {
        guard let source = classify(snapshot) else {
            return nil
        }

        let baseline = configuration.systemNaturalScrollEnabled ?? configuration.trackpadNaturalScrollEnabled
        let desired = configuration.naturalScrollEnabled(for: source)
        return ScrollEventDecision(source: source, shouldInvertEvent: baseline != desired)
    }
}
