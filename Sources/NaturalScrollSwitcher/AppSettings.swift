import Foundation
import NaturalScrollCore

final class AppSettings {
    private enum Key {
        static let mouseNaturalScrollEnabled = "mouseNaturalScrollEnabled"
        static let trackpadNaturalScrollEnabled = "trackpadNaturalScrollEnabled"
        static let forceMouseDirectionCorrection = "forceMouseDirectionCorrection"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var configuration: NaturalScrollConfiguration {
        NaturalScrollConfiguration(
            mouseNaturalScrollEnabled: bool(
                forKey: Key.mouseNaturalScrollEnabled,
                defaultValue: false
            ),
            trackpadNaturalScrollEnabled: bool(
                forKey: Key.trackpadNaturalScrollEnabled,
                defaultValue: true
            ),
            forceMouseDirectionCorrection: bool(
                forKey: Key.forceMouseDirectionCorrection,
                defaultValue: false
            )
        )
    }

    func naturalScrollEnabled(for source: InputSource) -> Bool {
        configuration.naturalScrollEnabled(for: source)
    }

    func setNaturalScrollEnabled(_ enabled: Bool, for source: InputSource) {
        switch source {
        case .mouse:
            defaults.set(enabled, forKey: Key.mouseNaturalScrollEnabled)
        case .trackpad:
            defaults.set(enabled, forKey: Key.trackpadNaturalScrollEnabled)
        }
    }

    func setForceMouseDirectionCorrection(_ enabled: Bool) {
        defaults.set(enabled, forKey: Key.forceMouseDirectionCorrection)
    }

    private func bool(forKey key: String, defaultValue: Bool) -> Bool {
        guard defaults.object(forKey: key) != nil else {
            return defaultValue
        }
        return defaults.bool(forKey: key)
    }
}
