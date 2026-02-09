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
        
        var primaryColor = UIColor(named: "BT-Primary") ?? .systemBlue
        if #available(iOS 26.0, *) {
            primaryColor = UIColor(named: "ZT-Black") ?? .label
        }
        
        let baseTitleFont = UIFont.preferredFont(forTextStyle: .headline)

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        
        let resolvedBackground = UIColor.systemBackground.resolvedColor(with: UITraitCollection.current)
        appearance.backgroundColor = resolvedBackground
        appearance.titleTextAttributes = [
            .font: baseTitleFont,
            .foregroundColor: primaryColor
        ]
        
        let titleLabelAppearance = UILabel.appearance(whenContainedInInstancesOf: [UINavigationBar.self])
        titleLabelAppearance.adjustsFontSizeToFitWidth = true
        titleLabelAppearance.minimumScaleFactor = 0.8
        titleLabelAppearance.adjustsFontForContentSizeCategory = true

        let navBar = UINavigationBar.appearance()

        navBar.standardAppearance = appearance
        navBar.scrollEdgeAppearance = appearance
        navBar.compactAppearance = appearance

        if #available(iOS 16.0, *) {
            navBar.compactScrollEdgeAppearance = appearance
        }

        navBar.tintColor = primaryColor
        navBar.prefersLargeTitles = false

        appearance.shadowColor = UIColor.black.withAlphaComponent(0.2)
    }

}
