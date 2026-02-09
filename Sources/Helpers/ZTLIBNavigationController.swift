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
        var appTint = UIColor(named: "BT-Primary") ?? .systemBlue
        if #available(iOS 26.0, *) {
            appTint = UIColor(named: "ZT-Black") ?? .black
        }
        let titleFont = UIFont.preferredFont(forTextStyle: .headline)
        let largeTitleFont = UIFont.preferredFont(forTextStyle: .largeTitle)

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBackground
        appearance.shadowColor = UIColor.black.withAlphaComponent(0.2)

        appearance.titleTextAttributes = [
            .font: titleFont,
            .foregroundColor: appTint
        ]
        appearance.largeTitleTextAttributes = [
            .font: largeTitleFont,
            .foregroundColor: appTint
        ]

        // Apply the appearance only to this navigation controller's bar
        let navBar = self.navigationBar
        navBar.standardAppearance = appearance
        navBar.scrollEdgeAppearance = appearance
        navBar.compactAppearance = appearance
        if #available(iOS 16.0, *) {
            navBar.compactScrollEdgeAppearance = appearance
        }

        navBar.tintColor = appTint
        navBar.barStyle = .default

        // Use opaque background to avoid translucency artifacts
        navBar.isTranslucent = false

        // Remove any layer-based shadows that can conflict with appearance
        navBar.layer.shadowOpacity = 0
        navBar.layer.shadowRadius = 0
        navBar.layer.shadowColor = nil
        navBar.layer.shadowOffset = .zero
    }

}
