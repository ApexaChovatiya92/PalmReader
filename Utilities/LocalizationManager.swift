//
//  LocalizationManager.swift
//  PalmistryApp
//
//  Created for Offline Palmistry App.
//

import SwiftUI

/// Languages the user can pick inside the app
public enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case hindi = "hi"
    case bengali = "bn"
    case marathi = "mr"
    case telugu = "te"
    case tamil = "ta"
    case gujarati = "gu"
    case urdu = "ur"
    case kannada = "kn"
    case odia = "or"
    case malayalam = "ml"

    public var id: String { rawValue }

    /// Name written in the language's own script
    public var nativeName: String {
        switch self {
        case .english: return "English"
        case .hindi: return "हिन्दी"
        case .bengali: return "বাংলা"
        case .marathi: return "मराठी"
        case .telugu: return "తెలుగు"
        case .tamil: return "தமிழ்"
        case .gujarati: return "ગુજરાતી"
        case .urdu: return "اردو"
        case .kannada: return "ಕನ್ನಡ"
        case .odia: return "ଓଡ଼ିଆ"
        case .malayalam: return "മലയാളം"
        }
    }

    public var englishName: String {
        switch self {
        case .english: return "English"
        case .hindi: return "Hindi"
        case .bengali: return "Bengali"
        case .marathi: return "Marathi"
        case .telugu: return "Telugu"
        case .tamil: return "Tamil"
        case .gujarati: return "Gujarati"
        case .urdu: return "Urdu"
        case .kannada: return "Kannada"
        case .odia: return "Odia"
        case .malayalam: return "Malayalam"
        }
    }

    public var isRightToLeft: Bool { self == .urdu }

    /// Letter tracking breaks conjuncts / joined letters in Indic & Arabic scripts
    public var supportsLetterTracking: Bool { self == .english }

    public var locale: Locale { Locale(identifier: "\(rawValue)_IN") }
}

/// Holds the selected in-app language and resolves localized strings from the matching `.lproj` bundle
@Observable
public final class LocalizationManager {
    public static let shared = LocalizationManager()

    /// Separates a key from its arguments in stored localized text (see `LocalizedText`)
    static let argumentSeparator: Character = "\u{1F}"
    private static let storageKey = "app.selectedLanguage"

    public var language: AppLanguage {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: Self.storageKey)
            bundle = Self.bundle(for: language)
        }
    }

    @ObservationIgnored private var bundle: Bundle
    @ObservationIgnored private let englishBundle = LocalizationManager.bundle(for: .english)

    private init() {
        let saved = UserDefaults.standard.string(forKey: Self.storageKey).flatMap(AppLanguage.init(rawValue:))
        let initial = saved ?? Self.preferredSystemLanguage()
        self.language = initial
        self.bundle = Self.bundle(for: initial)
    }

    /// Looks up a key in the selected language, falling back to English, then to the key itself
    /// (so readings saved before localization still show their original English text)
    public func string(forKey key: String) -> String {
        _ = language // registers observation so views refresh on language change
        let missing = "\u{0}"
        let value = bundle.localizedString(forKey: key, value: missing, table: nil)
        if value != missing { return value }
        let english = englishBundle.localizedString(forKey: key, value: missing, table: nil)
        return english != missing ? english : key
    }

    /// Resolves stored text that may be a plain key or a `LocalizedText`-encoded key with arguments
    public func resolve(_ text: String) -> String {
        let parts = text.split(separator: Self.argumentSeparator, omittingEmptySubsequences: false).map(String.init)
        guard parts.count > 1 else { return string(forKey: text) }
        let arguments = parts.dropFirst().map { resolve($0) as CVarArg }
        return String(format: string(forKey: parts[0]), locale: language.locale, arguments: arguments)
    }

    /// Joins items the way the selected language writes lists ("A, B and C")
    public func list(_ items: [String]) -> String {
        let formatter = ListFormatter()
        formatter.locale = language.locale
        return formatter.string(from: items) ?? items.joined(separator: ", ")
    }
    
    private static func bundle(for language: AppLanguage) -> Bundle {
        guard let path = Bundle.main.path(forResource: language.rawValue, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return .main
        }
        return bundle
    }

    private static func preferredSystemLanguage() -> AppLanguage {
        for identifier in Locale.preferredLanguages {
            let code = Locale(identifier: identifier).language.languageCode?.identifier ?? ""
            if let match = AppLanguage(rawValue: code) { return match }
        }
        return .english
    }
}

/// Builds storable text that is translated at display time, e.g. `LocalizedText.make("summary.holistic", "hand.right")`
public enum LocalizedText {
    public static func make(_ key: String, _ argumentKeys: String...) -> String {
        ([key] + argumentKeys).joined(separator: String(LocalizationManager.argumentSeparator))
    }
}

/// Localized string for a key (or `LocalizedText`-encoded stored text)
public func L(_ key: String) -> String {
    LocalizationManager.shared.resolve(key)
}

/// Localized format string filled with the given arguments
public func L(_ key: String, _ arguments: CVarArg...) -> String {
    let manager = LocalizationManager.shared
    return String(format: manager.string(forKey: key), locale: manager.language.locale, arguments: arguments)
}

public extension View {
    /// Applies letter tracking only for scripts where it doesn't break letter shaping
    func localizedTracking(_ value: CGFloat) -> some View {
        tracking(LocalizationManager.shared.language.supportsLetterTracking ? value : 0)
    }

    /// Injects the selected language's locale and reading direction
    func appLanguageEnvironment() -> some View {
        let language = LocalizationManager.shared.language
        return self
            .environment(\.locale, language.locale)
            .environment(\.layoutDirection, language.isRightToLeft ? .rightToLeft : .leftToRight)
    }
}

public extension Date {
    func localizedFormatted(date: Date.FormatStyle.DateStyle, time: Date.FormatStyle.TimeStyle) -> String {
        formatted(Date.FormatStyle(date: date, time: time).locale(LocalizationManager.shared.language.locale))
    }
}
