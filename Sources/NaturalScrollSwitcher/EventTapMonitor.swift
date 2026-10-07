import AppKit
import CoreGraphics
import Foundation
import NaturalScrollCore

enum EventTapStatus {
    case eventTapUnavailable
    case runLoopSourceUnavailable
    case listening(NaturalScrollRunMode)
    case stopped
    case reenabled
}

enum ScrollEventAction {
    case passedThrough
    case invertedScroll
}

struct ScrollEventObservation {
    let source: InputSource
    let action: ScrollEventAction
    let snapshot: ScrollEventSnapshot
    let ioHIDModified: Bool
}

final class EventTapMonitor {
    var configuration = NaturalScrollConfiguration()
    var onInputEvent: ((ScrollEventObservation) -> Void)?
    var onTapStatus: ((EventTapStatus) -> Void)?

    private let hidWheelMonitor = HIDMouseWheelMonitor()
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private(set) var activeRunMode: NaturalScrollRunMode?
    private var requestedRunMode: NaturalScrollRunMode?
    private var sourceTracker = InputSourceTransitionTracker()
    private var observationGeneration: UInt64 = 0

    var isRunning: Bool {
        eventTap != nil
    }

    @discardableResult
    func start(preferredRunMode: NaturalScrollRunMode) -> Bool {
        guard preferredRunMode != .manualOnly else {
            stop()
            return false
        }

        if isRunning && requestedRunMode == preferredRunMode {
            return true
        }

        if isRunning {
            stop()
        }
        requestedRunMode = preferredRunMode

        let scrollMask = CGEventMask(1) << CGEventType.scrollWheel.rawValue
        let gestureMask = CGEventMask(1) << UInt64(ScrollEventClassifier.gestureEventTypeRawValue)
        let mask = scrollMask | gestureMask

        let tapAndMode = makeTap(preferredRunMode: preferredRunMode, mask: mask)

        guard let tap = tapAndMode.tap else {
            activeRunMode = nil
            onTapStatus?(.eventTapUnavailable)
            return false
        }

        guard let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0) else {
            CFMachPortInvalidate(tap)
            onTapStatus?(.runLoopSourceUnavailable)
            return false
        }

        eventTap = tap
        activeRunMode = tapAndMode.mode
        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        hidWheelMonitor.start()
        onTapStatus?(.listening(tapAndMode.mode))
        return true
    }

    private func makeTap(
        preferredRunMode: NaturalScrollRunMode,
        mask: CGEventMask
    ) -> (tap: CFMachPort?, mode: NaturalScrollRunMode) {
        if preferredRunMode == .eventCorrection {
            let editableTap = createTap(options: .defaultTap, mask: mask)
            if let editableTap {
                return (editableTap, .eventCorrection)
            }
        }

        return (
            createTap(options: .listenOnly, mask: mask),
            .globalFallback
        )
    }

    private func createTap(
        options: CGEventTapOptions,
        mask: CGEventMask
    ) -> CFMachPort? {
        CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .tailAppendEventTap,
            options: options,
            eventsOfInterest: mask,
            callback: EventTapMonitor.eventTapCallback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        )
    }

    func stop() {
        resetInputSource()
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        if let tap = eventTap {
            CFMachPortInvalidate(tap)
        }
        runLoopSource = nil
        eventTap = nil
        activeRunMode = nil
        requestedRunMode = nil
        hidWheelMonitor.stop()
        onTapStatus?(.stopped)
    }

    func resetInputSource(to source: InputSource? = nil) {
        observationGeneration &+= 1
        sourceTracker.reset(to: source)
    }

    private func handle(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let eventTap {
                CGEvent.tapEnable(tap: eventTap, enable: true)
                DispatchQueue.main.async { [weak self] in
                    self?.onTapStatus?(.reenabled)
                }
            }
            return Unmanaged.passUnretained(event)
        }

        if Int64(type.rawValue) == ScrollEventClassifier.gestureEventTypeRawValue &&
            sourceTracker.lastSource == .trackpad {
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
        var ioHIDModified = false
        if activeRunMode == .eventCorrection && decision.shouldInvertEvent && snapshot.hasInvertibleDeltas {
            ioHIDModified = invertScrollEvent(event)
            action = .invertedScroll
        } else {
            action = .passedThrough
        }

        if sourceTracker.observe(decision.source) {
            notifyInputEvent(
                source: decision.source,
                action: action,
                snapshot: snapshot,
                ioHIDModified: ioHIDModified
            )
        }

        return Unmanaged.passUnretained(event)
    }

    private func notifyInputEvent(
        source: InputSource,
        action: ScrollEventAction,
        snapshot: ScrollEventSnapshot,
        ioHIDModified: Bool
    ) {
        let generation = observationGeneration
        DispatchQueue.main.async { [weak self] in
            guard let self, self.isRunning,
                  self.observationGeneration == generation else {
                return
            }
            self.onInputEvent?(
                ScrollEventObservation(
                    source: source,
                    action: action,
                    snapshot: snapshot,
                    ioHIDModified: ioHIDModified
                )
            )
        }
    }

    private func makeSnapshot(type: CGEventType, event: CGEvent) -> ScrollEventSnapshot {
        if Int64(type.rawValue) == ScrollEventClassifier.gestureEventTypeRawValue {
            return ScrollEventSnapshot(eventTypeRawValue: Int64(type.rawValue), isContinuousScroll: nil)
        }
        return ScrollEventSnapshot(
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
            momentumPhase: event.getIntegerValueField(.scrollWheelEventMomentumPhase),
            recentMouseWheelInput: hidWheelMonitor.hasRecentMouseWheelInput(),
            eventNaturalScrollEnabled: activeRunMode == .eventCorrection ? NSEvent(cgEvent: event)?.isDirectionInvertedFromDevice : nil
        )
    }

    private func invertScrollEvent(_ event: CGEvent) -> Bool {
        // Set the coarse delta first. macOS recalculates fixed and point deltas
        // when this field changes, so the precise fields must be written after it.
        invertIntegerField(.scrollWheelEventDeltaAxis1, on: event)
        invertIntegerField(.scrollWheelEventDeltaAxis2, on: event)
        invertIntegerField(.scrollWheelEventDeltaAxis3, on: event)
        invertDoubleField(.scrollWheelEventFixedPtDeltaAxis1, on: event)
        invertDoubleField(.scrollWheelEventFixedPtDeltaAxis2, on: event)
        invertDoubleField(.scrollWheelEventFixedPtDeltaAxis3, on: event)
        invertIntegerField(.scrollWheelEventPointDeltaAxis1, on: event)
        invertIntegerField(.scrollWheelEventPointDeltaAxis2, on: event)
        invertIntegerField(.scrollWheelEventPointDeltaAxis3, on: event)
        return IOHIDScrollEventBridge.shared.invertScrollValues(on: event)
    }

    private func invertIntegerField(_ field: CGEventField, on event: CGEvent) {
        let value = event.getIntegerValueField(field)
        guard value != 0 else {
            return
        }
        event.setIntegerValueField(field, value: -value)
    }

    private func invertDoubleField(_ field: CGEventField, on event: CGEvent) {
        let value = event.getDoubleValueField(field)
        guard value != 0 else {
            return
        }
        event.setDoubleValueField(field, value: -value)
    }

    private static let eventTapCallback: CGEventTapCallBack = { _, type, event, userInfo in
        guard let userInfo else {
            return Unmanaged.passUnretained(event)
        }

        let monitor = Unmanaged<EventTapMonitor>.fromOpaque(userInfo).takeUnretainedValue()
        return monitor.handle(type: type, event: event)
    }
}
