import Foundation

public enum InputSource: String, Equatable, Sendable {
    case mouse
    case trackpad

    public var displayName: String {
        switch self {
        case .mouse:
            return "Mouse"
        case .trackpad:
            return "Trackpad"
        }
    }

    public func menuTitle(naturalScrollEnabled: Bool) -> String {
        "\(displayName): Natural \(naturalScrollEnabled ? "On" : "Off")"
    }
}
