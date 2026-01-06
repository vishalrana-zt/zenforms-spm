//
//  ZTProgressCircleView.swift
//  crm
//
//  Created by apple on 20/11/25.
//  Copyright © 2025 SmartServ. All rights reserved.
//

import SwiftUI

struct ZTProgressCircleView: View {
    var progress: CGFloat
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(.systemGray4), lineWidth: 4)
            Circle()
                .trim(from: 0.0, to: progress)
                .stroke(Color("DF-Green"), lineWidth: 4)
                .rotationEffect(.degrees(-90))
        }
    }
}

