import Foundation

enum AppLanguage: String, CaseIterable, Sendable {
    case system, english = "en", spanish = "es"

    var title: String {
        switch self {
        case .system: return Loc.t("Follow phone")
        case .english: return "English"
        case .spanish: return "Español"
        }
    }
}

enum Loc {
    nonisolated(unsafe) static var preference = AppLanguage.system

    static let supported = ["en", "es"]

    static var code: String {
        switch preference {
        case .english: return "en"
        case .spanish: return "es"
        case .system:
            let best = Bundle.main.preferredLocalizations.first ?? "en"
            return supported.contains(best) ? best : "en"
        }
    }

    static var locale: Locale { Locale(identifier: code) }

    static var isSpanish: Bool { code == "es" }

    static var speechTags: [String] {
        isSpanish ? ["es-US", "es-MX", "es-ES"] : ["en-US", "en-GB"]
    }

    private nonisolated(unsafe) static var bundles: [String: Bundle] = [:]

    private static func bundle(for code: String) -> Bundle {
        if let cached = bundles[code] { return cached }
        let found = Bundle.main.path(forResource: code, ofType: "lproj").flatMap(Bundle.init(path:)) ?? Bundle.main
        bundles[code] = found
        return found
    }

    static func t(_ key: String) -> String {
        t(key, language: code)
    }

    static func t(_ key: String, language code: String) -> String {
        // English is the key, including when the bundle has no English resource.
        if code == "en" { return key }
        return bundle(for: code).localizedString(forKey: key, value: key, table: nil)
    }

    static func f(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: t(key), locale: locale, arguments: arguments)
    }

    static func number(_ value: Double, decimals: Int) -> String {
        String(format: "%.\(decimals)f", locale: locale, value)
    }
}
