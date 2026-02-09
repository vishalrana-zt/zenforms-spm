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
            appTint = UIColor(named: "ZT-Black") ?? .label
        }

        let baseTitleFont = UIFont.preferredFont(forTextStyle: .headline)
        let baseLargeTitleFont = UIFont.preferredFont(forTextStyle: .largeTitle)

        let scaledTitleFont =
            UIFontMetrics(forTextStyle: .headline).scaledFont(for: baseTitleFont)

        let scaledLargeTitleFont =
            UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: baseLargeTitleFont)

        let appearance = UINavigationBarAppearance()

        if #available(iOS 26.0, *) {
            appearance.configureWithTransparentBackground()
            appearance.backgroundEffect =
                UIBlurEffect(style: .systemUltraThinMaterial)
            appearance.backgroundColor =
                UIColor.systemBackground.withAlphaComponent(0.85)

            appearance.shadowColor = UIColor.separator
        } else {
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .systemBackground
            appearance.shadowColor = UIColor.black.withAlphaComponent(0.2)
        }

        appearance.titleTextAttributes = [
            .font: scaledTitleFont,
            .foregroundColor: appTint
        ]

        appearance.largeTitleTextAttributes = [
            .font: scaledLargeTitleFont,
            .foregroundColor: appTint
        ]

        let navBar = self.navigationBar
        navBar.standardAppearance = appearance
        navBar.scrollEdgeAppearance = appearance
        navBar.compactAppearance = appearance

        if #available(iOS 16.0, *) {
            navBar.compactScrollEdgeAppearance = appearance
        }

        navBar.prefersLargeTitles = false
        navBar.tintColor = appTint
        navBar.barStyle = .default

        navBar.isTranslucent = true

        navBar.layer.shadowOpacity = 0
        navBar.layer.shadowRadius = 0
        navBar.layer.shadowColor = nil
        navBar.layer.shadowOffset = .zero
    }

}
