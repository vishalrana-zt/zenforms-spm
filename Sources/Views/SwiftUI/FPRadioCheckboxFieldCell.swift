import SwiftUI

struct FPRadioCheckboxFieldCell: View {
    var isNew:Bool = false
    var fieldItem:FPFieldDetails
    var section:Int
    var tag:Int
    var arrOptions: [FPFieldOption] = []

    var onRadioBtnClicked: ((String) -> Void)? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if fieldItem.mandatory, fieldItem.getUIType() != .AUTO_POPULATE{
                SwiftUI.Text(fetchAttributedString())
            }else{
                SwiftUI.Text(fieldItem.displayName ?? "")
                    .font(.headline)
                    .foregroundColor(Color("ZT-Black"))
            }
            
            VStack(alignment: .leading, spacing: 0) {
                ForEach(arrOptions.indices, id: \.self) { idx in
                    let option = arrOptions[idx]
                    let isSelected = getIsSelected(option: option)
                    Button(action: {
                        let toggleValue = isSelected ? false : true
                        if fieldItem.getUIType()  == .CHECKBOX {
                            var checkboxValue = (fieldItem.value?.getDictonary() as? [String:Bool])
                            checkboxValue?[arrOptions[safe: idx]?.key ?? ""] = toggleValue
                            onRadioBtnClicked?(checkboxValue?.getJson() ?? "")
                        } else if toggleValue {
                            let value = arrOptions[safe: idx]?.value ?? ""
                            onRadioBtnClicked?(value)
                        }
                    }) {
                        HStack(spacing: 2) {
                            Image(fetchRadioImageForRow(isSelected:isSelected))
                                .resizable()
                                .frame(width: 24, height: 24)
                                .foregroundStyle(Color("BT-Primary"))
                                .padding(.trailing, 8)
                                .padding(.vertical, 4)

                            SwiftUI.Text(getLabelText(option: option))
                                .font(.system(size: 16.0))
                                .foregroundStyle(Color("ZT-Black"))
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.systemBackground))
                        }
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                }
            }
        }
        .padding(10)
    }
    
    func fetchRadioImageForRow(isSelected: Bool) -> String{
        if fieldItem.getUIType()  == .CHECKBOX {
            return isSelected ? "selectCheck" : "selectUncheck"
        } else {
            return isSelected ? "radio_on" : "radio_off"
        }
    }
        
    func fetchAttributedString() -> AttributedString {
        let fontAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 17, weight: .semibold), .foregroundColor: UIColor.black]
        let baseString =  NSAttributedString(string: " \(fieldItem.displayName ?? "")", attributes: fontAttributes)
        let colrattributes: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.red]
        let starString =  NSAttributedString(string: "*", attributes: colrattributes)
        let mutableString = NSMutableAttributedString(attributedString: starString)
        mutableString.append(baseString)
        return AttributedString(mutableString)
    }
    
    func getIsSelected(option: FPFieldOption) -> Bool {
        if fieldItem.getUIType() == .CHECKBOX {
            if let key = option.key, let value = (fieldItem.value?.getDictonary() as? [String:Bool])?[key] {
                return value
            }
        } else {
            let orgValue = FPUtility().fetchCompataibleSpecialCharsStringFromDB(strInput: fieldItem.value ?? "")
            return option.isSelected || orgValue == option.value
        }
        return false
    }
    
    func getLabelText(option: FPFieldOption) -> String {
        return fieldItem.getUIType() == .CHECKBOX ? option.label ?? "" : option.key ?? ""
    }
}
