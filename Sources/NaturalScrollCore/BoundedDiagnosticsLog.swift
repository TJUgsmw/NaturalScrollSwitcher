import Foundation

public final class BoundedDiagnosticsLog {
    private let url: URL
    private let maximumBytes: Int
    private let queue = DispatchQueue(label: "NaturalScrollSwitcher.diagnostics", qos: .utility)
    private let formatter = ISO8601DateFormatter()
    private var handle: FileHandle?
    private var byteCount: UInt64 = 0

    public init(url: URL, maximumBytes: Int = 1_048_576) {
        self.url = url
        self.maximumBytes = max(1_024, maximumBytes)
    }

    public func append(_ message: String) {
        queue.async { [self] in
            do {
                try openIfNeeded()
                let boundedMessage = message.prefix(min(1_024, maximumBytes / 8))
                let data = Data("\(formatter.string(from: Date())) \(boundedMessage)\n".utf8)
                try compactIfNeeded(adding: data.count)
                try handle?.write(contentsOf: data)
                byteCount += UInt64(data.count)
            } catch {
                try? handle?.close()
                handle = nil
            }
        }
    }

    public func flush() {
        queue.sync {
            try? handle?.synchronize()
        }
    }

    private func openIfNeeded() throws {
        guard handle == nil else {
            return
        }
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        if !FileManager.default.fileExists(atPath: url.path) {
            FileManager.default.createFile(atPath: url.path, contents: nil)
        }
        handle = try FileHandle(forUpdating: url)
        byteCount = try handle?.seekToEnd() ?? 0
    }

    private func compactIfNeeded(adding incomingBytes: Int) throws {
        guard byteCount + UInt64(incomingBytes) > UInt64(maximumBytes),
              let handle else {
            return
        }

        // Read only a bounded tail, including when upgrading a multi-GB old log.
        let retainedBytes = min(byteCount, UInt64(maximumBytes / 2))
        try handle.seek(toOffset: byteCount - retainedBytes)
        var tail = try handle.read(upToCount: Int(retainedBytes)) ?? Data()
        if let newline = tail.firstIndex(of: 10) {
            tail.removeSubrange(tail.startIndex...newline)
        } else {
            tail.removeAll()
        }
        try handle.truncate(atOffset: 0)
        try handle.seek(toOffset: 0)
        try handle.write(contentsOf: tail)
        byteCount = UInt64(tail.count)
    }
}
