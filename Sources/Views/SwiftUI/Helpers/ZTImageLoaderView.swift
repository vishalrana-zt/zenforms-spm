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
    
    @State private var loadingFailed = false
    
    var body: some View {
        Rectangle()
            .opacity(0.001)
            .overlay {
                if loadingFailed {
                    Image("noimage")
                        .resizable()
                        .aspectRatio(contentMode: resizingMode)
                } else {
                    KFImage(URL(string: urlString))
                        .placeholder {
                            ProgressView()
                        }
                        .onFailure { error in
                            loadingFailed = true
                        }
                        .retry(maxCount: 1, interval: .seconds(2))
                        .onSuccess { result in
                            loadingFailed = false
                        }
                        .fade(duration: 0.25)
                        .resizable()
                        .aspectRatio(contentMode: resizingMode)
                        .allowsHitTesting(false)
                }
            }
            .clipped()
    }
}
