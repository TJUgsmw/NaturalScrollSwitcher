import CoreGraphics
import Foundation

// Zero-payload gesture events exercise the listener without moving the pointer.
let arguments = Array(CommandLine.arguments.dropFirst())
let mouseInput = arguments.contains("--mouse")
let duration = arguments.first.flatMap(Double.init) ?? 10
let event: CGEvent?
if mouseInput {
    event = CGEvent(scrollWheelEvent2Source: nil, units: .line, wheelCount: 1, wheel1: 0, wheel2: 0, wheel3: 0)
} else {
    event = CGEvent(source: nil)
    event?.type = CGEventType(rawValue: 29)!
}
guard duration > 0, duration <= 60, let event else {
    fputs("Usage: gesture_load_probe [seconds: 1...60] [--mouse]\n", stderr)
    exit(1)
}

let interval = 1.0 / 240.0
let started = ProcessInfo.processInfo.systemUptime
var count = 0
while ProcessInfo.processInfo.systemUptime - started < duration {
    event.post(tap: .cgSessionEventTap)
    count += 1
    let nextDeadline = started + Double(count) * interval
    let remaining = nextDeadline - ProcessInfo.processInfo.systemUptime
    if remaining > 0 {
        Thread.sleep(forTimeInterval: remaining)
    }
}
print("Posted \(count) zero-payload \(mouseInput ? "mouse" : "gesture") events in \(duration) seconds")
