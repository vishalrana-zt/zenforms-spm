//
//  ImageLoaderView.swift
//  crm
//
//  Created by apple on 20/11/25.
//  Copyright © 2025 SmartServ. All rights reserved.
//

import SwiftUI
internal import Kingfisher
struct ZTImageLoaderView: View {
    
    var urlString: String = ""
    var resizingMode: SwiftUI.ContentMode = .fit
    
    var body: some View {
        Rectangle()
            .opacity(0.001)
            .overlay {
                KFImage(URL(string: urlString))
                    .placeholder {
                        ProgressView()
                    }
                    .resizable()
                    .aspectRatio(contentMode: resizingMode)
                    .allowsHitTesting(false)
            }
            .clipped()
    }
}
