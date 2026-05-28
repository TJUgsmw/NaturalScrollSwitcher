import Foundation

public enum InputSource: String, Equatable, Sendable {
    case mouse
    case trackpad

    public var naturalScrollEnabled: Bool {
        switch self {
        case .mouse:
            return false
        case .trackpad:
            return true
        }
    }

    public var menuTitle: String {
        switch self {
        case .mouse:
            return "Mouse: Natural Off"
        case .trackpad:
            return "Trackpad: Natural On"
        }
    }

    public var statusTitle: String {
        switch self {
        case .mouse:
            return "Mouse Off"
        case .trackpad:
            return "Trackpad On"
        }
    }
}
