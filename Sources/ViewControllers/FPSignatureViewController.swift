//
//  FPSignatureViewController.swift
//  FP-Form-Detail
//
//  Created by apple on 15/04/24.
//

import UIKit
import Foundation
internal import PPSSignatureView
@objc protocol FPSignatureDelegate {
    func getSignatureImage(_ image: UIImage?)
}


@objc class FPSignatureViewController: UIViewController{
    
    @IBOutlet private weak var signatureImageBackgroundView: PPSSignatureView!
    @IBOutlet weak var savedSignatureImageView: UIImageView!
    @IBOutlet weak var outerSignatureView: UIView!
    @IBOutlet weak var signHightConst: NSLayoutConstraint!

    @objc var del: FPSignatureDelegate?
    @objc var signature: FPMedia?
    @IBOutlet weak var signWidhConst: NSLayoutConstraint!
    
    private var clearButton: UIBarButtonItem?
    private var saveButton: UIBarButtonItem?
    

    var screenHeight: CGFloat {
        return UIScreen.main.bounds.height
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        clearButton = UIBarButtonItem(title: FPLocalizationHelper.localize("lbl_Clear"), style: .plain, target: self, action: #selector(self.clearSignatureView(_:)))
        saveButton = UIBarButtonItem(title: FPLocalizationHelper.localize("SAVE"), style: .plain, target: self, action: #selector(self.saveSignature(_:)))
        navigationItem.rightBarButtonItems = [saveButton, clearButton] as? [UIBarButtonItem]
        outerSignatureView.layer.borderWidth = 1.0
        outerSignatureView.layer.borderColor = UIColor(red: 64 / 255.0, green: 164 / 255.0, blue: 28 / 255.0, alpha: 1.0).cgColor
        navigationItem.title = FPLocalizationHelper.localize("lbl_Signature")
        if UIDevice.current.userInterfaceIdiom == .phone{
            signWidhConst.changeFPMultiplier(multiplier: 0.85)
        }
        if (signature != nil) {
            saveButton?.isEnabled = false
            savedSignatureImageView.isHidden = false
        } else {
            saveButton?.isEnabled = true
            savedSignatureImageView.isHidden = true
        }
       
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateSignViewConstraints()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        updateSignViewConstraints()
    }
    
    func updateSignViewConstraints() {
        signHightConst.constant = screenHeight * 0.4
        self.view.layoutIfNeeded()
    }
    
    @objc func saveSignature(_ sender: UIBarButtonItem?) {

        if signatureImageBackgroundView.hasSignature {
            let resizedImage = FPUtility.imageWithImage(image: signatureImageBackgroundView.signatureImage, convertToSize: CGSize(width: 730.0, height: 250.0))
            del?.getSignatureImage(resizedImage)
            navigationController?.popViewController(animated: true)
        } else {
            FPUtility.showErrorMessage(nil, withTitle: FPLocalizationHelper.localize("No_Signature"), withWarningMessage:  FPLocalizationHelper.localize("Please_Get_Signature"))
        }
    }
    
    @objc func clearSignatureView(_ sender: UIBarButtonItem?) {
        if signatureImageBackgroundView.hasSignature {
            signatureImageBackgroundView.erase()
        } else if !savedSignatureImageView.isHidden {
            saveButton?.isEnabled = true
            savedSignatureImageView.isHidden = true
        }
    }
    
    
    func serviceAgreementNotPitchedAction() {
        navigationController?.popViewController(animated: true)
    }
    
}


extension NSLayoutConstraint {

  func changeFPMultiplier(multiplier: CGFloat) -> NSLayoutConstraint {
    let newConstraint = NSLayoutConstraint(
      item: firstItem,
      attribute: firstAttribute,
      relatedBy: relation,
      toItem: secondItem,
      attribute: secondAttribute,
      multiplier: multiplier,
      constant: constant)
    newConstraint.priority = priority

      NSLayoutConstraint.deactivate([self])
      NSLayoutConstraint.activate([newConstraint])

    return newConstraint
  }

}
