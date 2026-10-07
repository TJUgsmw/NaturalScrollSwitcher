import Foundation
import NaturalScrollCore

struct EventDiagnosticsLogger {
    private let writer: BoundedDiagnosticsLog?
    private let detailedEventsEnabled = ProcessInfo.processInfo.environment["NSS_VERBOSE_EVENTS"] == "1"

    init() {
        let baseURL = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first?
            .appendingPathComponent("Logs", isDirectory: true)
            .appendingPathComponent("NaturalScrollSwitcher", isDirectory: true)
        if let baseURL {
            self.writer = BoundedDiagnosticsLog(url: baseURL.appendingPathComponent("events.log"))
        } else {
            self.writer = nil
        }
    }

    func log(_ message: String) {
        writer?.append(message)
    }

    func flush() {
        writer?.flush()
    }

    func logObservation(
        _ observation: ScrollEventObservation,
        runMode: NaturalScrollRunMode,
        systemValue: Bool?
    ) {
        guard detailedEventsEnabled else {
            return
        }
        log(
            "source=\(observation.source.rawValue) action=\(observation.action) runMode=\(runMode.rawValue) system=\(systemValue.map(String.init) ?? "unknown") " +
                "eventType=\(observation.snapshot.eventTypeRawValue) continuous=\(observation.snapshot.isContinuousScroll.map(String.init) ?? "nil") " +
                "delta=(\(observation.snapshot.deltaAxis1),\(observation.snapshot.deltaAxis2),\(observation.snapshot.deltaAxis3)) " +
                "fixed=(\(observation.snapshot.fixedPointDeltaAxis1),\(observation.snapshot.fixedPointDeltaAxis2),\(observation.snapshot.fixedPointDeltaAxis3)) " +
                "point=(\(observation.snapshot.pointDeltaAxis1),\(observation.snapshot.pointDeltaAxis2),\(observation.snapshot.pointDeltaAxis3)) " +
                "phase=\(observation.snapshot.scrollPhase) momentum=\(observation.snapshot.momentumPhase) " +
                "hidRecent=\(observation.snapshot.recentMouseWheelInput) eventNatural=\(observation.snapshot.eventNaturalScrollEnabled.map(String.init) ?? "nil") " +
                "ioHIDModified=\(observation.ioHIDModified)"
        )
    }
}
