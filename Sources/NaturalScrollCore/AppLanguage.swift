import Foundation

public enum AppLanguage: String, Equatable, Sendable {
    case english
    case simplifiedChinese

    public init(preferredLanguages: [String] = Locale.preferredLanguages) {
        let primary = preferredLanguages.first?.lowercased() ?? ""
        if primary.hasPrefix("zh") {
            self = .simplifiedChinese
        } else {
            self = .english
        }
    }
}
