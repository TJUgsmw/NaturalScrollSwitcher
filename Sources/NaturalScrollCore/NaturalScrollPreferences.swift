import Foundation

public struct PreferenceWriteResult: Equatable {
    public let requestedValue: Bool
    public let synchronized: Bool
    public let refreshedPreferencesDaemon: Bool
    public let observedValue: Bool?

    public var succeeded: Bool {
        synchronized && observedValue == requestedValue
    }
}

public final class NaturalScrollPreferences {
    private let key = "com.apple.swipescrolldirection" as CFString

    public init() {}

    public func currentValue() -> Bool? {
        let value = CFPreferencesCopyValue(
            key,
            kCFPreferencesAnyApplication,
            kCFPreferencesCurrentUser,
            kCFPreferencesAnyHost
        )

        if let number = value as? NSNumber {
            return number.boolValue
        }

        if let string = value as? String {
            let normalized = string.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if ["1", "true", "yes"].contains(normalized) {
                return true
            }
            if ["0", "false", "no"].contains(normalized) {
                return false
            }
        }

        return nil
    }

    public func setNaturalScrollEnabled(_ enabled: Bool) -> PreferenceWriteResult {
        CFPreferencesSetValue(
            key,
            enabled ? kCFBooleanTrue : kCFBooleanFalse,
            kCFPreferencesAnyApplication,
            kCFPreferencesCurrentUser,
            kCFPreferencesAnyHost
        )

        let synchronized = CFPreferencesSynchronize(
            kCFPreferencesAnyApplication,
            kCFPreferencesCurrentUser,
            kCFPreferencesAnyHost
        )
        let refreshed = Self.refreshPreferencesDaemon()

        return PreferenceWriteResult(
            requestedValue: enabled,
            synchronized: synchronized,
            refreshedPreferencesDaemon: refreshed,
            observedValue: currentValue()
        )
    }

    private static func refreshPreferencesDaemon() -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
        process.arguments = ["cfprefsd"]

        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }
}
