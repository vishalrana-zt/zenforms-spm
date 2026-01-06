// ChartLabelRowView.swift

import SwiftUI

struct ChartLabelRowView: View {
    
    @State var strLbl: String
    var removeAlpha: Double = 1.0
    var onRemove: () -> Void
    var onLblChanged:((String) -> Void)? = nil
    var onKeyboardHiddenShown:((String) -> Void)? = nil

    var body: some View {
        HStack(spacing: 0) {
            TextField(FPLocalizationHelper.localize("lbl_Enter_label"), text: $strLbl) { isEditing in
                if !isEditing {
                    onKeyboardHiddenShown?(strLbl)
                }
            }
            .font(.system(size: 16))
            .padding(.horizontal)
            .textFieldStyle(.roundedBorder)
            .multilineTextAlignment(.leading)
            .keyboardType(.decimalPad)
            .onChange(of: strLbl) { newValue in
                strLbl =  newValue.filter { "0123456789.".contains($0) }
                onLblChanged?(strLbl)
            }
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.black)
            }
            .opacity(removeAlpha)
            .frame(width: 40, height: 40)
            .padding(.horizontal, 4)
        }
    }
}

// Sample preview and usage
struct LabelRowListView: View {
    @State private var labels: [String] = ["ok", "test"]
    
    var body: some View {
        VStack(alignment: .leading) {
            ForEach(labels.indices, id: \.self) { idx in
                ChartLabelRowView(strLbl: labels[idx]) {
                    labels.remove(at: idx)
                }
            }
        }
    }
}

#Preview {
    LabelRowListView()
}
