//
//  TableHeaderCollectionCell.swift
//  crm
//
//  Created by apple on 20/11/25.
//  Copyright © 2025 SmartServ. All rights reserved.
//

import SwiftUI

struct TableHeaderCollectionCell: View {
    
    var lblHeader:String
    var isHeaderLblHidden:Bool
    
    var isCheckBoxHidden:Bool
    @State var isCheckBoxSelcted:Bool = false
    var onCheckBoxClicked: (Bool) -> Void
    
    var isMoreActionHidden:Bool
    var imgMore:UIImage
    var imgMoreColor:Color
    var onMoreClicked: () -> Void
    
    var body: some View {
        HStack(spacing: 0) {            
            if !isHeaderLblHidden{
                SwiftUI.Text(lblHeader)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color("ZT-Black"))
                    .lineLimit(2)
                    .minimumScaleFactor(0.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
            
            if !isCheckBoxHidden{
                Button(action: {
                    isCheckBoxSelcted = !isCheckBoxSelcted
                    onCheckBoxClicked(isCheckBoxSelcted)
                }) {
                    Image(isCheckBoxSelcted ? "icn_row-checked" : "icn_row-unchecked")
                        .font(.headline)
                        .foregroundStyle(Color("BT-Primary"))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
            
            if !isMoreActionHidden{
                Button(action: onMoreClicked) {
                    Image(uiImage: imgMore)
                        .font(.headline)
                        .foregroundStyle(imgMoreColor)
                }
                .frame(width: 40)
            }
        }
        .padding(.leading, 8)
        .background(Color(hex: "#F0EFF6"))
        .border(Color(uiColor: UIColor.darkGray), width: 0.5)
    }
}

