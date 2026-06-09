import Foundation

public enum NaturalScrollRunMode: String, Equatable, Sendable {
    case eventCorrection
    case globalFallback
    case manualOnly

    public static func resolve(
        inputMonitoringAllowed: Bool,
        accessibilityTrusted: Bool
    ) -> NaturalScrollRunMode {
        if inputMonitoringAllowed && accessibilityTrusted {
            return .eventCorrection
        }
        if inputMonitoringAllowed {
            return .globalFallback
        }
        return .manualOnly
    }
}
