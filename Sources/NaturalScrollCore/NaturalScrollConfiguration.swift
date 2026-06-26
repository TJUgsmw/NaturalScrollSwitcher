import Foundation

public struct NaturalScrollConfiguration: Equatable, Sendable {
    public var mouseNaturalScrollEnabled: Bool
    public var trackpadNaturalScrollEnabled: Bool
    public var systemNaturalScrollEnabled: Bool?
    public var forceMouseDirectionCorrection: Bool

    public init(
        mouseNaturalScrollEnabled: Bool = false,
        trackpadNaturalScrollEnabled: Bool = true,
        systemNaturalScrollEnabled: Bool? = nil,
        forceMouseDirectionCorrection: Bool = false
    ) {
        self.mouseNaturalScrollEnabled = mouseNaturalScrollEnabled
        self.trackpadNaturalScrollEnabled = trackpadNaturalScrollEnabled
        self.systemNaturalScrollEnabled = systemNaturalScrollEnabled
        self.forceMouseDirectionCorrection = forceMouseDirectionCorrection
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
