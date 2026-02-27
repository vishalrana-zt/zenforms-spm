//
//  FPEditRowTableViewCell.swift
//  ZenForms
//
//  Created by apple on 27/02/26.
//


import UIKit
internal import SSMediaManager
internal import IQKeyboardManagerSwift

// MARK: - Cell

protocol FPEditRowCellDelegate: AnyObject {
    func updateData(at index:IndexPath, with data:ColumnData, filedData filed:FPFieldDetails?)
    func showAddAttachment(at index:IndexPath,with data:ColumnData)
}


 class FPEditRowTableViewCell: UITableViewCell {

    // MARK: - IBOutlets

    @IBOutlet weak var btnAddAttachment: UIButton!
    @IBOutlet weak var tblTextField: UITextField!
    @IBOutlet weak var tblDropdownField: ZTDropDown!
    @IBOutlet weak var tblTextView: UITextView!
    @IBOutlet weak var viewBarcode: UIView!
    @IBOutlet weak var imgBarcode: UIImageView!
    @IBOutlet weak var btnBarcode: UIButton!

    // MARK: - Properties

    var indexPath: IndexPath?
    var parentIndexPath: IndexPath?

    weak var delegate: FPEditRowCellDelegate?

    var data: ColumnData? {
        didSet {
            guard let data else { return }
            configure(with: data)
        }
    }

    private var pickerArray: [DropdownOptions] = []
    private var generateDynamically = false
    private var isUITypeDeficiency = false

    // MARK: - Lifecycle

    override func awakeFromNib() {
        super.awakeFromNib()

        selectionStyle = .none

        tblTextField.delegate = self
        tblTextView.delegate = self

        tblTextField.iq.toolbar.doneBarButton
            .setTarget(self, action: #selector(doneTapped))

        tblTextView.iq.toolbar.doneBarButton
            .setTarget(self, action: #selector(doneTapped))

        imgBarcode.setImageColor(
            color: UIColor(named: "BT-Primary") ?? .black
        )
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        tblTextField.text = nil
        tblTextView.text = nil
        tblDropdownField.text = nil

        btnAddAttachment.isHidden = true
        tblTextField.isHidden = true
        tblTextView.isHidden = true
        tblDropdownField.isHidden = true
    }

    // MARK: - Actions

    @objc private func doneTapped() {
        endEditing(true)
    }

    @IBAction func didTapAddAttachments(_ sender: Any) {
        guard let indexPath, let data else { return }
        delegate?.showAddAttachment(at: indexPath, with: data)
    }
}

// MARK: - Configuration

private extension FPEditRowTableViewCell {

    func configure(with column: ColumnData) {

        resetUI()

        tblTextView.isUserInteractionEnabled = !(column.readonly ?? false)
        tblTextField.isUserInteractionEnabled = !(column.readonly ?? false)
        tblDropdownField.isUserInteractionEnabled = !(column.readonly ?? false)


        switch column.uiType {

        case "DROPDOWN", "DEFICIENCY":
            configureDropdown(column)

        case "ATTACHMENT":
            configureAttachment(column)

        default:
            configureInput(column)
        }

        assignTags()
    }

    func resetUI() {
        btnAddAttachment.isHidden = true
        tblTextField.isHidden = true
        tblTextView.isHidden = true
        tblDropdownField.isHidden = true
    }
}

// MARK: - Dropdown

private extension FPEditRowTableViewCell {

    func configureDropdown(_ column: ColumnData) {

        generateDynamically = column.generateDynamically ?? false
        isUITypeDeficiency = column.uiType == "DEFICIENCY"

        tblDropdownField.isHidden = false

        let display =
        FPUtility()
            .getSQLiteSpecialCharsCompatibleString(
                value: column.value,
                isForLocal: false
            ) ?? column.value

        tblDropdownField.text = display

        pickerArray.removeAll()

        
        let select = DropdownOptions(key:FPStringBoolIntValue.string(FPLocalizationHelper.localize("SELECT")),
                                     value: FPStringBoolIntValue.string(FPLocalizationHelper.localize("SELECT")),
                                     label: FPStringBoolIntValue.string(FPLocalizationHelper.localize("SELECT")))

        pickerArray.append(select)

        if isUITypeDeficiency,
           column.dropDownOptions == nil {
            pickerArray.append(contentsOf: defaultDeficeincyOptions)
        } else {
            pickerArray.append(contentsOf: column.dropDownOptions ?? [])
        }

        tblDropdownField.optionArray =
            pickerArray.map { $0.label.stringValue() }

        tblDropdownField.didSelect { _, index, _ in
            self.applySelection(index)
        }

        tblDropdownField.didEndSelect { text in
            guard var columnData = self.data,
                  let indexPath = self.indexPath else { return }

            columnData.value = text

            self.delegate?.updateData(
                at: indexPath,
                with: columnData,
                filedData: nil
            )
        }
    }

    func applySelection(_ index: Int) {

        guard pickerArray.indices.contains(index),
              let indexPath else { return }

        let value =
        pickerArray[index].value.stringValue()
        tblDropdownField.text = value
        saveText(value)
    }
}

// MARK: - Attachment

private extension FPEditRowTableViewCell {

    func configureAttachment(_ column: ColumnData) {

        btnAddAttachment.isHidden = false

        let dict = column.value.getDictonary()

        if let files = dict["files"] as? [[String:Any]],
           !files.isEmpty {

            btnAddAttachment.setTitle(
                FPLocalizationHelper.localize("lbl_View"),
                for: .normal
            )
        } else {
            btnAddAttachment.setTitle(
                FPLocalizationHelper.localize("lbl_Add"),
                for: .normal
            )
        }
    }
}

// MARK: - Input

private extension FPEditRowTableViewCell {

    func configureInput(_ column: ColumnData) {

        if ["DATE","TIME","DATE_TIME","YEAR"]
            .contains(column.dataType) {

            tblTextField.isHidden = false
            tblTextField.text = column.value

        } else {
            tblTextView.isHidden = false
            tblTextView.text =
                FPUtility()
                .getSQLiteSpecialCharsCompatibleString(
                    value: column.value,
                    isForLocal: false
                ) ?? column.value
        }
    }
}

// MARK: - Helpers

private extension FPEditRowTableViewCell {

    func assignTags() {
        guard let indexPath else { return }
        let tag = indexPath.row - 2
        tblTextField.tag = tag
        tblTextView.tag = tag
        btnAddAttachment.tag = tag
    }

    func saveText(_ text: String) {

        guard var columnData = data,
              let indexPath else { return }

        columnData.value = text

        delegate?.updateData(
            at: indexPath,
            with: columnData,
            filedData: nil
        )
    }

    var defaultDeficeincyOptions:[DropdownOptions]{
        let yesOption = DropdownOptions(key:FPStringBoolIntValue.string(FPLocalizationHelper.localize("Yes")) , value: FPStringBoolIntValue.string(FPLocalizationHelper.localize("Yes")), label: FPStringBoolIntValue.string(FPLocalizationHelper.localize("Yes")))
        let noOption = DropdownOptions(key:FPStringBoolIntValue.string(FPLocalizationHelper.localize("No")) , value: FPStringBoolIntValue.string(FPLocalizationHelper.localize("No")), label: FPStringBoolIntValue.string(FPLocalizationHelper.localize("No")))
        let naOption = DropdownOptions(key:FPStringBoolIntValue.string("NA") , value: FPStringBoolIntValue.string("NA"), label: FPStringBoolIntValue.string("NA"))
        return [yesOption, noOption, naOption]
    }
}

// MARK: - UITextFieldDelegate

extension FPEditRowTableViewCell: UITextFieldDelegate {

    func textFieldDidEndEditing(_ textField: UITextField) {
        saveText(textField.text ?? "")
    }
}

// MARK: - UITextViewDelegate

extension FPEditRowTableViewCell: UITextViewDelegate {

    func textViewDidEndEditing(_ textView: UITextView) {
        saveText(textView.text ?? "")
    }
}

