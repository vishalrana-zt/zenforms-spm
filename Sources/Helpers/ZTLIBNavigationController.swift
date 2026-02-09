//
//  ZTLIBNavigationController.swift
//  ZenForms
//
//  Created by apple on 09/02/26.
//

import UIKit
class ZTLIBNavigationController: UINavigationController {

    override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
        applyNavbarTheme()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        applyNavbarTheme()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        applyNavbarTheme()
    }
    
    func applyNavbarTheme() {
        FPUtility().setNavbarTheme()
    }

}
