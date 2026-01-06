//
//  DatasetColorPickerViewController.swift
//  crm
//
//  Created by apple on 23/02/24.
//  Copyright © 2024 SmartServ. All rights reserved.
//

import UIKit
internal import ZenColorPicker

protocol DatasetColorDelegate: AnyObject {
    func datasetColorSelected(color:String, for indexPath:IndexPath)
}

class DatasetColorPickerViewController: UIViewController {

    @IBOutlet weak var viewSelectedColor: UIView!
    @IBOutlet weak var viewColorPicker: ColorPickerView!
    
    weak var objcVc:FPChartViewController?
    var fieldItem:FPFieldDetails?
    var delegate:DatasetColorDelegate?
    var selectedColor:String?
    var indexPath:IndexPath!
    
    var arrChartColors:[String]{
        if let dictChartConts = UserDefaults.dictConstants?["CHART_CONSTANTS"] as? [String:Any]{
            return dictChartConts["lineColors"] as? [String] ?? []
        }else{
            FPFormsServiceManager.getZenFormConstants()
            return []
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpView()
    }


    func setUpView(){
        viewColorPicker.delegate = self
        viewColorPicker.layoutDelegate = self
        viewColorPicker.style = .circle
        viewColorPicker.selectionStyle = .check
        viewColorPicker.isSelectedColorTappable = false
        setUpAvailableColors()
        setBarButtons()
    }
    
    func setUpAvailableColors(){
        var takenColors:[String] = []
        if let dictValue = fieldItem?.value?.getDictonary(), !dictValue.isEmpty, let arrDatasets = dictValue["datasets"] as? [[String:Any]]{
            takenColors = arrDatasets.map { $0["borderColor"] as? String ?? "#000000"}
        }
        var availableColors = arrChartColors.filter { !takenColors.contains($0) }
        if let selectedColor = selectedColor{
            availableColors.insert(selectedColor, at: 0)
        }
        viewColorPicker.colors = availableColors.map{FPUtility.colorwithHexString($0)}
        if let selectedColor = selectedColor{
            viewColorPicker.preselectedIndex = availableColors.firstIndex(where: { $0  == selectedColor })
        }else{
            selectedColor = availableColors.first
            viewColorPicker.preselectedIndex = availableColors.indices.first
        }
        if let selectedColor = selectedColor{
            viewSelectedColor.backgroundColor = FPUtility.colorwithHexString(selectedColor)
        }
    }
    
    //MARK: Nav
    func setBarButtons(){
        let cancelBarButton = UIBarButtonItem(title: FPLocalizationHelper.localize("Cancel"), style: .plain, target: self, action: #selector(DatasetColorPickerViewController.cancelBtnAction))
        let doneButton = UIBarButtonItem(title: FPLocalizationHelper.localize("Done"), style:.plain, target: self, action: #selector(DatasetColorPickerViewController.doneBtnAction))
        self.navigationItem.leftBarButtonItem = cancelBarButton
        self.navigationItem.rightBarButtonItem = doneButton
        self.navigationItem.title = FPLocalizationHelper.localize("SELECT")
    }
    
    @objc func cancelBtnAction(){
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func doneBtnAction(){
        if let selectedColor = selectedColor{
            delegate?.datasetColorSelected(color: selectedColor, for: indexPath)
            self.dismiss(animated: true, completion: nil)
        }else{
            _  = FPUtility.showAlertController(title: FPLocalizationHelper.localize("error_dialog_title"), message: FPLocalizationHelper.localize("msg_chart_select_dataset_color"), completion: nil)
        }
    }

}

extension DatasetColorPickerViewController: ColorPickerViewDelegate, ColorPickerViewDelegateFlowLayout{
    
    // MARK: - ColorPickerViewDelegate
    
    func colorPickerView(_ colorPickerView: ColorPickerView, didSelectItemAt indexPath: IndexPath) {
        if let color  = colorPickerView.colors[safe:indexPath.item]{
            self.selectedColor = color.toHex()
            self.viewSelectedColor.backgroundColor = color
        }
    }
    
    // MARK: - ColorPickerViewDelegateFlowLayout
    
    func colorPickerView(_ colorPickerView: ColorPickerView, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 48, height: 48)
    }
    
    func colorPickerView(_ colorPickerView: ColorPickerView, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 12
    }
    
    func colorPickerView(_ colorPickerView: ColorPickerView, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 8
    }
    
    func colorPickerView(_ colorPickerView: ColorPickerView, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
    }
    
}

extension UIColor {

    func toHex() -> String {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        guard self.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            assertionFailure("Failed to get RGBA components from UIColor")
            return "#000000"
        }

        // Clamp components to [0.0, 1.0]
        red = max(0, min(1, red))
        green = max(0, min(1, green))
        blue = max(0, min(1, blue))
        alpha = max(0, min(1, alpha))

        if alpha == 1 {
            // RGB
            return String(
                format: "#%02lX%02lX%02lX",
                Int(round(red * 255)),
                Int(round(green * 255)),
                Int(round(blue * 255))
            )
        } else {
            // RGBA
            return String(
                format: "#%02lX%02lX%02lX%02lX",
                Int(round(red * 255)),
                Int(round(green * 255)),
                Int(round(blue * 255)),
                Int(round(alpha * 255))
            )
        }
    }

}
