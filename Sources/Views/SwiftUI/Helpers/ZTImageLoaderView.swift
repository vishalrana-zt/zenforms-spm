//
//  ImageLoaderView.swift
//  crm
//
//  Created by apple on 20/11/25.
//  Copyright © 2025 SmartServ. All rights reserved.
//

import SwiftUI
internal import SDWebImageSwiftUI

struct ZTImageLoaderView: View {
    
    var urlString:String = ""
    var resizingMode:ContentMode = .fit
    
    var body: some View {
        Rectangle()
            .opacity(0.001)
            .overlay {
                WebImage(url: URL(string: urlString))
                    .resizable()
                    .indicator(.activity)
                    .aspectRatio(contentMode: resizingMode)
                    .allowsHitTesting(false)
            }
            .clipped()
    }
}
