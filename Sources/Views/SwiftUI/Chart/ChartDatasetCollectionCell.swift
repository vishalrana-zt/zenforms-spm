//
//  ChartDatasetCollectionCell.swift
//  crm
//
//  Created by apple on 12/11/25.
//  Copyright © 2025 SmartServ. All rights reserved.
//



import SwiftUI

struct ChartDatasetCollectionCell: View {
    
    @FocusState private var isFocused: Bool
    
    var lblHeader:String
    var isHeaderLblHidden:Bool
   
    @State var strDatasetValue: String
    var keyboardType:UIKeyboardType = .default
    var isInputHidden:Bool
    var cellIndxPath:IndexPath
    var onDatasetValueEditChanged:((String) -> Void)? = nil

    var isRemoveHidden:Bool
    var onRemove: () -> Void
    
    var backColor:Color = .white
    var isColorHidden:Bool
    var strColor:String
    var onColorClicked: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            if !isHeaderLblHidden{
                SwiftUI.Text(lblHeader)
                    .font(.footnote)
                    .foregroundStyle(Color("ZT-Black"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            
            if !isInputHidden{
                TextField("", text: $strDatasetValue)
                    .focused($isFocused)
                    .textFieldStyle(.roundedBorder)
                    .multilineTextAlignment(.center)
                    .keyboardType(keyboardType)
                    .onChange(of: strDatasetValue) { newValue in
                        if keyboardType == .decimalPad{
                            strDatasetValue =  newValue.filter { "0123456789.".contains($0) }
                        }else{
                            strDatasetValue = newValue
                        }
                    }
                    .onChange(of: isFocused) { isFocused in
                        if isFocused {
                            if cellIndxPath.row != 2, strDatasetValue == "0.0"{
                                strDatasetValue = ""
                            }
                        }else{
                            if cellIndxPath.row != 2, strDatasetValue.trim.isEmpty{
                                strDatasetValue = "0.0"
                            }
                            onDatasetValueEditChanged?(strDatasetValue)
                        }
                    }
            }
            
            
            if !isRemoveHidden{
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.headline)
                        .foregroundColor(.black)
                }
            }
            
            if !isColorHidden{
                Button(action: onColorClicked) {
                    Circle()
                        .fill(Color(hex:strColor))
                        .frame(width: 30, height: 30)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(8)
        .background(backColor)
        .border(Color(uiColor: UIColor.darkGray), width: 0.5)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
