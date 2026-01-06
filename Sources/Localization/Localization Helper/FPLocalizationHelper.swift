
import Foundation
let LIB_ENGLISH_LANGUAGE_CODE = "en"
class FPLocalizationHelper {
    public static func localize(_ key: String) -> String {
        let lang = UserDefaults.libCurrentLanguage
        let libBundle = ZenFormsBundle.bundle
        guard let path = libBundle.path(forResource: lang, ofType: "lproj") else {
            return NSLocalizedString(key, comment: "")
        }
        guard let bundle = Bundle(path: path) else {
            return NSLocalizedString(key, comment: "")
        }
        let localizevalue = NSLocalizedString(key, bundle: bundle, comment: "")
        return localizevalue
    }

    public static func localizeWith(args: [CVarArg], key: String) -> String {
        String(format: localize(key), args)
    }
    
}
