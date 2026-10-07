import Foundation
import Darwin

public struct PreferenceWriteResult: Equatable {
    public let requestedValue: Bool
    public let synchronized: Bool
    public let refreshedPreferencesDaemon: Bool
    public let observedValue: Bool?
    public let liveObservedValue: Bool?
    public let usedLiveSystemAPI: Bool

    public var succeeded: Bool {
        synchronized &&
            observedValue == requestedValue &&
            (liveObservedValue == nil || liveObservedValue == requestedValue)
    }
}

public final class NaturalScrollPreferences {
    private let key = "com.apple.swipescrolldirection" as CFString
    private let liveAPI = SwipeScrollDirectionAPI()

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

    public func currentLiveValue() -> Bool? {
        liveAPI?.currentValue()
    }

    public func setNaturalScrollEnabled(
        _ enabled: Bool,
        forceLiveRefresh: Bool = false
    ) -> PreferenceWriteResult {
        let storedBeforeWrite = currentValue()
        let liveBeforeWrite = currentLiveValue()

        if let liveAPI {
            // The private setter is what System Settings uses. Calling it updates
            // the live HID preference; CFPreferences alone only changes the UI.
            if forceLiveRefresh &&
                storedBeforeWrite == enabled &&
                liveBeforeWrite != enabled {
                liveAPI.setValue(!enabled)
            }
            liveAPI.setValue(enabled)
        }

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
        let refreshed = liveAPI == nil ? Self.refreshPreferencesDaemon() : false

        return PreferenceWriteResult(
            requestedValue: enabled,
            synchronized: synchronized,
            refreshedPreferencesDaemon: refreshed,
            observedValue: currentValue(),
            liveObservedValue: currentLiveValue(),
            usedLiveSystemAPI: liveAPI != nil
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

private final class SwipeScrollDirectionAPI {
    private typealias Getter = @convention(c) () -> Int8
    private typealias Setter = @convention(c) (Int8) -> Void

    private let handle: UnsafeMutableRawPointer
    private let getter: Getter
    private let setter: Setter

    init?() {
        let path = "/System/Library/PrivateFrameworks/PreferencePanesSupport.framework/PreferencePanesSupport"
        guard let handle = dlopen(path, RTLD_LAZY | RTLD_LOCAL),
              let getterSymbol = dlsym(handle, "swipeScrollDirection"),
              let setterSymbol = dlsym(handle, "setSwipeScrollDirection") else {
            return nil
        }

        self.handle = handle
        getter = unsafeBitCast(getterSymbol, to: Getter.self)
        setter = unsafeBitCast(setterSymbol, to: Setter.self)
    }

    deinit {
        dlclose(handle)
    }

    func currentValue() -> Bool {
        getter() != 0
    }

    func setValue(_ enabled: Bool) {
        setter(enabled ? 1 : 0)
    }
}
