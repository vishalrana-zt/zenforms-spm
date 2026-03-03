//
//  SegmentControlView.swift
//  ZenForms
//
//  SwiftUI implementation of the segment control (grey track, white pill).
//

import SwiftUI

struct SegmentControlView: View {
    let titles: [String]
    let selectedIndex: Int
    let onSelect: (Int) -> Void
    var isEnabled: Bool = true

    /// Local state so the pill updates immediately on tap (like old UIKit). No dependency on table reload.
    @State private var displayedIndex: Int

    private let stackInset: CGFloat = 2
    private let pillRadius: CGFloat = 6
    private let trackRadius: CGFloat = 8

    init(titles: [String], selectedIndex: Int, onSelect: @escaping (Int) -> Void, isEnabled: Bool = true) {
        self.titles = titles
        self.selectedIndex = selectedIndex
        self.onSelect = onSelect
        self.isEnabled = isEnabled
        _displayedIndex = State(initialValue: selectedIndex >= 0 && selectedIndex < titles.count ? selectedIndex : -1)
    }

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            HStack(spacing: 0) {
                ForEach(Array(titles.enumerated()), id: \.offset) { index, title in
                    Text(title)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: pillRadius)
                                .fill(index == displayedIndex ? Color.white : Color.clear)
                        )
                }
            }
            .padding(stackInset)
            .contentShape(Rectangle())
            .onTapGesture(coordinateSpace: .local) { location in
                guard isEnabled, !titles.isEmpty, width > 0 else { return }
                let segmentWidth = width / CGFloat(titles.count)
                let rawIndex = Int(location.x / segmentWidth)
                let index = min(max(rawIndex, 0), titles.count - 1)
                displayedIndex = index
                onSelect(index)
            }
        }
        .frame(height: 40)
        .background(
            RoundedRectangle(cornerRadius: trackRadius)
                .fill(Color(uiColor: .systemGray5))
        )
        .allowsHitTesting(isEnabled)
        .onChange(of: selectedIndex) { newValue in
            if newValue >= 0 && newValue < titles.count {
                displayedIndex = newValue
            }
        }
    }
}

// MARK: - Delegate (used by FPSegmentView when hosting this view in a table cell)
protocol SegmentControlDelegate: AnyObject {
    func segmentValueChangedAt(indexPath index: IndexPath?, withSelectedIndex: Int)
}
