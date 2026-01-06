//
//  TableAttachementView.swift
//  crm
//
//  Created by kuldeep on 11/05/23.
//  Copyright © 2023 SmartServ. All rights reserved.
//

import UIKit
internal import TagListView
internal import SSMediaManager
import MobileCoreServices
import QuickLook
import UniformTypeIdentifiers
import Photos
import PhotosUI

protocol AttachmentPickerDelegate{
    func onMediaSave(mediaAdded:[SSMedia],mediaDeleted:[SSMedia])
}

class TableAttachementView: UIView, UINavigationControllerDelegate {
    @IBOutlet weak var tagListView: TagListView!
    @IBOutlet var contentView: UIView!
    var delegate:AttachmentPickerDelegate?
    var attachmentValue:String?
    private var mediaAdded:[SSMedia] = []
    private var mediaDeleted:[SSMedia] = []
    var parentViewController:UIViewController?;
    static let instance = TableAttachementView()
    var previewMedia:SSMedia?
    
    fileprivate let fileManager = FileManager.default
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
        
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    
    private func commonInit(){
        let bundle = ZenFormsBundle.bundle
        bundle.loadNibNamed("TableAttachementView", owner: self, options:nil)
        addSubview(contentView)
        
        self.contentView.layer.cornerRadius = 10
        
        contentView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        tagListView.delegate = self
    }
    
    func showAttachmentPicker() {
        tagListView.removeAllTags()
        mediaAdded = []
        mediaDeleted = []
        contentView.frame = parentViewController?.view.frame ?? contentView.frame
        parentViewController?.view.addSubview(contentView)
        if let data = self.attachmentValue?.getDictonary(),!data.isEmpty{
            if let files = data["files"] as? [[String:Any]]{
                files.forEach { file in
                    let media = SSMedia(name: file["altText"] as? String ?? "",id: file["id"] as? String ?? "",mimeType: file["type"] as? String ?? "", serverUrl: file["file"] as? String ?? "", moduleType: .forms)
                    mediaAdded.append(media)
                    tagListView.addTag(media.name)
                }
            }
            
            if let files = data["filesToUpload"] as? [[String:Any]]{
                files.forEach { file in
                    let media = SSMedia(name: file["altText"] as? String ?? "",mimeType: file["type"] as? String ?? "", filePath: file["localPath"] as? String ?? "", moduleType: .forms)
                    mediaAdded.append(media)
                    tagListView.addTag(media.name)
                }
            }
            
        }
    }
    
    @IBAction func didTapCancel(_ sender: Any) {
        contentView.removeFromSuperview()
        
    }
    @IBAction func didTapSave(_ sender: Any) {
        contentView.removeFromSuperview()
        delegate?.onMediaSave(mediaAdded: mediaAdded, mediaDeleted: mediaDeleted)
        
    }
    @IBAction func attachTap(_ sender: UIButton) {
        addAttachmentTouched(sender: sender)
    }
    
    
    //MARK: Attachments Helper
    func addAttachmentTouched(sender:UIButton) {
        let actionOptions = UIAlertController(title: FPLocalizationHelper.localize("lbl_attachment"), message: nil, preferredStyle: .actionSheet)
        let libraryAction = UIAlertAction(title:FPLocalizationHelper.localize("lbl_Library"), style: .default) { action in
            self.checkPermissionAndShowPhotoLibrary()
        }
        
        let cameraAction = UIAlertAction(title: FPLocalizationHelper.localize("lbl_Camera"), style: .default) { action in
            if !UIImagePickerController.isSourceTypeAvailable(.camera) {
                FPUtility.showErrorMessage(nil, withTitle: "", withWarningMessage: FPLocalizationHelper.localize("No_Camera"))
            } else {
                self.checkPermissionAndShowCamera()
            }
        }
        
        let documentAction = UIAlertAction(title: FPLocalizationHelper.localize("lbl_Document"), style: .default) { action in
            self.showDocumentPicker()
        }
        
        let sketchAction = UIAlertAction(title: FPLocalizationHelper.localize("lbl_Sketch"), style: .default) { action in
            let viewController =  FPDrawViewController(nibName: "FPDrawViewController", bundle: ZenFormsBundle.bundle)
            viewController.delegate = self
            self.parentViewController?.navigationController?.pushViewController(viewController, animated: true)
        }
        
        let cancelAction = UIAlertAction(title: FPLocalizationHelper.localize("Cancel"), style: .cancel, handler: nil)
        
        actionOptions.addAction(libraryAction)
        actionOptions.addAction(cameraAction)
        actionOptions.addAction(documentAction)
        actionOptions.addAction(sketchAction)
        actionOptions.addAction(cancelAction)
        
        actionOptions.popoverPresentationController?.sourceView = sender ;
        self.parentViewController?.navigationController?.present(actionOptions, animated: true, completion: nil)
    }
    
    func checkPermissionAndShowCamera() {
        let status:AVAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        if status == .authorized {
            OperationQueue.main.addOperation {
                self.showImagePickerForSourceType(sourceType: .camera)
            }
        } else if status == .denied {
            OperationQueue.main.addOperation {
                let alert = FPUtility.createAlertController(title: FPLocalizationHelper.localize("lbl_Permission_Denied"), andMessage: FPLocalizationHelper.localize("msg_cameraPermissionDenied"), withPositiveAction:FPLocalizationHelper.localize("lbl_Go_to_Settings"), andHandler:{ _ in
                    guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                        return
                    }
                    if UIApplication.shared.canOpenURL(settingsUrl) {
                        UIApplication.shared.open(settingsUrl, completionHandler: { (success) in  })
                    }
                }, withNegativeAction:FPLocalizationHelper.localize("Cancel"), andHandler:nil)
                FPUtility.topViewController()?.present(alert, animated: true)
            }
            
        } else if status == .notDetermined {
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    OperationQueue.main.addOperation {
                        self.showImagePickerForSourceType(sourceType: .camera)
                    }
                }
            }
        }
    }
    
    //check permissions for photo access
    func checkPermissionAndShowPhotoLibrary() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        if status == .authorized {
            DispatchQueue.main.async {
                self.showPHImagePickerController()
            }
        } else if status == .limited {
            DispatchQueue.main.async {
                self.enbaleFullAccessPermission()
            }
        } else if status == .denied {
            OperationQueue.main.addOperation {
                let alert = FPUtility.createAlertController(title: FPLocalizationHelper.localize("lbl_Permission_Denied"), andMessage: FPLocalizationHelper.localize("msg_galleryPermissionDenied"), withPositiveAction:FPLocalizationHelper.localize("lbl_Go_to_Settings"), andHandler:{ _ in
                    guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                        return
                    }
                    if UIApplication.shared.canOpenURL(settingsUrl) {
                        UIApplication.shared.open(settingsUrl, completionHandler: { (success) in  })
                    }
                    
                }, withNegativeAction:FPLocalizationHelper.localize("Cancel"), andHandler:nil)
                FPUtility.topViewController()?.present(alert, animated: true)
            }
            
        } else if status == .notDetermined {
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                if status == .authorized {
                    OperationQueue.main.addOperation {
                        self.showPHImagePickerController()
                    }
                }else if status == .limited {
                    DispatchQueue.main.async {
                        self.enbaleFullAccessPermission()
                    }
                }
            }
        }
    }
    
    func enbaleFullAccessPermission() {
        let alert = FPUtility.createAlertController(title: FPLocalizationHelper.localize("lbl_Permission_limited"), andMessage: FPLocalizationHelper.localize("msg_fullGalleryPermissionDenied"), withPositiveAction:FPLocalizationHelper.localize("lbl_Go_to_Settings"), andHandler:{ _ in
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                return
            }
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl, completionHandler: { (success) in  })
            }
        }, withNegativeAction:FPLocalizationHelper.localize("Cancel"), andHandler:nil)
        FPUtility.topViewController()?.present(alert, animated: true)
    }
    
    func showImagePickerForSourceType(sourceType:UIImagePickerController.SourceType) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = false
        picker.sourceType = sourceType
        picker.mediaTypes = ["public.image", "public.movie"]
        if sourceType == .camera {
            picker.showsCameraControls = true
        }
        parentViewController?.present(picker, animated:true, completion:nil)
    }
    
    func showDocumentPicker() {
        let documentPicker = UIDocumentPickerViewController(documentTypes:FPUtility.getSupportedDocumentTypesForFileUpload(), in:.import)
        documentPicker.delegate = self
        documentPicker.modalPresentationStyle = .formSheet
        documentPicker.allowsMultipleSelection = true
        DispatchQueue.main.async {
            self.parentViewController?.present(documentPicker, animated:true, completion:nil)
        }
    }
}


extension TableAttachementView:  FPDrawHelper{
    func imageSelected(_ image: UIImage) {
        do {
            let documentDirectory = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor:nil, create:true)
            let fileURL = documentDirectory.appendingPathComponent("\(Int.random(in: 999999..<9999999)).png" )
            if let data = image.pngData() {
                try? data.write(to: fileURL)
            }
            let media  = SSMedia(name: fileURL.lastPathComponent, mimeType: fileURL.fileMimeType(), filePath: fileURL.path, templateId: nil, moduleType: .forms)
            self.mediaAdded.append(media)
            tagListView.removeAllTags()
            self.mediaAdded.forEach { media in
                tagListView.addTag(media.name)
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    
}

// MARK: - UIImagePickerControllerDelegate

extension TableAttachementView: UIImagePickerControllerDelegate{
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion:nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true) {
            let mediaType = info[UIImagePickerController.InfoKey.mediaType] as? String
            if (mediaType == "public.movie") {
                guard let mediaURL = info[UIImagePickerController.InfoKey.mediaURL] as? URL else {
                    return
                }
                if picker.sourceType == .camera {
                    UISaveVideoAtPathToSavedPhotosAlbum(mediaURL.path, nil, nil, nil)
                }
                do{
                    let mediadata = try? Data(contentsOf: mediaURL)
                    let documentDirectory = try self.fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor:nil, create:true)
                    let fileURL = documentDirectory.appendingPathComponent("\(Int.random(in: 999999..<9999999)).mov")
                    try? mediadata?.write(to: fileURL)
                    let media  = SSMedia(name: fileURL.lastPathComponent, mimeType: fileURL.fileMimeType(), filePath: fileURL.path, templateId: nil, moduleType: .forms)
                    self.mediaAdded.append(media)
                    
                }catch let error{
                    print(error)
                }
                
            }else{
                var chosenImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
                if (chosenImage == nil) {
                    chosenImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage
                }
                if picker.sourceType == .camera {
                    UIImageWriteToSavedPhotosAlbum(chosenImage!, nil, nil,nil)
                }
                if (chosenImage != nil) {
                    guard let imageData = chosenImage!.jpegData(compressionQuality: 1.0) else { return }
                    do {
                        let documentDirectory = try self.fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor:nil, create:true)
                        let fileURL = documentDirectory.appendingPathComponent("\(Int.random(in: 999999..<9999999)).jpeg" )
                        try? imageData.write(to: fileURL)
                        let media  = SSMedia(name: fileURL.lastPathComponent, mimeType: fileURL.fileMimeType(), filePath: fileURL.path, templateId: nil, moduleType: .forms)
                        self.mediaAdded.append(media)
                    } catch {
                        print(error.localizedDescription)
                    }
                }
            }
            DispatchQueue.main.async {
                self.tagListView.removeAllTags()
                self.mediaAdded.forEach { media in
                    self.tagListView.addTag(media.name)
                }
            }
        }
    }
}

// MARK: - PHPickerViewController

extension TableAttachementView: PHPickerViewControllerDelegate{
    func showPHImagePickerController() {
        var configuration = PHPickerConfiguration(photoLibrary: PHPhotoLibrary.shared())
        configuration.selectionLimit = 10
        configuration.filter = .any(of: [.images, .videos])
        
        let pickerViewController = PHPickerViewController(configuration: configuration)
        pickerViewController.modalPresentationStyle = .fullScreen
        pickerViewController.delegate = self
        parentViewController?.present(pickerViewController, animated:true, completion:nil)
    }

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true) {
            guard !results.isEmpty else {
                return
            }
            let arrIdentifiers = results.compactMap(\.assetIdentifier)
            _ = FPUtility.showHUDWithMessage(FPLocalizationHelper.localize("lbl_Adding_PhotosVideos"), detailText: "")
            let group = DispatchGroup()
            for result in results {
                group.enter()
                if result.itemProvider.hasItemConformingToTypeIdentifier(UTType.movie.identifier){
                    result.itemProvider.loadDataRepresentation(forTypeIdentifier: UTType.movie.identifier) { fileData, error in
                        if let fileData = fileData{
                            do {
                                let documentDirectory = try self.fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor:nil, create:true)
                                let fileURL = documentDirectory.appendingPathComponent("\(Int.random(in: 999999..<9999999)).mov")
                                try? fileData.write(to: fileURL)
                                let media  = SSMedia(name: fileURL.lastPathComponent, mimeType: fileURL.fileMimeType(), filePath: fileURL.path, templateId: nil, moduleType: .forms)
                                self.mediaAdded.append(media)
                            } catch let error{
                                print(error)
                            }
                        }
                        group.leave()
                    }
                }else{
                    result.itemProvider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { phImgData, error in
                        if let phImgData = phImgData, let image = UIImage(data: phImgData), let imageData = image.jpegData(compressionQuality: 1.0){
                            do {
                                let documentDirectory = try self.fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor:nil, create:true)
                                let fileURL = documentDirectory.appendingPathComponent("\(Int.random(in: 999999..<9999999)).jpeg" )
                                try? imageData.write(to: fileURL)
                                let media  = SSMedia(name: fileURL.lastPathComponent, mimeType: fileURL.fileMimeType(), filePath: fileURL.path, templateId: nil, moduleType: .forms)
                                self.mediaAdded.append(media)
                            } catch let error{
                                print(error)
                            }
                        }
                        group.leave()
                    }
                }
            }
            group.notify(queue: DispatchQueue.main) {
                FPUtility.hideHUD()
                DispatchQueue.main.async {
                    self.tagListView.removeAllTags()
                    self.mediaAdded.forEach { media in
                        self.tagListView.addTag(media.name)
                    }
                }
            }
        }
    }
}


extension  TableAttachementView: UIDocumentPickerDelegate{
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        _ = FPUtility.showHUDWithMessage(FPLocalizationHelper.localize("lbl_AddingDocuments"), detailText:"")
        var arrNames = [String]()
        for url in urls {
            let fileFullName = url.lastPathComponent.removingPercentEncoding?.replacingOccurrences(of: " ", with: "_") ?? ""
            let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
            let documentsPath = paths.first ?? ""
            let filePath = (documentsPath as NSString).appendingPathComponent("\(Int.random(in: 999999..<9999999))_" + fileFullName)
            let tempUrl = URL(fileURLWithPath: filePath)
            let UTI = FPUTI(withExtension: tempUrl.pathExtension).rawValue
            let fileExtension = FPMedia.getExtensionWith(fileName: filePath.components(separatedBy: "/").last ?? "")
            if fileExtension != "csv", !FPUtility.getSupportedDocumentTypesForFileUpload().contains(UTI) {
                arrNames.append(filePath.components(separatedBy: "/").last ?? "")
                continue
            }
            if fileManager.fileExists(atPath: tempUrl.path){
                do {
                    try fileManager.removeItem(atPath: tempUrl.path)
                }catch let error{
                    print(error)
                }
            }
            
            do {
                try fileManager.moveItem(at: url, to: tempUrl)
            } catch let error{
                print(error)
            }
            let media  = SSMedia(name: tempUrl.lastPathComponent, mimeType: tempUrl.fileMimeType(), filePath: tempUrl.path, moduleType: .forms)
            self.mediaAdded.append(media)
        }
        
        FPUtility.hideHUD()
        if arrNames.count > 0 {
            let filesMsg = FPLocalizationHelper.localizeWith(args: [arrNames.joined(separator: ", ")], key: "msg_detectedExecutablesfiles")
            _  = FPUtility.showAlertController(title: FPLocalizationHelper.localize("msg_executablesfilesNotSupported"), message:filesMsg, completion:nil)
        }
        DispatchQueue.main.async {
            self.tagListView.removeAllTags()
            self.mediaAdded.forEach { media in
                self.tagListView.addTag(media.name)
            }
        }
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    }
    
}


extension TableAttachementView:TagListViewDelegate{
    func tagPressed(_ title: String, tagView: TagView, sender: TagListView){
        guard let media  =  mediaAdded.first(where: {$0.name == title}) else{return}
        if(media.filePath == nil){
            if(FPUtility.isConnectedToNetwork()){
                getMedialLocalUrl(media: media) { localMedia in
                    DispatchQueue.main.async {
                        self.previewMedia = localMedia
                        let previewController = QLPreviewController()
                        previewController.dataSource = self
                        FPUtility.topViewController()?.present(previewController, animated: false)
                    }
                }
            }else{
                _  = FPUtility.showAlertController(title: FPLocalizationHelper.localize("error_dialog_title"), message: FPLocalizationHelper.localize("msg_can_not_view_attachment_offline"), completion: nil)
            }
        }else{
            self.previewMedia = media
            let previewController = QLPreviewController()
            previewController.dataSource = self
            FPUtility.topViewController()?.present(previewController, animated: false)
        }
    }
    
    
    fileprivate func retrunLocalFilePath(_ media: SSMedia, _ completion: (SSMedia?) -> Void) {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsPath = paths.first ?? ""
        let filePath = (documentsPath as NSString).appendingPathComponent(media.name)
        var tempMedia = media
        tempMedia.filePath = filePath
        completion(tempMedia)
    }
    
    func getMedialLocalUrl(media:SSMedia, completion: @escaping (SSMedia?) -> Void) {
        if FPUtility.isConnectedToNetwork(){
            if  FPMedia.isMediaExistInDocumentsDirectory(fileName: media.name ){
                retrunLocalFilePath(media, completion)
            }else if let serverUrl = media.serverUrl, serverUrl.isValidHttpsUrl || serverUrl.isValidHttpsUrl{
                DispatchQueue.main.async {
                    _ = FPUtility.showHUDWithMessage(FPLocalizationHelper.localize("lbl_Getting_File"), detailText: "")
                }
                let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
                let documentsPath = paths.first ?? ""
                let filePath = (documentsPath as NSString).appendingPathComponent(media.name )
                let tempUrl:NSURL = NSURL(fileURLWithPath: filePath)
                FPUtility.download(urlString:media.serverUrl ?? "", toFile: tempUrl.absoluteString ?? "") { error in
                    FPUtility.hideHUD()
                    var tempMedia = media
                    if error == nil{
                        tempMedia.filePath = filePath
                    }
                    completion(tempMedia)
                }
            }else{}
            
        }else{
            if FPMedia.isMediaExistInDocumentsDirectory(fileName: media.name ){
                retrunLocalFilePath(media, completion)
            }else{
                completion(media)
            }
        }
    }

    
    fileprivate func deleteTag(_ title: String, _ media: SSMedia) {
        tagListView.removeTag(title)
        _ = mediaAdded.removeObject(media)
        if let mediaID =  media.id, !mediaID.isEmpty{
            mediaDeleted.append(media)
        }
    }
    
    func tagRemoveButtonPressed(_ title: String, tagView: TagView, sender: TagListView){
        guard let media  =  mediaAdded.first(where: {$0.name == title}) else{return}
        if(media.filePath != nil){
            deleteTag(title, media)
        }else{
            if(FPUtility.isConnectedToNetwork()){
                return deleteTag(title, media)
            }
            _  = FPUtility.showAlertController(title: FPLocalizationHelper.localize("error_dialog_title"), message: FPLocalizationHelper.localize("msg_can_not_delete_attachment_offline"), completion: nil)
        }
    }
    
}


extension TableAttachementView: QLPreviewControllerDataSource{
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        if let path = previewMedia!.filePath{
            return  NSURL(fileURLWithPath: path)
        }else{
            return  NSURL()
        }
    }
}

class PreviewItem: NSObject, QLPreviewItem {
    var previewItemURL: URL?
}

