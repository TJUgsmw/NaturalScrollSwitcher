import CoreFoundation
import CoreGraphics
import Darwin

final class IOHIDScrollEventBridge {
    static let shared = IOHIDScrollEventBridge()

    private typealias CopyIOHIDEvent = @convention(c) (CGEvent) -> Unmanaged<CFTypeRef>?
    private typealias GetFloatValue = @convention(c) (CFTypeRef, UInt32) -> Double
    private typealias SetFloatValue = @convention(c) (CFTypeRef, UInt32, Double) -> Void

    private static let scrollEventType: UInt32 = 6
    private static let scrollFieldBase = scrollEventType << 16
    private static let scrollXField = scrollFieldBase | 0
    private static let scrollYField = scrollFieldBase | 1

    private let coreGraphicsHandle: UnsafeMutableRawPointer?
    private let ioKitHandle: UnsafeMutableRawPointer?
    private let copyIOHIDEvent: CopyIOHIDEvent?
    private let getFloatValue: GetFloatValue?
    private let setFloatValue: SetFloatValue?

    private init() {
        coreGraphicsHandle = dlopen(
            "/System/Library/Frameworks/CoreGraphics.framework/CoreGraphics",
            RTLD_LAZY | RTLD_LOCAL
        )
        ioKitHandle = dlopen(
            "/System/Library/Frameworks/IOKit.framework/IOKit",
            RTLD_LAZY | RTLD_LOCAL
        )

        if let coreGraphicsHandle,
           let symbol = dlsym(coreGraphicsHandle, "CGEventCopyIOHIDEvent") {
            copyIOHIDEvent = unsafeBitCast(symbol, to: CopyIOHIDEvent.self)
        } else {
            copyIOHIDEvent = nil
        }

        if let ioKitHandle,
           let getSymbol = dlsym(ioKitHandle, "IOHIDEventGetFloatValue"),
           let setSymbol = dlsym(ioKitHandle, "IOHIDEventSetFloatValue") {
            getFloatValue = unsafeBitCast(getSymbol, to: GetFloatValue.self)
            setFloatValue = unsafeBitCast(setSymbol, to: SetFloatValue.self)
        } else {
            getFloatValue = nil
            setFloatValue = nil
        }
    }

    deinit {
        if let coreGraphicsHandle {
            dlclose(coreGraphicsHandle)
        }
        if let ioKitHandle {
            dlclose(ioKitHandle)
        }
    }

    @discardableResult
    func invertScrollValues(on event: CGEvent) -> Bool {
        guard let copyIOHIDEvent,
              let getFloatValue,
              let setFloatValue,
              let hidEvent = copyIOHIDEvent(event)?.takeRetainedValue() else {
            return false
        }

        let x = getFloatValue(hidEvent, Self.scrollXField)
        let y = getFloatValue(hidEvent, Self.scrollYField)
        setFloatValue(hidEvent, Self.scrollXField, -x)
        setFloatValue(hidEvent, Self.scrollYField, -y)
        return true
    }
}
