
import Foundation
import UIKit

internal protocol FPIBLocalizable {
    var localizedKey: String? { get set }
}

extension UILabel: FPIBLocalizable {
    @IBInspectable var localizedKey: String? {
        get { nil }
        set(key) {
            applyLocalizedLable(key)
        }
    }
    
    // Not visible to the app
    internal func applyLocalizedLable(_ key: String?) {
        if let key = key { text = FPLocalizationHelper.localize(key) }
    }
}

extension UIButton: FPIBLocalizable {
    @IBInspectable var localizedKey: String? {
        get { nil }
        set(key) {
            if let key = key {
                applyLocalizedTitle(key)
            }
        }
    }

    // Not visible to the app
    internal func applyLocalizedTitle(_ key: String) {
        let value = FPLocalizationHelper.localize(key)
        setTitle(value, for: .normal)
        setTitle(value, for: .highlighted)
        setTitle(value, for: .selected)
        setTitle(value, for: .disabled)
        makeTitleAdjustAutomatically()
    }

    // Even stricter
    fileprivate func makeTitleAdjustAutomatically() {
        titleLabel?.adjustsFontSizeToFitWidth = true
        titleLabel?.minimumScaleFactor = 0.5
        titleLabel?.lineBreakMode = .byTruncatingTail
    }
}

extension UINavigationItem: FPIBLocalizable {
    @IBInspectable var localizedKey: String? {
        get { nil }
        set(key) {
            applyLocalizedValue(key)
        }
    }
    
    // Not visible to the app
    internal func applyLocalizedValue(_ key: String?) {
        if let key = key { title = FPLocalizationHelper.localize(key) }
    }
}

extension UIBarItem: FPIBLocalizable {
    @IBInspectable var localizedKey: String? {
        get { nil }
        set(key) {
            applyLocalizedName(key)
        }
    }
    
    // Not visible to the app
    internal func applyLocalizedName(_ key: String?) {
        if let key = key { title = FPLocalizationHelper.localize(key) }
    }
}

extension UITextField: FPIBLocalizable {
    @IBInspectable var localizedKey: String? {
        get { nil }
        set(key) {
            applyLocalizedPlaceholder(key)
        }
    }
    
    // Not visible to the app
    internal func applyLocalizedPlaceholder(_ key: String?) {
        if let key = key {
            placeholder = FPLocalizationHelper.localize(key)
        }
    }
}

