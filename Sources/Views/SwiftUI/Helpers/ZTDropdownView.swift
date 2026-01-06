import SwiftUI

struct ZTDropdownView: View {
    @State private var isExpanded = false
    @State var selectedItem: String = ""
    var placeholder = ""
    var items: [String] = []
    var isSearchable:Bool = true
    var isBorderNeeded:Bool = true
    @FocusState private var isInputFocused: Bool
    var onSelectChanged: ((String)-> Void)?
    @State private var isShowAllItems:Bool = true

    var filteredItems: [String] {
        if selectedItem.isEmpty {
            return items
        } else {
            return items.filter { $0.lowercased().contains(selectedItem.lowercased()) }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ZStack {
                HStack(spacing: 0) {
                    TextField(placeholder, text: $selectedItem)
                        .focused($isInputFocused)
                        .foregroundStyle(Color("ZT-Black"))
                        .font(.system(size: 14))
                        .lineLimit(1)
                        .minimumScaleFactor(0.25)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 16)
                        .disabled(!isSearchable)
                        .autocorrectionDisabled(true)
                        .onChange(of: selectedItem) { newValue in
                            withAnimation {
                                isShowAllItems = false
                                isExpanded = true
                            }
                        }
                        .onChange(of: isInputFocused) { isFocused in
                            withAnimation {
                                isExpanded = isFocused
                            }
                        }
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .padding(.horizontal, 8)
                        .padding(.vertical, 10)
                        .onTapGesture {
                            if isSearchable{
                                withAnimation {
                                    isShowAllItems = true
                                    isExpanded = !isExpanded
                                    if !isExpanded{
                                        isInputFocused = false
                                    }
                                }
                            }
                        }
                }
                if !isSearchable{
                    Button(action: {
                        withAnimation {
                            isShowAllItems = true
                            isExpanded = !isExpanded
                        }
                    }) {
                        SwiftUI.Text("Button")
                            .foregroundStyle(Color.clear)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: isBorderNeeded ? 4 : 0)
                    .stroke(Color(.systemGray4), lineWidth: isBorderNeeded ? 1 : 0)
            )
            
            if isExpanded {
                DropdownExpandedView(selectedItem: selectedItem, items: isShowAllItems ? items : filteredItems) { item in
                    selectedItem = item
                    isInputFocused = false
                    isExpanded = false
                    onSelectChanged?(selectedItem)
                }
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.8).combined(with: .opacity),
                    removal: .opacity
                ))
                .zIndex(1)
            }
        }
        .background(Color(.systemBackground))
    }
}

private struct DropdownExpandedView: View {
    @State var selectedItem: String = ""
    let items: [String]
    var onSelectChanged: ((String)-> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(items, id: \ .self) { item in
                Button(action: {
                    onSelectChanged?(item != FPLocalizationHelper.localize("SELECT") ? item : "")
                }) {
                    SwiftUI.Text(item)
                        .font(.system(size: 14))
                        .foregroundStyle(Color("ZT-Black"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(selectedItem == item ? Color(hex: "#F0EFF6") : Color.clear)
                }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 2)
        )
    }
}
