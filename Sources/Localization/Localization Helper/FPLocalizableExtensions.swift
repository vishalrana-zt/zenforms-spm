
import Foundation
import UIKit

internal protocol FPIBLocalizable {
    var localizedKey: String? { get set }
}

extension UILabel: FPIBLocalizable {
    var localizedKey: String? {
        get { nil }
        set(key) {
            if let key = key { text = FPLocalizationHelper.localize(key) }
        }
    }
}

extension UIButton: FPIBLocalizable {
    var localizedKey: String? {
        get { nil }
        set(key) {
            if let key = key {
                setTitle(FPLocalizationHelper.localize(key), for: .normal)
                setTitle(FPLocalizationHelper.localize(key), for: .highlighted)
                setTitle(FPLocalizationHelper.localize(key), for: .selected)
                setTitle(FPLocalizationHelper.localize(key), for: .disabled)
                makeTitleAdjustAutomatically()
            }

        }
    }
    
    func updateButtonTitle(title:String){
        setTitle(title, for: .normal)
        setTitle(title, for: .highlighted)
        setTitle(title, for: .selected)
        setTitle(title, for: .disabled)
    }
    
    func makeTitleAdjustAutomatically() {
        self.titleLabel?.adjustsFontSizeToFitWidth = true
        self.titleLabel?.minimumScaleFactor = 0.5
        self.titleLabel?.lineBreakMode = .byTruncatingTail
    }
}

extension UINavigationItem: FPIBLocalizable {
    var localizedKey: String? {
        get { nil }
        set(key) {
            if let key = key { title = FPLocalizationHelper.localize(key) }
        }
    }
}

extension UIBarItem: FPIBLocalizable {
    var localizedKey: String? {
        get { nil }
        set(key) {
            if let key = key { title = FPLocalizationHelper.localize(key) }
        }
    }
}

extension UITextField: FPIBLocalizable {
    var localizedKey: String? {
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

