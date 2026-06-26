import Foundation
import IOKit.hid

final class HIDMouseWheelMonitor {
    private let recentInputWindow: CFTimeInterval = 0.2
    private var manager: IOHIDManager?
    private var lastMouseWheelInputTime: CFTimeInterval = 0

    func start() {
        guard manager == nil else {
            return
        }

        let newManager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        IOHIDManagerSetDeviceMatching(newManager, nil)
        IOHIDManagerRegisterInputValueCallback(
            newManager,
            HIDMouseWheelMonitor.inputValueCallback,
            Unmanaged.passUnretained(self).toOpaque()
        )
        IOHIDManagerScheduleWithRunLoop(
            newManager,
            CFRunLoopGetMain(),
            CFRunLoopMode.commonModes.rawValue
        )

        let result = IOHIDManagerOpen(newManager, IOOptionBits(kIOHIDOptionsTypeNone))
        guard result == kIOReturnSuccess else {
            IOHIDManagerUnscheduleFromRunLoop(
                newManager,
                CFRunLoopGetMain(),
                CFRunLoopMode.commonModes.rawValue
            )
            return
        }

        manager = newManager
    }

    func stop() {
        guard let manager else {
            return
        }

        IOHIDManagerUnscheduleFromRunLoop(
            manager,
            CFRunLoopGetMain(),
            CFRunLoopMode.commonModes.rawValue
        )
        IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        self.manager = nil
        lastMouseWheelInputTime = 0
    }

    func hasRecentMouseWheelInput(now: CFTimeInterval = CFAbsoluteTimeGetCurrent()) -> Bool {
        now - lastMouseWheelInputTime <= recentInputWindow
    }

    private func handleInputValue(_ value: IOHIDValue) {
        let element = IOHIDValueGetElement(value)
        let usagePage = IOHIDElementGetUsagePage(element)
        let usage = IOHIDElementGetUsage(element)
        let device = IOHIDElementGetDevice(element)

        guard !isTrackpadLikeDevice(device),
              isWheelElement(usagePage: usagePage, usage: usage),
              IOHIDValueGetIntegerValue(value) != 0 else {
            return
        }

        lastMouseWheelInputTime = CFAbsoluteTimeGetCurrent()
    }

    private func isWheelElement(usagePage: UInt32, usage: UInt32) -> Bool {
        if usagePage == kHIDPage_GenericDesktop && usage == kHIDUsage_GD_Wheel {
            return true
        }

        return usagePage == kHIDPage_Consumer && usage == kHIDUsage_Csmr_ACPan
    }

    private func isTrackpadLikeDevice(_ device: IOHIDDevice) -> Bool {
        let searchableText = [
            stringProperty(kIOHIDProductKey, from: device),
            stringProperty(kIOHIDManufacturerKey, from: device),
            stringProperty(kIOHIDTransportKey, from: device)
        ]
        .compactMap { $0 }
        .joined(separator: " ")
        .lowercased()

        return searchableText.contains("trackpad") ||
            searchableText.contains("multitouch") ||
            searchableText.contains("multi-touch")
    }

    private func stringProperty(_ key: String, from device: IOHIDDevice) -> String? {
        IOHIDDeviceGetProperty(device, key as CFString).map { String(describing: $0) }
    }

    private static let inputValueCallback: IOHIDValueCallback = { context, _, _, value in
        guard let context else {
            return
        }

        let monitor = Unmanaged<HIDMouseWheelMonitor>.fromOpaque(context).takeUnretainedValue()
        monitor.handleInputValue(value)
    }
}
