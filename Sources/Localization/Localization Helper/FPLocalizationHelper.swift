
import Foundation
let LIB_ENGLISH_LANGUAGE_CODE = "en"
internal final class FPLocalizationHelper {
    static func localize(_ key: String) -> String {
        let lang = UserDefaults.libCurrentLanguage
        let libBundle = ZenFormsBundle.bundle

        // Try to find the .lproj bundle for the requested language
        if let path = libBundle.path(forResource: lang, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            let localizedValue = bundle.localizedString(forKey: key, value: nil, table: nil)
            // If localization found (value differs from key), return it
            if localizedValue != key {
                return localizedValue
            }
        }

        // Fallback: try English if requested language failed
        if lang != LIB_ENGLISH_LANGUAGE_CODE,
           let path = libBundle.path(forResource: LIB_ENGLISH_LANGUAGE_CODE, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            let localizedValue = bundle.localizedString(forKey: key, value: nil, table: nil)
            if localizedValue != key {
                return localizedValue
            }
        }

        // Final fallback: use the library bundle directly (for SPM processed resources)
        let localizedValue = libBundle.localizedString(forKey: key, value: nil, table: nil)
        if localizedValue != key {
            return localizedValue
        }

        // Return the key if nothing found
        return key
    }

    static func localizeWith(args: [CVarArg], key: String) -> String {
        String(format: localize(key), args)
    }
}
