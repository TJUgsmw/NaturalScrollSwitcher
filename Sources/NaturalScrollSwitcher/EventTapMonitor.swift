import CoreGraphics
import Foundation
import NaturalScrollCore

enum EventTapStatus {
    case eventTapUnavailable
    case runLoopSourceUnavailable
    case listening
    case stopped
    case reenabled
}

final class EventTapMonitor {
    var onInputSource: ((InputSource) -> Void)?
    var onTapStatus: ((EventTapStatus) -> Void)?

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    var isRunning: Bool {
        eventTap != nil
    }

    @discardableResult
    func start() -> Bool {
        if isRunning {
            return true
        }

        let scrollMask = CGEventMask(1) << CGEventType.scrollWheel.rawValue
        let gestureMask = CGEventMask(1) << UInt64(ScrollEventClassifier.gestureEventTypeRawValue)
        let mask = scrollMask | gestureMask

        let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .tailAppendEventTap,
            options: .listenOnly,
            eventsOfInterest: mask,
            callback: EventTapMonitor.eventTapCallback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        )

        guard let tap else {
            onTapStatus?(.eventTapUnavailable)
            return false
        }

        guard let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0) else {
            CFMachPortInvalidate(tap)
            onTapStatus?(.runLoopSourceUnavailable)
            return false
        }

        eventTap = tap
        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        onTapStatus?(.listening)
        return true
    }

    func stop() {
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        if let tap = eventTap {
            CFMachPortInvalidate(tap)
        }
        runLoopSource = nil
        eventTap = nil
        onTapStatus?(.stopped)
    }

    private func handle(type: CGEventType, event: CGEvent) {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let eventTap {
                CGEvent.tapEnable(tap: eventTap, enable: true)
                DispatchQueue.main.async { [weak self] in
                    self?.onTapStatus?(.reenabled)
                }
            }
            return
        }

        let continuous = event.getIntegerValueField(.scrollWheelEventIsContinuous) != 0
        let source = ScrollEventClassifier.classify(
            eventTypeRawValue: Int64(type.rawValue),
            isContinuousScroll: type == .scrollWheel ? continuous : nil
        )

        guard let source else {
            return
        }

        DispatchQueue.main.async { [weak self] in
            self?.onInputSource?(source)
        }
    }

    private static let eventTapCallback: CGEventTapCallBack = { _, type, event, userInfo in
        guard let userInfo else {
            return Unmanaged.passUnretained(event)
        }

        let monitor = Unmanaged<EventTapMonitor>.fromOpaque(userInfo).takeUnretainedValue()
        monitor.handle(type: type, event: event)
        return Unmanaged.passUnretained(event)
    }
}
