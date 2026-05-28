import Foundation

public enum ScrollEventClassifier {
    public static let scrollWheelEventTypeRawValue: Int64 = 22
    public static let gestureEventTypeRawValue: Int64 = 29

    public static func classify(
        eventTypeRawValue: Int64,
        isContinuousScroll: Bool?
    ) -> InputSource? {
        if eventTypeRawValue == gestureEventTypeRawValue {
            return .trackpad
        }

        guard eventTypeRawValue == scrollWheelEventTypeRawValue else {
            return nil
        }

        guard let isContinuousScroll else {
            return nil
        }

        return isContinuousScroll ? .trackpad : .mouse
    }
}
