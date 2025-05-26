//  LocalizationManager.swift
//  exerun
//
//  Created by Nazar Odemchuk on 29/4/2025.
//

import Foundation
import ObjectiveC.runtime

// MARK: – Public façade
//──────────────────────────────────────────────────────────────────────────────
final class LocalizationManager {

    static let shared = LocalizationManager()

    // -------------------------------------------------------------------------
    private let userDefaultsKey = "selectedLanguage"

    /// The language that was active when the app booted for the very first time.
    /// We capture it **before** the app ever touches the AppleLanguages array so
    /// that we can safely “go back to system language”.
    private let systemLanguageCode: String

    private(set) var currentLanguage: String

    // -------------------------------------------------------------------------
    private init() {

        // 1️⃣ remember the *original* iOS language just once
        let raw = Locale.preferredLanguages.first ?? "en"
        systemLanguageCode =
            raw.split(separator: "-").first.map(String.init) ?? "en"

        // 2️⃣ pick the language to start with
        if let saved = UserDefaults.standard.string(forKey: userDefaultsKey) {
            currentLanguage = saved
        } else {
            currentLanguage = systemLanguageCode
        }

        setLanguage(currentLanguage)                // ← activate
    }

    // -------------------------------------------------------------------------
    /// Switch to a specific language code, e.g. `"en"`, `"uk"`.
    func setLanguage(_ code: String) {

        guard currentLanguage != code else { return }

        currentLanguage = code
        UserDefaults.standard.set(code, forKey: userDefaultsKey)
        UserDefaults.standard.set([code], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()

        Bundle.setLanguage(code)                    // swizzle
    }

    /// Forget every override and **return to the iOS language** the user picked
    /// in Settings (or English if your app doesn’t support it).
    func resetToSystemLanguage() {

        // 1️⃣ clear both override keys
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()

        // 2️⃣ fall back to what we saw on first launch
        setLanguage(systemLanguageCode)
    }

    // Convenience for one-off lookups, still used by older code
    func localizedString(forKey k: String) -> String {
        Bundle.main.localizedString(forKey: k, value: nil, table: nil)
    }
}

// MARK: – Bundle swizzling (unchanged)
//──────────────────────────────────────────────────────────────────────────────
private var bundleKey: UInt8 = 0

final class LocalizedBundle: Bundle, @unchecked Sendable {
    override func localizedString(forKey key: String,
                                  value: String?,
                                  table tableName: String?) -> String {
        let bundle = objc_getAssociatedObject(self, &bundleKey) as? Bundle ?? self
        return bundle.localizedString(forKey: key, value: value, table: tableName)
    }
}

extension Bundle {
    static func setLanguage(_ code: String) {
        object_setClass(Bundle.main, LocalizedBundle.self)

        guard let path = Bundle.main.path(forResource: code, ofType: "lproj"),
              let bundle = Bundle(path: path) else { return }

        objc_setAssociatedObject(Bundle.main, &bundleKey,
                                 bundle, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}
