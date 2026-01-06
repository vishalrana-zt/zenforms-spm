//
//  TableContentCollectionCell 2.swift
//  crm
//
//  Created by apple on 20/11/25.
//  Copyright © 2025 SmartServ. All rights reserved.
//


import SwiftUI
internal import SSMediaManager


struct TableContentCollectionCell: View {
    
    @State var data: ColumnData?
    
    var parentTableIndex:IndexPath?
    var childTableIndex:IndexPath?
    
    @State var tblFieldValue: String
    @State var fieldSelectedDate: Date?
    
    @State var btnAttachmentTitle: String?
    var onAttachementClicked: ((_ index:IndexPath?, _ data:ColumnData?)-> Void)?

    var showBarcodeButton:Bool = false
    var onBarcodeClicked: (()-> Void)?

    var isCheckBoxHidden:Bool = false
    @State var isCheckBoxSelcted:Bool = false
    var onCheckBoxClicked: (Bool) -> Void
    
    var onTblFieldValueChanged: ((_ index: IndexPath?, _ data: ColumnData?, _ filedData: FPFieldDetails?)-> Void)?
    
    @FocusState private var isInputFocused: Bool

    private var defaultDeficeincyOptions:[DropdownOptions]{
        let yesOption = DropdownOptions(key:FPStringBoolIntValue.string(FPLocalizationHelper.localize("Yes")) , value: FPStringBoolIntValue.string(FPLocalizationHelper.localize("Yes")), label: FPStringBoolIntValue.string(FPLocalizationHelper.localize("Yes")))
        let noOption = DropdownOptions(key:FPStringBoolIntValue.string(FPLocalizationHelper.localize("No")) , value: FPStringBoolIntValue.string(FPLocalizationHelper.localize("No")), label: FPStringBoolIntValue.string(FPLocalizationHelper.localize("No")))
        let naOption = DropdownOptions(key:FPStringBoolIntValue.string("NA") , value: FPStringBoolIntValue.string("NA"), label: FPStringBoolIntValue.string("NA"))
        return [yesOption, noOption, naOption]
    }
    
    var strFPDateFormat: String {
        var strFormat = ""
        var dateFormatType: FPFORM_DATE_FORMAT = .DATE
        if let columnData  = data{
            if columnData.dataType == "TIME"{
                dateFormatType = .TIME
            }else if columnData.dataType == "DATE_TIME"{
                dateFormatType = .DATE_TIME
            }else if columnData.dataType == "YEAR"{
                dateFormatType = .YEAR
            }else{
                dateFormatType = .DATE
            }
        }
        if dateFormatType == .DATE_TIME, let dateFormat = data?.dateFormat{
            strFormat = dateFormat
        }else{
            strFormat = dateFormatType.rawValue
        }
        strFormat = dateFormatType.rawValue
        return strFormat
    }
  
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if showBarcodeButton{
                Button(action: {
                    onBarcodeClicked?()
                }) {
                    Image("icn_asset_link")
                        .font(.headline)
                        .foregroundStyle(Color("BT-Primary"))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
            
            if !isCheckBoxHidden, showActionButton(){
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
            
            if showDropDownDeficiencyView(){
                ZTDropdownView(
                    selectedItem: tblFieldValue,
                    placeholder: "",
                    items: fetchTblFieldDisplayOptions(),
                    isSearchable: data?.uiType == "DROPDOWN",
                    isBorderNeeded: false) { selectedText in
                        if var columnData = self.data{
                            let dbValue = selectedText.handleAndDisplayApostrophe()
                            columnData.value = dbValue
                            onTblFieldValueChanged?(self.childTableIndex, columnData, nil)
                        }
                    }
            }
            
            if showAttachementOptions(){
                Button(action: {
                    onAttachementClicked?(childTableIndex, data)
                }) {
                    SwiftUI.Text(btnAttachmentTitle ?? FPLocalizationHelper.localize("lbl_Add"))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color("BT-Primary"))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
                        
            if showDateInputView(){
                if data?.dataType == "YEAR"{
                    yearPickerInputView
                }else{
                    datePickerInputView
                }
            }
            
            if data?.dataType == "NUMBER" || data?.dataType == "TEXT"{
                textAreaInputView
            }
        }
        .background(.white)
        .border(Color(uiColor: UIColor.darkGray), width: 0.5)
        .onAppear {
            setItemValue()
        }

    }
    
    private var textAreaInputView: some View {
        TextEditor(text: $tblFieldValue)
            .font(.system(size: 14, weight: .regular))
            .focused($isInputFocused)
            .autocorrectionDisabled(true)
            .padding(8)
            .keyboardType(data?.dataType == "NUMBER" ? .numbersAndPunctuation : .default)
            .onChange(of: isInputFocused) { isFocused in
                if !isFocused {
                    self.saveText(text: tblFieldValue)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
    
    private var datePickerInputView: some View{
        ZTDateTextFieldView(
            date: $fieldSelectedDate,
            datePickerMode: datePickerMode(),
            placeholder: "",
            displayFormat: strFPDateFormat,
            minDate: nil,
            maxDate: nil,
            showClearButton: true) { date in
                saveDateInput(date: date)
            }
            .padding(8)
    }
    
    private var yearPickerInputView: some View{
        ZTYearPickerView(
            yearValue: data?.value ?? "",
            selectedDate: fieldSelectedDate,
            minimumDate: Calendar.current.date(byAdding: .year, value: -10, to: Date()) ?? Date(),
            maximumDate: Calendar.current.date(byAdding: .year, value: 10, to: Date()) ?? Date(),
            placeholder: "") { date in
                saveDateInput(date: date)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .padding(8)
    }
    
    //MARK: Helper Methods
    
    func showActionButton() -> Bool{
        return data?.key == "action-checkbox" && data?.uiType == "CHECKBOX"
    }
    
    func showDropDownDeficiencyView() -> Bool{
        return data?.uiType == "DEFICIENCY" || data?.uiType == "DROPDOWN"
    }
    
    func showAttachementOptions() -> Bool{
        return data?.uiType == "ATTACHMENT"
    }

    func showDateInputView() -> Bool{
        return  data?.dataType == "DATE" ||
        data?.dataType == "TIME" ||
        data?.dataType == "DATE_TIME" ||
        data?.dataType == "YEAR"
    }
    
    func setItemValue(){
        if let dataValue = data?.value, !dataValue.trim.isEmpty{
            if data?.dataType == "DATE" || data?.dataType == "TIME" || data?.dataType == "DATE_TIME" || data?.dataType == "YEAR"{
                if let date = FPUtility.getOPDateFrom(dataValue) {
                    fieldSelectedDate = date
                    tblFieldValue = self.formateDateAccordingToMode(date: date)
                }else if let fixedDate = fixDateFormat(dataValue) {
                    fieldSelectedDate = fixedDate
                    tblFieldValue = self.formateDateAccordingToMode(date: fixedDate)
                }else{}
            }else{
                tblFieldValue = FPUtility().getSQLiteSpecialCharsCompatibleString(value: dataValue, isForLocal: false) ?? dataValue
                if showDropDownDeficiencyView(){
                    if data?.uiType == "DEFICIENCY", data?.dropDownOptions != nil{
                        let compareValue = FPUtility().getSQLiteSpecialCharsCompatibleString(value: data?.value, isForLocal: false) ?? dataValue
                        let arrOptions = fetchTblFieldDropDownOptions()
                        if let index = arrOptions.firstIndex(where: { $0.value.stringValue().handleAndDisplayApostrophe().lowercased() == compareValue.lowercased() }){
                            tblFieldValue = arrOptions[safe:index]?.label.stringValue().handleAndDisplayApostrophe() ?? dataValue
                        }
                    }else{
                        let arrOptions = fetchTblFieldDisplayOptions()
                        let compareValue = FPUtility().getSQLiteSpecialCharsCompatibleString(value: dataValue, isForLocal: false) ?? dataValue
                        if let index = arrOptions.firstIndex(where: { $0.lowercased() == compareValue.lowercased() }){
                            tblFieldValue = arrOptions[safe:index] ?? dataValue
                        }
                    }
                }
            }
        }
        if showAttachementOptions(){
            setAttachementsForTable()
        }
    }

    
    func formateDateAccordingToMode(date:Date) -> String {
        return date.convertUTCToLocalInString(with: strFPDateFormat)
    }
    
    func fixDateFormat(_ dateString: String, format:String = "yyyy-MM-dd'T'HH:mm:ss.SSSZ") -> Date? {
        let fixedDateString = dateString.replacingOccurrences(of: "__X2E__", with: ".")
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        
        if let fixedDate = dateFormatter.date(from: fixedDateString) {
            return fixedDate
        } else {
            return nil
        }
    }
    
    
    func setAttachementsForTable(){
        let dataObject = data?.value.getDictonary() ?? [:]
        if(!dataObject.isEmpty){
            if let files =  dataObject["files"] as? [[String:Any]],!files.isEmpty{
                btnAttachmentTitle = FPLocalizationHelper.localize("lbl_View")
            }else{
                if let files =  dataObject["filesToUpload"] as? [[String:Any]],!files.isEmpty{
                    var mediasAdded:[SSMedia] = []
                    files.forEach { file in
                        if((FPFormDataHolder.shared.tableMediaCache.first(where: {$0.mediaAdded.contains(where: {$0.name == file["altText"] as? String ?? "" })})) == nil){
                            
                            let mediaAdded = SSMedia(name:file["altText"] as? String ?? "",mimeType:file["type"] as? String ?? "",filePath: file["localPath"] as? String ?? "", moduleType: .forms)
                            mediasAdded.append(mediaAdded)
                        }
                    }
                    if mediasAdded.count>0{
                        if let mediaIndex = FPFormDataHolder.shared.tableMediaCache.firstIndex(where: {$0.parentTableIndex == parentTableIndex && $0.childTableIndex == childTableIndex}){
                            var tableMedia = FPFormDataHolder.shared.tableMediaCache[mediaIndex]
                            tableMedia.mediaAdded = mediasAdded
                            FPFormDataHolder.shared.addUpdateTableMediaCache(media: tableMedia)
                            
                        }else{
                            let tableMedia = TableMedia(columnIndex:childTableIndex!.row-2,key:data?.key,parentTableIndex: parentTableIndex,childTableIndex: childTableIndex, mediaAdded: mediasAdded, mediaDeleted: [])
                            FPFormDataHolder.shared.addUpdateTableMediaCache(media: tableMedia)
                        }
                    }
                    
                    btnAttachmentTitle = FPLocalizationHelper.localize("lbl_View")
                }else{
                    btnAttachmentTitle = FPLocalizationHelper.localize("lbl_Add")
                }
            }
        }else{
            btnAttachmentTitle = FPLocalizationHelper.localize("lbl_Add")
        }
    }
    
    func fetchTblFieldDropDownOptions() -> [DropdownOptions]{
        var arrDrowpDownOptions: [DropdownOptions] = []
        let selOption = DropdownOptions(key:FPStringBoolIntValue.string(FPLocalizationHelper.localize("SELECT")) , value: FPStringBoolIntValue.string(FPLocalizationHelper.localize("SELECT")), label: FPStringBoolIntValue.string(FPLocalizationHelper.localize("SELECT")))
        arrDrowpDownOptions.append(selOption)
        if data?.uiType == "DEFICIENCY", data?.dropDownOptions == nil{
            arrDrowpDownOptions.append(contentsOf: defaultDeficeincyOptions)
        }else{
            arrDrowpDownOptions.append(contentsOf: data?.dropDownOptions ?? [])
        }
        return arrDrowpDownOptions
    }
    
    func fetchTblFieldDisplayOptions() -> [String]{
        let arrStrOptions = fetchTblFieldDropDownOptions().compactMap({ data?.generateDynamically ?? false || data?.uiType == "DEFICIENCY" ? $0.label.stringValue().handleAndDisplayApostrophe() : $0.key.stringValue().handleAndDisplayApostrophe()})
        return arrStrOptions
    }
    
    private func saveDateInput(date:Date?){
        if let date {
            fieldSelectedDate = date
            tblFieldValue = self.formateDateAccordingToMode(date: date)
            data?.value =  FPUtility.getStringWithTZFormat(date)
        }else{
            tblFieldValue = ""
            data?.value = ""
        }
        if tblFieldValue.trim.isEmpty {
            self.data?.value = ""
        }
        saveText(text: tblFieldValue)
    }
    
    private func saveText(text:String){
        if var columnData = data{
            var tblValue = text
            if !text.trim.isEmpty, data?.dataType == "DATE" || data?.dataType == "TIME" || data?.dataType == "DATE_TIME" || data?.dataType == "YEAR"{
                tblValue = columnData.value
            }
            let dbValue = FPUtility().getSQLiteSpecialCharsCompatibleString(value: tblValue, isForLocal: true) ?? text
            columnData.value = dbValue
            onTblFieldValueChanged?(childTableIndex, columnData, nil)
        }
    }
    
    private func datePickerMode() -> UIDatePicker.Mode{
        var datePickerMode: UIDatePicker.Mode = .date
        if data?.dataType == "TIME"{
            datePickerMode = .time
        }else if data?.dataType == "DATE_TIME"{
            datePickerMode = .dateAndTime
        }
        return datePickerMode
    }
}

