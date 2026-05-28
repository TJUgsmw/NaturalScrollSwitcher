import Foundation
import NaturalScrollCore

final class AppSettings {
    private enum Key {
        static let mouseNaturalScrollEnabled = "mouseNaturalScrollEnabled"
        static let trackpadNaturalScrollEnabled = "trackpadNaturalScrollEnabled"
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

    private func bool(forKey key: String, defaultValue: Bool) -> Bool {
        guard defaults.object(forKey: key) != nil else {
            return defaultValue
        }
        return defaults.bool(forKey: key)
    }
}
