
import Foundation
import UIKit

internal protocol FPIBLocalizable {
    var fpLocalizedKey: String? { get set }
}

extension UILabel: FPIBLocalizable {
    @objc var fpLocalizedKey: String? {
        get { nil }
        set(key) {
            if let key = key { text = FPLocalizationHelper.localize(key) }
        }
    }
}

extension UIButton: FPIBLocalizable {
    @objc var fpLocalizedKey: String? {
        get { nil }
        set(key) {
            if let key = key {
                setTitle(FPLocalizationHelper.localize(key), for: .normal)
                setTitle(FPLocalizationHelper.localize(key), for: .highlighted)
                setTitle(FPLocalizationHelper.localize(key), for: .selected)
                setTitle(FPLocalizationHelper.localize(key), for: .disabled)
                fpMakeTitleAdjustAutomatically()
            }

        }
    }

    func fpUpdateButtonTitle(title: String) {
        setTitle(title, for: .normal)
        setTitle(title, for: .highlighted)
        setTitle(title, for: .selected)
        setTitle(title, for: .disabled)
    }

    func fpMakeTitleAdjustAutomatically() {
        self.titleLabel?.adjustsFontSizeToFitWidth = true
        self.titleLabel?.minimumScaleFactor = 0.5
        self.titleLabel?.lineBreakMode = .byTruncatingTail
    }
}

extension UINavigationItem: FPIBLocalizable {
    @objc var fpLocalizedKey: String? {
        get { nil }
        set(key) {
            if let key = key { title = FPLocalizationHelper.localize(key) }
        }
    }
}

extension UIBarItem: FPIBLocalizable {
    @objc var fpLocalizedKey: String? {
        get { nil }
        set(key) {
            if let key = key { title = FPLocalizationHelper.localize(key) }
        }
    }
}

extension UITextField: FPIBLocalizable {
    @objc var fpLocalizedKey: String? {
        get { nil }
        set(key) {
            if let key = key {
                placeholder = FPLocalizationHelper.localize(key)
                self.adjustsFontSizeToFitWidth = true
                self.minimumFontSize = 12.0
            }
        }
    }
}
