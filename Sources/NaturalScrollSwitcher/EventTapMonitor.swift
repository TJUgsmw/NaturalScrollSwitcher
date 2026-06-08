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

enum ScrollEventAction {
    case passedThrough
    case invertedMouseScroll
}

struct ScrollEventObservation {
    let source: InputSource
    let action: ScrollEventAction
}

final class EventTapMonitor {
    var configuration = NaturalScrollConfiguration()
    var onInputEvent: ((ScrollEventObservation) -> Void)?
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
            place: .headInsertEventTap,
            options: .defaultTap,
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

    private func handle(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent> {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let eventTap {
                CGEvent.tapEnable(tap: eventTap, enable: true)
                DispatchQueue.main.async { [weak self] in
                    self?.onTapStatus?(.reenabled)
                }
            }
            return Unmanaged.passUnretained(event)
        }

        let snapshot = makeSnapshot(type: type, event: event)
        guard let decision = ScrollEventClassifier.decision(
            for: snapshot,
            configuration: configuration
        ) else {
            return Unmanaged.passUnretained(event)
        }

        let action: ScrollEventAction
        if decision.shouldInvertEvent {
            invertScrollEvent(event)
            action = .invertedMouseScroll
        } else {
            action = .passedThrough
        }

        DispatchQueue.main.async { [weak self] in
            self?.onInputEvent?(
                ScrollEventObservation(
                    source: decision.source,
                    action: action
                )
            )
        }

        return Unmanaged.passUnretained(event)
    }

    private func makeSnapshot(type: CGEventType, event: CGEvent) -> ScrollEventSnapshot {
        ScrollEventSnapshot(
            eventTypeRawValue: Int64(type.rawValue),
            isContinuousScroll: type == .scrollWheel ? event.getIntegerValueField(.scrollWheelEventIsContinuous) != 0 : nil,
            deltaAxis1: event.getIntegerValueField(.scrollWheelEventDeltaAxis1),
            deltaAxis2: event.getIntegerValueField(.scrollWheelEventDeltaAxis2),
            deltaAxis3: event.getIntegerValueField(.scrollWheelEventDeltaAxis3),
            fixedPointDeltaAxis1: event.getIntegerValueField(.scrollWheelEventFixedPtDeltaAxis1),
            fixedPointDeltaAxis2: event.getIntegerValueField(.scrollWheelEventFixedPtDeltaAxis2),
            fixedPointDeltaAxis3: event.getIntegerValueField(.scrollWheelEventFixedPtDeltaAxis3),
            pointDeltaAxis1: event.getIntegerValueField(.scrollWheelEventPointDeltaAxis1),
            pointDeltaAxis2: event.getIntegerValueField(.scrollWheelEventPointDeltaAxis2),
            pointDeltaAxis3: event.getIntegerValueField(.scrollWheelEventPointDeltaAxis3),
            scrollPhase: event.getIntegerValueField(.scrollWheelEventScrollPhase),
            momentumPhase: event.getIntegerValueField(.scrollWheelEventMomentumPhase)
        )
    }

    private func invertScrollEvent(_ event: CGEvent) {
        invertIntegerField(.scrollWheelEventDeltaAxis1, on: event)
        invertIntegerField(.scrollWheelEventDeltaAxis2, on: event)
        invertIntegerField(.scrollWheelEventDeltaAxis3, on: event)
        invertIntegerField(.scrollWheelEventFixedPtDeltaAxis1, on: event)
        invertIntegerField(.scrollWheelEventFixedPtDeltaAxis2, on: event)
        invertIntegerField(.scrollWheelEventFixedPtDeltaAxis3, on: event)
        invertIntegerField(.scrollWheelEventPointDeltaAxis1, on: event)
        invertIntegerField(.scrollWheelEventPointDeltaAxis2, on: event)
        invertIntegerField(.scrollWheelEventPointDeltaAxis3, on: event)
    }

    private func invertIntegerField(_ field: CGEventField, on event: CGEvent) {
        let value = event.getIntegerValueField(field)
        guard value != 0 else {
            return
        }
        event.setIntegerValueField(field, value: -value)
    }

    private static let eventTapCallback: CGEventTapCallBack = { _, type, event, userInfo in
        guard let userInfo else {
            return Unmanaged.passUnretained(event)
        }

        let monitor = Unmanaged<EventTapMonitor>.fromOpaque(userInfo).takeUnretainedValue()
        return monitor.handle(type: type, event: event)
    }
}
