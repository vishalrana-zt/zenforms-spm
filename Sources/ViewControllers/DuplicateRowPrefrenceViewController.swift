//
//  DuplicateRowPrefrenceViewController.swift
//  crm
//
//  Created by apple on 26/03/25.
//  Copyright © 2025 SmartServ. All rights reserved.
//
import UIKit

class DuplicateRowPrefrenceViewController: UIViewController {

    @IBOutlet weak var dropDownPreference: ZTDropDown!
    
    var arrDropdowns:[String] = [FPLocalizationHelper.localize("lbl_After_Original_Row"), FPLocalizationHelper.localize("lbl_End_Table")]
    var selectedIndex = 0
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setupDropdownField()
        setBarButtons()
    }
    
    //MARK: SetUp

    
    func setupDropdownField(){
        if let preference = UserDefaults.standard.object(forKey: "DuplicateRowPreference") as? String {
            selectedIndex = preference == "lbl_End_Table" ? 1 : 0
        }else{
            UserDefaults.standard.set("lbl_After_Original_Row", forKey: "DuplicateRowPreference")
            UserDefaults.standard.synchronize()
        }
        self.dropDownPreference.text = arrDropdowns[safe: selectedIndex] ?? FPLocalizationHelper.localize("lbl_After_Original_Row")
        self.dropDownPreference.selectedIndex =  selectedIndex
        self.dropDownPreference.optionArray = arrDropdowns
        self.dropDownPreference.checkMarkEnabled = false
        self.dropDownPreference.isSearchEnable = false
        self.dropDownPreference.itemsColor = .black
        self.dropDownPreference.rowHeight = 60
        self.dropDownPreference.selectedRowColor = #colorLiteral(red: 0.9411764706, green: 0.937254902, blue: 0.9647058824, alpha: 1)
        dropDownPreference.arrowSize = 16
        self.dropDownPreference.didSelect{(selectedText , index ,id) in
            self.selectedIndex = index
            self.dropDownPreference.hideList()
        }
        self.dropDownPreference.didEndSelect{(selectedText) in
            DispatchQueue.main.async {
             self.dropDownPreference.hideList()
            }
        }
    }
    
    //MARK: Nav
    
    func setBarButtons(){
        let cancelBarButton = UIBarButtonItem(title: FPLocalizationHelper.localize("Cancel"), style: .plain, target: self, action: #selector(DuplicateRowPrefrenceViewController.cancelBtnAction))
        let doneButton = UIBarButtonItem(title: FPLocalizationHelper.localize("Done"), style:.plain, target: self, action: #selector(DuplicateRowPrefrenceViewController.doneBtnAction))
        self.navigationItem.leftBarButtonItem = cancelBarButton
        self.navigationItem.rightBarButtonItem = doneButton
    }

    @objc func cancelBtnAction(){
        self.view.endEditing(true)
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func doneBtnAction(){
        self.view.endEditing(true)
        let preference = self.selectedIndex == 1 ? "lbl_End_Table"  : "lbl_After_Original_Row"
        UserDefaults.standard.set(preference, forKey: "DuplicateRowPreference")
        UserDefaults.standard.synchronize()
        self.dismiss(animated: true, completion: nil)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
