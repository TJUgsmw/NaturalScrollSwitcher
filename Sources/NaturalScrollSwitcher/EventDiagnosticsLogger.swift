import Foundation
import NaturalScrollCore

struct EventDiagnosticsLogger {
    private let logURL: URL?

    init() {
        let baseURL = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first?
            .appendingPathComponent("Logs", isDirectory: true)
            .appendingPathComponent("NaturalScrollSwitcher", isDirectory: true)
        if let baseURL {
            try? FileManager.default.createDirectory(at: baseURL, withIntermediateDirectories: true)
            self.logURL = baseURL.appendingPathComponent("events.log")
        } else {
            self.logURL = nil
        }
    }

    func log(_ message: String) {
        guard let logURL else {
            return
        }

        let timestamp = ISO8601DateFormatter().string(from: Date())
        let line = "\(timestamp) \(message)\n"
        guard let data = line.data(using: .utf8) else {
            return
        }

        if FileManager.default.fileExists(atPath: logURL.path) {
            if let handle = try? FileHandle(forWritingTo: logURL) {
                try? handle.seekToEnd()
                try? handle.write(contentsOf: data)
                try? handle.close()
            }
        } else {
            try? data.write(to: logURL)
        }
    }

    func logObservation(
        _ observation: ScrollEventObservation,
        runMode: NaturalScrollRunMode,
        systemValue: Bool?
    ) {
        log(
            "source=\(observation.source.rawValue) action=\(observation.action) runMode=\(runMode.rawValue) system=\(systemValue.map(String.init) ?? "unknown") " +
                "eventType=\(observation.snapshot.eventTypeRawValue) continuous=\(observation.snapshot.isContinuousScroll.map(String.init) ?? "nil") " +
                "delta=(\(observation.snapshot.deltaAxis1),\(observation.snapshot.deltaAxis2),\(observation.snapshot.deltaAxis3)) " +
                "fixed=(\(observation.snapshot.fixedPointDeltaAxis1),\(observation.snapshot.fixedPointDeltaAxis2),\(observation.snapshot.fixedPointDeltaAxis3)) " +
                "point=(\(observation.snapshot.pointDeltaAxis1),\(observation.snapshot.pointDeltaAxis2),\(observation.snapshot.pointDeltaAxis3)) " +
                "phase=\(observation.snapshot.scrollPhase) momentum=\(observation.snapshot.momentumPhase) hidRecent=\(observation.snapshot.recentMouseWheelInput)"
        )
    }
}
