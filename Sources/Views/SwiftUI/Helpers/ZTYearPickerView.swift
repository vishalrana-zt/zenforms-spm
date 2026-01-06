//
//  MonthYearPickerView.swift
//  crm
//
//  Created by apple on 20/11/25.
//  Copyright © 2025 SmartServ. All rights reserved.
//
import SwiftUI

struct ZTYearPickerView: View {
    let yearValue: String
    @State var selectedDate: Date?
    @State var strDisplayedDate: String?
    let minimumDate: Date
    let maximumDate: Date
    let placeholder: String
    var onDateSelected: ((Date?)-> Void)?

    private var availableYears: [Int] {
        let minYear = Calendar.current.component(.year, from: minimumDate)
        let maxYear = Calendar.current.component(.year, from: maximumDate)
        return Array(minYear...maxYear)
    }
    
    var body: some View {
        ZStack{
            HStack(spacing: 4.0) {
                SwiftUI.Text(strDisplayedDate ?? placeholder)
                    .padding(.horizontal, 8)
                    .font(.system(size: 14))
                    .foregroundStyle(strDisplayedDate == nil ? Color(.systemGray4) : Color("ZT-Black"))
                    .frame(height: 50)
                Spacer()
                Circle()
                    .frame(width: 40)
                    .opacity(0.0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            HStack(spacing: 0){
                Menu {
                    ForEach(availableYears, id: \ .self) { year in
                        let date = DateComponents(calendar: Calendar(identifier: .gregorian), year: year, month: 1, day: 1, hour: 0, minute: 0, second: 0).date
                        Button {
                            selectedDate = date
                            refreshSelection()
                            onDateSelected?(selectedDate)
                        } label: {
                            if selectedDate == date {
                                Label(String(year), systemImage: "checkmark")
                            } else {
                                SwiftUI.Text(String(year))
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color("ZT-Black"))
                            }
                        }
                    }
                } label: {
                    Spacer()
                    Circle()
                        .frame(width: 40)
                        .opacity(0.0)
                }
                if selectedDate != nil {
                    Button(action: {
                        selectedDate = nil
                        refreshSelection()
                        onDateSelected?(selectedDate)
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(Color(.systemGray4))
                            .padding()
                    }
                    .frame(width: 40, height: 40)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
        }
        .onAppear {
            setSelection()
        }
    }
    
    //MARK: Helper Methods

    
    func setSelection(){
        if let date = FPUtility.getOPDateFrom(yearValue) {
            selectedDate = date
        }else if let fixedDate = fixDateFormat(yearValue) {
            selectedDate = fixedDate
        }else{}
        refreshSelection()
    }
    
    func refreshSelection(){
        strDisplayedDate = fetchDisplayedDate()
    }
    
    func fetchDisplayedDate() -> String?{
        let displayF = DateFormatter()
        displayF.dateFormat = FPFORM_DATE_FORMAT.YEAR.rawValue
        displayF.locale = .init(identifier: "en_US_POSIX")
        if let selectedDate{
            return displayF.string(from: selectedDate)
        }
        return nil
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
    
}

