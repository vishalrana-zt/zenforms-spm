//
//  ZTDateTextFieldView.swift
//  crm
//
//  Created by apple on 20/11/25.
//  Copyright © 2025 SmartServ. All rights reserved.
//
import SwiftUI


struct ZTDateTextFieldView: UIViewRepresentable {
    @Binding var date: Date?
    var datePickerMode: UIDatePicker.Mode?
    let placeholder: String
    let displayFormat: String
    var minDate: Date?
    var maxDate: Date?

    var showClearButton:Bool = false
    let onDateSelected: (Date?) -> Void
    
    // ───────────────── UIViewRepresentable
    func makeUIView(context: Context) -> UITextField {
        let tf = UITextField()
        tf.font = .systemFont(ofSize: 14)
        tf.textAlignment = .left
        tf.placeholder = placeholder
        tf.adjustsFontSizeToFitWidth = true
        tf.minimumFontSize = 6
        if showClearButton{
            tf.clearButtonMode = .whileEditing
        }
        let displayF = DateFormatter()
        displayF.dateFormat = displayFormat
        displayF.locale = .init(identifier: "en_US_POSIX")
        
        tf.delegate = context.coordinator
        context.coordinator.textField = tf
        
        // UIDatePicker as inputView
        let picker = UIDatePicker()
        picker.datePickerMode = datePickerMode ?? .date
        picker.minimumDate = minDate
        picker.maximumDate = maxDate
        if let date = date{
            picker.date = date
            tf.text = displayF.string(from: date)
        }
        picker.preferredDatePickerStyle = .wheels
        tf.inputView = picker
        
        let bar = UIToolbar();  bar.sizeToFit()
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace,
                                   target: nil, action: nil)
        let done = UIBarButtonItem(title: FPLocalizationHelper.localize("Done"), style: .done,
                                   target: context.coordinator,
                                   action: #selector(Coordinator.doneTapped))
        bar.items = [flex, done]
        tf.inputAccessoryView = bar
        
        return tf
    }
    
    func updateUIView(_ uiView: UITextField, context: Context) {
        let displayF = DateFormatter()
        displayF.dateFormat = displayFormat
        displayF.locale = .init(identifier: "en_US_POSIX")
        if let date = date{
            uiView.text = displayF.string(from: date)
        }
    }
    
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    
    // ───────────────── Coordinator
    final class Coordinator: NSObject, UITextFieldDelegate {
        let parent: ZTDateTextFieldView
        weak var textField: UITextField?
        
        init(_ parent: ZTDateTextFieldView) { self.parent = parent }
        
        // Done button
        @objc func doneTapped() {
            guard let tf = textField,
                  let picker = tf.inputView as? UIDatePicker else { return }            
            if tf.text?.isEmpty == false {
                parent.date = picker.date
                parent.onDateSelected(picker.date)
            }else{
                parent.date = nil
                parent.onDateSelected(nil)
            }
            tf.resignFirstResponder()
        }
        
        // ‼️ NEW: ensure picker shows the value that is inside the text-field
        func textFieldDidBeginEditing(_ textField: UITextField) {
            self.textField = textField
            if let picker = textField.inputView as? UIDatePicker{
                if let date = parent.date {
                    picker.setDate(date, animated: false)
                }
                let displayF = DateFormatter()
                displayF.dateFormat = parent.displayFormat
                displayF.locale = .init(identifier: "en_US_POSIX")
                textField.text = displayF.string(from: picker.date)
                parent.onDateSelected(picker.date)
            }
        }
        
        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
            return false
        }
        
        func textFieldShouldClear(_ textField: UITextField) -> Bool {
            parent.date = nil
            parent.onDateSelected(nil)
            return true
        }
    }
}
