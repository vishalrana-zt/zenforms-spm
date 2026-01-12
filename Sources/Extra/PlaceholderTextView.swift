
//
//  PlaceholderTextView.swift
//  ZT-copilot
//
//  Created by Harshit on 04/02/25.
//
import UIKit


class PlaceholderTextView: UITextView {
    
    // Placeholder properties
    var placeholder: String = "" {
        didSet {
            placeholderLabel.text = placeholder
        }
    }
    
    var placeholderColor: UIColor = .lightGray {
        didSet {
            placeholderLabel.textColor = placeholderColor
        }
    }
    
    // Private label to display the placeholder
    public lazy var placeholderLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = self.font
        label.textColor = placeholderColor
        label.backgroundColor = .clear
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // Initializers
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        setupPlaceholder()
        setupToolbar()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupPlaceholder()
        setupToolbar()
    }
    
    // Setup the placeholder label and observers
    private func setupPlaceholder() {
        addSubview(placeholderLabel)
        
        // Constraints for placeholder label to align it with text view's text
        NSLayoutConstraint.activate([
            placeholderLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 5),
            placeholderLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -5),
            placeholderLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 8)
        ])
        
        // Observe text changes to show/hide placeholder
        NotificationCenter.default.addObserver(self, selector: #selector(textDidChange), name: UITextView.textDidChangeNotification, object: self)
        
        textDidChange()
    }
    
    private func setupToolbar() {
        // Toolbar with Done and Cancel buttons
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        
        let cancelButton = UIBarButtonItem(title: FPLocalizationHelper.localize("Cancel"), style: .plain, target: self, action: #selector(cancelButtonTapped))
        let doneButton = UIBarButtonItem(title: FPLocalizationHelper.localize("Done"), style: .done, target: self, action: #selector(doneButtonTapped))
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        toolbar.items = [cancelButton, flexibleSpace, doneButton]
        
        // Set the toolbar as the input accessory view for the text view
        self.inputAccessoryView = toolbar
    }
    
    @objc private func cancelButtonTapped() {
        self.resignFirstResponder()
    }
    
    @objc private func doneButtonTapped() {
        self.resignFirstResponder()
    }
    
    // Update placeholder visibility
    @objc private func textDidChange() {
        placeholderLabel.isHidden = !text.isEmpty
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
