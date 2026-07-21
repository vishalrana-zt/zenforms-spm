//
//  DatasetColorPickerContentView.swift
//  ZenForms
//
//  Created by apple on 07/07/26.
//


//
//  DatasetColorPickerContentView.swift
//  crm
//

import SwiftUI

class ColorPickerSelectionState: ObservableObject {
    @Published var selectedIndex: Int?
    init(_ index: Int? = nil) { selectedIndex = index }
}

struct DatasetColorPickerContentView: View {
    let colors: [Color]
    let hexColors: [String]
    @ObservedObject var state: ColorPickerSelectionState
    var onSelect: (Int) -> Void

    private let itemSize: CGFloat = 48
    private let lineSpacing: CGFloat = 16
    private let interitemSpacing: CGFloat = 12
    private let inset: CGFloat = 16

    // 4 fixed columns to match the design
    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: interitemSpacing), count: 4)
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: lineSpacing) {
            ForEach(colors.indices, id: \.self) { index in
                ZStack {
                    Circle()
                        .fill(colors[index])
                        .frame(width: itemSize, height: itemSize)
                        .overlay(Circle().stroke(Color.primary.opacity(0.15), lineWidth: 1))

                    if state.selectedIndex == index {
                        Image(systemName: "checkmark")
                            .font(.system(size: itemSize * 0.4, weight: .bold))
                            .foregroundColor(colors[index].isLight ? .black : .white)
                    }
                }
                .onTapGesture {
                    guard state.selectedIndex != index else { return }
                    state.selectedIndex = index
                    onSelect(index)
                }
            }
        }
        .padding(inset)
        .background(Color(uiColor: .systemBackground))
    }
}

extension Color {
    var isLight: Bool {
        guard let components = UIColor(self).cgColor.components, components.count >= 3 else { return true }
        let brightness = (components[0] * 299 + components[1] * 587 + components[2] * 114) / 1000
        return brightness > 0.6
    }
}
