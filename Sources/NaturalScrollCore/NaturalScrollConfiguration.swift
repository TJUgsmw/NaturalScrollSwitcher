import Foundation

public struct NaturalScrollConfiguration: Equatable, Sendable {
    public var mouseNaturalScrollEnabled: Bool
    public var trackpadNaturalScrollEnabled: Bool

    public init(
        mouseNaturalScrollEnabled: Bool = false,
        trackpadNaturalScrollEnabled: Bool = true
    ) {
        self.mouseNaturalScrollEnabled = mouseNaturalScrollEnabled
        self.trackpadNaturalScrollEnabled = trackpadNaturalScrollEnabled
    }

    public func naturalScrollEnabled(for source: InputSource) -> Bool {
        switch source {
        case .mouse:
            return mouseNaturalScrollEnabled
        case .trackpad:
            return trackpadNaturalScrollEnabled
        }
    }
}
