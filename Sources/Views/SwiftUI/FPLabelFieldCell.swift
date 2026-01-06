//
//  FPLabelFieldCell.swift
//  crm
//
//  Created by apple on 12/11/25.
//  Copyright © 2025 SmartServ. All rights reserved.
//

import SwiftUI

enum LABEL_FONT_SIZE: String {
    case small
    case medium
    case large
    
    var size: Int{
        switch self {
        case .small:
            return 12
        case .medium:
            return 16
        case .large:
            return 20
        }
    }
}

enum LABEL_ALIGNMENT: String {
    case left
    case center
    case right
}


struct FPLabelFieldCell: View {
    var fieldItem: FPFieldDetails

    @State var backGColor: Color = .white
    @State var title:AttributedString = AttributedString()
    @State var txtAllignment:Alignment = .leading
    
    var body: some View {
        SwiftUI.Text(title)
            .padding(10)
            .background(backGColor)
            .frame(maxWidth: .infinity, alignment: txtAllignment)
            .onAppear {
                fetchLabelConfiguration()
            }
    }
    
    func fetchLabelConfiguration(){
        if let options = fieldItem.options?.getDictonary(){
            let txtColor = options["textColor"] as? String
            let backgroundColor = options["backgroundColor"] as? String
            let isBold = options["bold"] as? Bool ?? false
            let italic = options["italic"] as? Bool ?? false
            let underline = options["underline"] as? Bool ?? false
            let alignment = LABEL_ALIGNMENT(rawValue: options["alignment"] as? String ?? "") ?? .left
            let fontSize = LABEL_FONT_SIZE(rawValue: options["size"] as? String ?? "") ?? .medium
            var attributes = [NSAttributedString.Key : Any]()
            if italic {
                attributes[NSAttributedString.Key.font] =  UIFont.systemFontItalic(size: CGFloat(fontSize.size), fontWeight: isBold ? .bold : .regular)
            }else{
                attributes[NSAttributedString.Key.font] = UIFont.systemFont(ofSize: CGFloat(fontSize.size), weight: isBold ? .bold : .regular)
            }
            if let colorVal = txtColor, !colorVal.trim.isEmpty{
                attributes[NSAttributedString.Key.foregroundColor] = FPUtility.colorwithHexString(colorVal)
            }else{
                attributes[NSAttributedString.Key.foregroundColor] = UIColor.black
            }
            if underline {
                attributes[NSAttributedString.Key.underlineStyle] =  NSUnderlineStyle.single.rawValue
            }
            if let backColorVal = backgroundColor, !backColorVal.trim.isEmpty{
                backGColor = Color(hex: backColorVal)
            }
            txtAllignment = .leading
            if alignment == .right{
                txtAllignment = .trailing
            }else if alignment == .center{
                txtAllignment = .center
            }
            let displayName = fieldItem.displayName?.handleAndDisplayApostrophe() ?? ""
            title = AttributedString(NSAttributedString(string: displayName, attributes: attributes))
        }else{
            let displayName = fieldItem.displayName?.handleAndDisplayApostrophe() ?? ""
            title =  AttributedString(displayName)
        }
    }
}

extension UIFont {
    static func systemFontItalic(size fontSize: CGFloat = 17.0, fontWeight: UIFont.Weight = .regular) -> UIFont {
        let font = UIFont.systemFont(ofSize: fontSize, weight: fontWeight)
        return UIFont(descriptor: font.fontDescriptor.withSymbolicTraits(.traitItalic)!, size: fontSize)
    }
}
