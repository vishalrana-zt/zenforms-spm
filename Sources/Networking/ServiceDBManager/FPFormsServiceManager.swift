//
//  FPFormsServiceManager.swift
//  crm
//
//  Created by SmartServ-Shristi on 6/29/20.
//  Copyright © 2020 SmartServ. All rights reserved.
//

import Foundation
internal import SSMediaManager

let FPFormMduleId = 33
let FPFormTemplateModuleId = 32

let commonFPFormTemplates = "fpFormTemplate"

class FPFormsServiceManager: NSObject {
    typealias completionHandler = () -> ()
    typealias successCompletionHandler = (_ success: Bool) -> ()
    typealias GetFormWithError = (_ form: FPForms?, _ _error: Error?) -> ()
    typealias GetFormsWithError = (_ forms: [FPForms], _ _error: Error?) -> ()
    typealias errorCompletionHandler = (Error?) -> ()
    typealias GetCheckListWithError = (_ checkList: [String:Any], _ _error: Error?) -> ()
    typealias GetRecomendationListWithError = (_ recomendation: [String], _ _error: Error?) -> ()
    typealias GetInspectionFormsCompletionBlock = (_ forms: [FPForms], _ total:Int, _ error: Error?) -> Void
    
    static let serialQueueUpsertFPForms = DispatchQueue(label: "com.queue.serialQueueUpsertFPForms")

    static let router = FPRouter<FPFormsApiName>()
    
    class func getComputedFields(ticketID:String){
        guard FPUtility.isConnectedToNetwork() else {
            return
        }
        var parms:[String:Any] = [:]
        parms["ticketId"] = ticketID
        router.request(.getComputedFields(parms)) { json, data, response, error in
            if let result = json?["result"] as? [String:Any]{
                if let tokens = result["tokens"] as? [String:Any]{
                    var ticketComputedFields = UserDefaults.computedFields ?? [:]
                    ticketComputedFields[ticketID] = tokens
                    UserDefaults.computedFields = ticketComputedFields
                }
                
            }
        }
    }
    
    class func getZenFormConstants(){
        guard FPUtility.isConnectedToNetwork() else {
            return
        }
        let parms:[String:Any] = [:]
        router.request(.getFPFormConstants(parms)) { json, data, response, error in
            if let result = json?["result"] as? [String:Any]{
                UserDefaults.dictConstants = result
            }
        }
    }
    
    class func preComileFPForm(form:FPForms, ticketID:String, completion: completionHandler? = nil) {
        guard FPUtility.isConnectedToNetwork(), let formId = form.objectId else {
            completion?()
            return
        }
        var parms:[String:Any] = [:]
        parms["ticketId"] = ticketID
        router.request(.preCompileFPForm(formId, params: parms)) { (json, _data, response, _error) in
            if let error = _error {
                debugPrint(error.localizedDescription)
            }
            completion?()
        }
    }
    
    class func addSignaturesToFPForm(showLoader: Bool, form:FPForms, ticketID:NSNumber, params : [String: Any], completion: @escaping errorCompletionHandler) {
        
        if showLoader {
            DispatchQueue.main.async {
                FPUtility.showHUDWithLoadingMessage()
            }
        }
        
        guard FPUtility.isConnectedToNetwork(), let formId = form.objectId else {
            if showLoader {
                FPUtility.hideHUD()
            }
            completion(nil)
            return
        }
        router.request(.addSignaturesToFPForm(formId, params: params)) { (json, _data, response, error) in
            if showLoader {
                FPUtility.hideHUD()
            }
            if error == nil{
                guard let result = json?["result"] as? [String: Any] else {
                    let tempError = FPErrorHandler.getError(code: 401, message: FPLocalizationHelper.localize("lbl_Something_went_wrong"))
                    FPUtility.printErrorAndShowAlert(error: tempError)
                    completion(error)
                    return
                }
                completion(nil)
            } else {
                FPUtility.printErrorAndShowAlert(error: error)
                completion(error)
            }
        }
    }
    
    
    class func upsertLocalData(ticketId: NSNumber, moduleId: Int, form: FPForms, completion: @escaping GetFormWithError) {
        FPFormsDatabaseManager().upsert(form: form, ticketId: ticketId, moduleId: moduleId) { nform, success in
            if success {
                completion(nform, nil)
            }else {
                let tempError = FPErrorHandler.getError(code: 401, message: FPLocalizationHelper.localize("lbl_Something_went_wrong"))
                completion(nil, tempError)
            }
        }
    }
    
    
    class func upsertServerData(ticketId: NSNumber, moduleId: Int, localForm: FPForms, serverform:FPForms, completion: @escaping GetFormWithError) {
        FPFormsDatabaseManager().updateServerFormOnly(form: serverform, ticketId: ticketId) { form, success in
            let serverSections = serverform.sections ?? []
            let localSqliteId = localForm.sqliteId ?? 0
            serverSections.forEach { section in
                section.moduleEntityLocalId = localSqliteId
                if let localSection = localForm.sections?.filter({$0.sortPosition == section.sortPosition}).first {
                    section.sqliteId = localSection.sqliteId
                    FPSectionDetailsDatabaseManager().deleteSectionDetails(forArray: [localSection])
                    FPSectionDetailsDatabaseManager().insertSectionDetails([section], localSqliteId) { _ in }
                }
            }
            FPFormsDatabaseManager().fetchFormBy(sqliteId: localSqliteId, shouldIncludeMedia: false, moduleId: FPFormMduleId) { form in
                completion(form, nil)
            }
        }
    }
    
    /**
     This function is used to update partial section of form only
     */
    
    class func upsertDataForPartialSave(ticketId: NSNumber, moduleId: Int, section: FPSectionDetails, completion: @escaping GetFormWithError) {
        FPFormsDatabaseManager().upsertForPartialSave(section: section, ticketId: ticketId, moduleId: moduleId) { success in
            if success {
                completion(FPForms(), nil)
            }else {
                let tempError = FPErrorHandler.getError(code: 401, message: FPLocalizationHelper.localize("lbl_Something_went_wrong"))
                completion(nil, tempError)
            }
        }
        
    }
    
    class func markFormUnsync(form: FPForms, ticketId: NSNumber, moduleId: Int , completion: @escaping ((Bool) -> ())) {
        
        FPFormsDatabaseManager().markPartialFormNeedtoSync(form: form, ticketId: ticketId, moduleId: moduleId, shouldUpdateBySqliteId: true) { success in
            completion(success)
        }
    }
    
    class func markFormLocallySync(form: FPForms, ticketId: NSNumber, completion: @escaping ((Bool) -> ())) {
        FPFormsDatabaseManager().markFormLocallySync(form: form, ticketId: ticketId, completion: completion)
    }
    
    class func deleteFormLocally(form: FPForms, ticketId:NSNumber, moduleId: Int, completion: @escaping GetFormWithError) {
        DispatchQueue.global(qos: .userInitiated).async {
            FPFormsDatabaseManager().deleteFormBySqliteId(form: form, moduleId: moduleId, ticketId: ticketId) { success in
                if success {
                    completion(form, nil)
                }else {
                    let tempError = FPErrorHandler.getError(code: 401, message: FPLocalizationHelper.localize("lbl_Something_went_wrong"))
                    completion(form, tempError)
                }
            }
        }
    }
    
    class func fetchFormBy(objectId:String, completion:@escaping (_ form: FPForms?) -> ()) {
        FPFormsDatabaseManager().fetchFormBy(objectId: objectId, moduleId: FPFormMduleId, shouldIncludeMedia: true) { form in
            completion(form)
        }
    }
    
    class func getCustomFPForms(ticketId:NSNumber, serviceAddressId:NSNumber, sectionDelta:Bool = false, shouldFetchOnline:Bool, showLoader: Bool, completion: @escaping (_ forms: [FPForms]) -> Void) {
        if showLoader {
            DispatchQueue.main.async {
                FPUtility.showHUDWithLoadingMessage()
            }
        }
        if shouldFetchOnline {
            self.fetchCustomFormsForTicket(ticketId: ticketId, serviceAddressId: serviceAddressId, sectionDelta: sectionDelta, showLoader: showLoader) { (result) in
                if showLoader {
                    FPUtility.hideHUD()
                }
                completion(result)
            }
        }else {
            FPFormsDatabaseManager().fetchFormsFromLocal(ticketId: ticketId, moduleId: FPFormMduleId) { fpForms in
                if showLoader {
                    FPUtility.hideHUD()
                }
                completion(fpForms ?? [])
            }
        }
    }
    
    
    class func fetchCustomFormsForTicket(ticketId:NSNumber, serviceAddressId:NSNumber, sectionDelta:Bool, showLoader: Bool, completion: @escaping (_ forms: [FPForms]) -> Void) {
        if showLoader {
            DispatchQueue.main.async {
                FPUtility.showHUDWithLoadingMessage()
            }
        }
        guard FPUtility.isConnectedToNetwork() else {
            if showLoader {
                FPUtility.hideHUD()
            }
            completion([FPForms]())
            return
        }
        
        var params = [String: Any]()
        params["ticketId"] = ticketId
        if sectionDelta{
            params["sectionDelta"] = sectionDelta
        }
        router.request(.getCustomFormsForTicket(params)) { (json, _data, response, _error) in
            DispatchQueue.global(qos: .background).async {
                var fpFormsArray = [FPForms]()
                if _error == nil {
                    guard let results = json?["result"] as? [[String: Any]] else {
                        return
                    }
                    let group = DispatchGroup()
                    var tmpArr = [String]()
                    tmpArr = UserDefaults.standard.object(forKey: "arrDownloadingInspectionForms") as? [String] ?? []
                    for dict in results {
                        group.enter()
                        if let currentStatus = dict["downloadStatus"] as? String, currentStatus == "IN_PROGRESS", let formId = dict["id"] as? String, !formId.isEmpty, !tmpArr.contains(formId){
                            tmpArr.append(formId)
                        }
                        let fpForm = FPForms(dict: dict, isForLocal: true)
                        fpFormsArray.append(fpForm)
                        if sectionDelta{
                            FPFormsDatabaseManager().updateForm(form: fpForm, ticketId: ticketId, moduleId: FPFormMduleId, shouldUpdateBySqliteId: false, sectionDelta: sectionDelta) { _ , success in
                                group.leave()
                            }
                        }else{
                            group.leave()
                        }
                    }
                    group.notify(queue: .main) {
                        if showLoader {
                            FPUtility.hideHUD()
                        }
                        UserDefaults.standard.set(tmpArr,forKey: "arrDownloadingInspectionForms")
                        completion(fpFormsArray)
                    }
                } else {
                    if showLoader {
                        FPUtility.hideHUD()
                    }
                    completion(fpFormsArray)
                }
            }
        }
    }
    
    
    class func getFilesFromForm(form: FPForms){
        FPFormDataHolder.shared.customForm = form
        FPFormDataHolder.shared.getFilesFromValue(form: form)
        
    }
    
    class func getProceessedForm(isNew:Bool)->FPForms{
        return FPFormDataHolder.shared.getProcessedForm(isNew:isNew)!
    }
    
    
    class func uploadMediasAttached(completion:@escaping(_ status:Bool)->Void){
        let array = FPFormDataHolder.shared.getFiledFilesArray()
        var isLastTraversed = false
        var countOfUploading = 0
        guard FPUtility.isConnectedToNetwork() else {
            FPFormDataHolder.shared.saveFilesForOfflineSupport()
            completion(true)
            return
        }
        if(array.count > 0){
            let group = DispatchGroup()
            group.enter()
            array.enumerated().forEach { item in
                if item.element.value.isEmpty && item.offset == array.count - 1 && countOfUploading == 0 {
                    group.leave()
                    group.notify(queue: .main) {
                        completion(true)
                        return
                    }
                } else {
                    item.element.value.enumerated().forEach { media in
                        isLastTraversed = media.offset == item.element.value.count - 1 && item.offset == array.count - 1
                        if media.element.filePath != nil {
                            countOfUploading += 1
                            SSMediaManager.shared.uploadFileWith(media: media.element, baseS3URL: s3EnvironmentString, indexPath: item.element.key, index: media.offset) { json, data, response, error, indexPath, index in
                                countOfUploading -= 1
                                if error == nil, let s3URL = json?["s3URL"] as? String {
                                    FPFormDataHolder.shared.updateServerUrl(url: s3URL, key: indexPath ?? [] , index: index ?? 0 )
                                }
                                if isLastTraversed && countOfUploading == 0 {
                                    group.leave()
                                    group.notify(queue: .main) {
                                        completion(true)
                                        return
                                    }
                                }
                            }
                        } else if isLastTraversed && countOfUploading == 0 {
                            group.leave()
                            group.notify(queue: .main) {
                                completion(true)
                                return
                            }
                        }
                    }
                }
            }
        } else {
            completion(true)
        }
    }
    
    class func uploadMediasAttachedForCurrentSection(section: Int, completion:@escaping(_ status:Bool)->Void){
        let array = FPFormDataHolder.shared.getFiledFilesArrayForSection(section: section)
        var isLastTraversed = false
        var countOfUploading = 0
        guard FPUtility.isConnectedToNetwork() else {
            FPFormDataHolder.shared.saveFilesForOfflineSupportPartialSection(sectionfiledFiles: array)
            completion(true)
            return
        }
        if(array.count > 0){
            let group = DispatchGroup()
            group.enter()
            array.enumerated().forEach { item in
                if item.element.value.isEmpty && item.offset == array.count - 1 && countOfUploading == 0 {
                    group.leave()
                    group.notify(queue: .main) {
                        completion(true)
                        return
                    }
                } else {
                    item.element.value.enumerated().forEach { media in
                        isLastTraversed = media.offset == item.element.value.count - 1 && item.offset == array.count - 1
                        if (media.element.filePath != nil &&  (media.element.serverUrl == nil || media.element.serverUrl == "")) {
                            countOfUploading += 1
                            SSMediaManager.shared.uploadFileWith(media: media.element, baseS3URL: s3EnvironmentString, indexPath: item.element.key, index: media.offset) { json, data, response, error, indexPath, index in
                                countOfUploading -= 1
                                if error == nil, let s3URL = json?["s3URL"] as? String {
                                    FPFormDataHolder.shared.updateServerUrl(url: s3URL, key: indexPath ?? [] , index: index ?? 0 )
                                }
                                if isLastTraversed && countOfUploading == 0 {
                                    group.leave()
                                    group.notify(queue: .main) {
                                        completion(true)
                                        return
                                    }
                                }
                            }
                        } else if isLastTraversed && countOfUploading == 0 {
                            group.leave()
                            group.notify(queue: .main) {
                                completion(true)
                                return
                            }
                        }
                    }
                }
            }
        } else {
            completion(true)
        }
    }
    
    class func routeToOfflinePartialSaveCustomFormSection(ticketId: NSNumber, section: FPSectionDetails, form: FPForms, completion: @escaping GetFormWithError) {
        DispatchQueue.global(qos: .userInitiated).async {
            form.isSyncedToServer = false
            section.isSyncedToServer = false
            self.markFormUnsync(form: form, ticketId: ticketId, moduleId: FPFormMduleId) { _ in
                let results = AssetFormLinkingDatabaseManager().fetchAssetLinkigDataFor(customForm: form)
                for linkdata in results{
                    let updated = linkdata
                    updated.isNotConfirmed = false
                    AssetFormLinkingDatabaseManager().upsert(item: updated){  _ in }
                }
                section.moduleEntityLocalId = form.sqliteId
                self.upsertDataForPartialSave(ticketId: ticketId, moduleId: FPFormMduleId, section: section) { form, error in
                    completion(form, error)
                }
            }
        }
    }
    
    /**
     This function is used to save partial function api where we pass forms id, template Id and section object
     */
    
    class func routeToPartialSaveCustomFormSection(ticketId: NSNumber, section: FPSectionDetails, form: FPForms, sectionIndex: Int, setSynced: Bool, assetLinkDetail:[String:Any]? = nil, completion: @escaping GetFormWithError) {
        guard FPUtility.isConnectedToNetwork() else {
            DispatchQueue.global(qos: .userInitiated).async {
                form.isSyncedToServer = false
                section.isSyncedToServer = false
                self.markFormUnsync(form: form, ticketId: ticketId, moduleId: FPFormMduleId) { _ in
                    let results = AssetFormLinkingDatabaseManager().fetchAssetLinkigDataFor(customForm: form)
                    for linkdata in results{
                        let updated = linkdata
                        updated.isNotConfirmed = false
                        AssetFormLinkingDatabaseManager().upsert(item: updated){  _ in }
                    }
                    section.moduleEntityLocalId = form.sqliteId
                    self.upsertDataForPartialSave(ticketId: ticketId, moduleId: FPFormMduleId, section: section) { form, error in
                        completion(form, error)
                    }
                }
            }
            return
      }

       var params = [String: Any]()
       if let objectId = form.objectId, let intvalue = Int(objectId) {
           params["moduleEntityId"] = intvalue
       }else{
           params["moduleEntityId"] = form.objectId
       }
       params["ticketId"] = ticketId
       params["sectionDetails"] = section.getJSON()
       
       if let data = assetLinkDetail, !data.isEmpty{
           params["assetLinkingDetails"] = data
       }
       if let deletedSections = FPFormDataHolder.shared.customForm?.deletedSections, !deletedSections.isEmpty{
           let arrSections = deletedSections.components(separatedBy: ",")
           let delSections = arrSections.compactMap({Int($0)})
           if !delSections.isEmpty{
               params["delete"] = ["section":delSections]
           }
       }
        router.request(.updateCustomFormSection(params)) { (json, _data, response, _error ) in
            DispatchQueue.global(qos: .userInitiated).async {
                if _error == nil {
                    guard let result = json?["result"] as? [String: Any] else {
                        let tempError = FPErrorHandler.getError(code: 401, message: FPLocalizationHelper.localize("lbl_Something_went_wrong"))
                        return
                    }
                    var updatedSection = section
                    let formOnline = FPForms.init(dict: result, isForLocal: true)
                    if let localSection = FPFormDataHolder.shared.getSection(at: sectionIndex){
                        if let serverSection = formOnline.sections?.filter({$0.sortPosition == localSection.sortPosition} ).first as? FPSectionDetails{
                            serverSection.sqliteId = localSection.sqliteId
                            if serverSection.fields.count == localSection.fields.count, !serverSection.fields.isEmpty {
                                var sortedServerSectionFields =  serverSection.fields.sorted(by:{$0.sortPosition ?? "" < $1.sortPosition ?? ""})
                                let sortedLocalSectionFields =  localSection.fields.sorted(by:{$0.sortPosition ?? "" < $1.sortPosition ?? ""})
                                sortedServerSectionFields.enumerated().forEach { (index,_) in
                                    sortedServerSectionFields[index].sqliteId = sortedLocalSectionFields[index].sqliteId
                                }
                                serverSection.fields = sortedServerSectionFields
                            }
                            
                            //make sure assetId field at last---
                            var sectionFields = serverSection.fields
                            if let index = sectionFields.firstIndex(where: {$0.getUIType() == .HIDDEN && $0.name == "assetId"}){
                                sectionFields.append(sectionFields.remove(at: index))
                            }
                            serverSection.fields = sectionFields
                            //--------
//                            FPFormDataHolder.shared.sections?[sectionIndex] = serverSection
                            if let localId = localSection.objectId,
                               let idx = FPFormDataHolder.shared.sections?.firstIndex(where: { $0.objectId == localId }) {
                                FPFormDataHolder.shared.sections?[idx] = serverSection
                            } else {
                                // Sort a mutable copy, mutate, and assign back
                                if var sections = FPFormDataHolder.shared.sections {
                                    sections.sort { ($0.sortPosition ?? "") < ($1.sortPosition ?? "") }
                                    if sections.indices.contains(sectionIndex) {
                                        sections[sectionIndex] = serverSection
                                    } else {
                                        // If index out of range, append as fallback
                                        sections.append(serverSection)
                                    }
                                    FPFormDataHolder.shared.sections = sections
                                }
                            }
                            updatedSection = serverSection
                        }
                    }
                    let results = AssetFormLinkingDatabaseManager().fetchAssetLinkigDataFor(customForm: form)
                    for linkdata in results{
                        let updated = linkdata
                        updated.customFormId = NSNumber(value: Int(formOnline.objectId ?? "0") ?? 0)
                        updated.isSyncedToServer = true
                        updated.isNotConfirmed = false
                        if linkdata.deleteLinking{
                            AssetFormLinkingDatabaseManager().deleteMappingData(updated){  _ in }
                        }else{
                            AssetFormLinkingDatabaseManager().upsert(item: updated){  _ in }
                        }
                    }
                    updatedSection.moduleEntityLocalId = form.sqliteId
                    updatedSection.isSyncedToServer = true
                    self.upsertDataForPartialSave(ticketId: ticketId, moduleId: FPFormMduleId, section: updatedSection) { form, error in
                        completion(form, error)
                    }
                } else {
                    FPUtility.hideHUD()
                    completion(nil, _error)
                }
            }
        }
    }
    
    static func uploadTableAttachments(medias:[TableMedia] =  [],startIndex:Int = 0,completion:@escaping(_ status:Bool)->Void){
        guard FPUtility.isConnectedToNetwork() else {
            completion(true)
            return
        }
        var mediaArray = medias
        if (mediaArray.isEmpty){
            mediaArray = FPFormDataHolder.shared.tableMedia
        }
        if(mediaArray.count>startIndex){
            uploadTableMedia(tableMedia:mediaArray[startIndex]) { tableMedia in
                if(mediaArray.count>startIndex+1){
                    uploadTableAttachments(medias: mediaArray,startIndex: startIndex+1, completion:completion)
                }else{
                    completion(true)
                }
            }
        }else{
            completion(true)
        }
        
    }
    
    static func uploadTableAttachmentsForCurrentSection(section: Int, medias:[TableMedia] =  [],startIndex:Int = 0,completion:@escaping(_ status:Bool)->Void){
        guard FPUtility.isConnectedToNetwork() else {
            completion(true)
            return
        }
        var mediaArray = medias
        if (mediaArray.isEmpty){
            mediaArray = FPFormDataHolder.shared.tableMedia.filter({ $0.parentTableIndex?.section == section })
        }
        if(mediaArray.count>startIndex){
            uploadTableMedia(tableMedia:mediaArray[startIndex]) { tableMedia in
                if(mediaArray.count>startIndex+1){
                    uploadTableAttachments(medias: mediaArray,startIndex: startIndex+1, completion:completion)
                }else{
                    completion(true)
                }
            }
        }else{
            completion(true)
        }
    }
    
    private static func uploadTableMedia(tableMedia:TableMedia, tableMediaindex:Int=0,completion:@escaping(_ tableMedia:TableMedia)->Void){
        if(tableMedia.mediaAdded.count>tableMediaindex){
            let media  = tableMedia.mediaAdded[tableMediaindex]
            SSMediaManager.shared.uploadFileWith(media: media, baseS3URL: s3EnvironmentString, indexPath: tableMedia.parentTableIndex!, index: tableMedia.childTableIndex!.section-1, completion: { json, data, response, error, indexPath, index in
                
                if error == nil, let s3URL = json?["s3URL"] as? String {
                    var tempMedia = media
                    tempMedia.serverUrl = s3URL
                    var tempTableMedia = tableMedia
                    tempTableMedia.mediaAdded[tableMediaindex] = tempMedia
                    FPFormDataHolder.shared.updateTableFieldValue(media: tempTableMedia,isPostUpload: true)
                    uploadTableMedia(tableMedia: tempTableMedia, tableMediaindex: tableMediaindex+1, completion: completion)
                }
            })
        }else{
            completion(tableMedia)
        }
    }
    
    class func routeToSaveCustomForm(ticketId: NSNumber, isNew: Bool, form: FPForms, setSynced: Bool, assetLinkDetail:[String:Any]? = nil, completion: @escaping GetFormWithError) {
        if isNew || form.objectId == nil{
            let tempForm = form
            tempForm.objectId = nil
            self.addCustomForm(ticketId: ticketId, form: tempForm, setSynced: setSynced, assetLinkDetail: assetLinkDetail) { result, error in
                completion(result, error)
            }
        } else {
            self.updateCustomForm(ticketId: ticketId, form: form, setSynced: setSynced, assetLinkDetail: assetLinkDetail) { result, error in
                completion(result, error)
            }
        }
    }
    
    class func updateCustomForm(ticketId: NSNumber, form: FPForms, setSynced: Bool, assetLinkDetail:[String:Any]? = nil, completion: @escaping GetFormWithError){
        guard FPUtility.isConnectedToNetwork() else {
            DispatchQueue.global(qos: .userInitiated).async {
                form.isSyncedToServer = false
                self.upsertLocalData(ticketId: ticketId, moduleId: FPFormMduleId, form: form) { form, error in
                    completion(form, error)
                }
            }
            return
        }
        var dictJson = form.getJSONForUpdate()
        if let data = assetLinkDetail, !data.isEmpty{
            dictJson["assetLinkingDetails"] = data
        }
        if let deletedSections = FPFormDataHolder.shared.customForm?.deletedSections, !deletedSections.isEmpty{
            let arrSections = deletedSections.components(separatedBy: ",")
            let delSections = arrSections.compactMap({Int($0)})
            if !delSections.isEmpty{
                dictJson["delete"] = ["section":delSections]
            }
        }
        router.request(.updateCustomForm(dictJson)) { (json, _data, response, _error ) in
            DispatchQueue.global(qos: .userInitiated).async {
                if _error == nil {
                    guard let result = json?["result"] as? [String: Any] else {
                        completion(nil, FPErrorHandler.getError(code: 401, message: FPLocalizationHelper.localize("lbl_Something_went_wrong")))
                        return
                    }
                    let formOnline = FPForms.init(dict: result,isForLocal: true)
                    formOnline.isSyncedToServer = true
                    formOnline.sqliteId = form.sqliteId
                    let results = AssetFormLinkingDatabaseManager().fetchAssetLinkigDataFor(customForm: formOnline)
                    let group = DispatchGroup()
                    for linkdata in results{
                        let updated = linkdata
                        updated.customFormId = NSNumber(value: Int(form.objectId ?? "0") ?? 0)
                        updated.isSyncedToServer = true
                        updated.isNotConfirmed = false
                        if linkdata.deleteLinking{
                            group.enter()
                            AssetFormLinkingDatabaseManager().deleteMappingData(updated){  _ in
                                group.leave()
                            }
                        }else{
                            group.enter()
                            AssetFormLinkingDatabaseManager().upsert(item: updated){  _ in
                                group.leave()
                            }
                        }
                    }
                    if isStaffTechnician{
                        FPFormsServiceManager.preComileFPForm(form: formOnline, ticketID: ticketId.stringValue) {}
                    }
                    self.upsertServerData(ticketId: ticketId, moduleId: FPFormMduleId, localForm: form, serverform: formOnline) { dbform, error in
                        completion(dbform, error)
                    }
                } else {
                    FPUtility.hideHUD()
                    completion(nil, _error)
                }
            }
        }
    }
    
    class func addCustomForm(ticketId: NSNumber, form: FPForms, setSynced: Bool, assetLinkDetail:[String:Any]? = nil, completion: @escaping GetFormWithError) {
        guard FPUtility.isConnectedToNetwork() else {
            DispatchQueue.global(qos: .userInitiated).async {
                form.isSyncedToServer = false
                form.isActive = true
                self.upsertLocalData(ticketId: ticketId, moduleId: FPFormMduleId, form: form) { form, error in
                    let group = DispatchGroup()
                    for linking in FPFormDataHolder.shared.arrLinkingDB{
                        let updated = linking
                        updated.customFormLocalId = form?.sqliteId
                        updated.isNotConfirmed = false
                        group.enter()
                        AssetFormLinkingDatabaseManager().upsert(item: updated) { _ in
                            group.leave()
                        }
                    }
                    FPFormDataHolder.shared.arrLinkingDB = []
                    completion(form, error)
                }
            }
            return
        }
        let dictJson = form.getJSONForSync()
        var params = [String: Any]()
        params["ticketId"] = ticketId
        params["fpForm"] = dictJson
        if let data = assetLinkDetail, !data.isEmpty{
            params["assetLinkingDetails"] = data
        }
        router.request(.addCustomForm(params)) { (json, _data, response, _error ) in
            DispatchQueue.global(qos: .userInitiated).async {
                if _error == nil {
                    guard let result = json?["result"] as? [String: Any] else {
                        completion(nil, FPErrorHandler.getError(code: 401, message: FPLocalizationHelper.localize("lbl_Something_went_wrong")))
                        return
                    }
                    let formOnline = FPForms.init(dict: result,isForLocal: true)
                    formOnline.isSyncedToServer = true
                    
                    if isStaffTechnician{
                        FPFormsServiceManager.preComileFPForm(form: formOnline, ticketID: ticketId.stringValue) {
                        }
                    }
                    
                    let results = AssetFormLinkingDatabaseManager().fetchAssetLinkigDataFor(customForm: form)
                    let group = DispatchGroup()
                    for linkdata in results{
                        let updated = linkdata
                        updated.customFormId = NSNumber(value: Int(formOnline.objectId ?? "0") ?? 0)
                        updated.isSyncedToServer = true
                        updated.isNotConfirmed = false
                        group.enter()
                        AssetFormLinkingDatabaseManager().upsert(item: updated){  _ in
                            group.leave()
                        }
                    }
                    
                    
                    for linking in FPFormDataHolder.shared.arrLinkingDB{
                        let updated = linking
                        updated.customFormId = NSNumber(value: Int(formOnline.objectId ?? "0") ?? 0)
                        updated.isNotConfirmed = false
                        group.enter()
                        AssetFormLinkingDatabaseManager().upsert(item: updated) { _ in
                            group.leave()
                        }
                    }
                    FPFormDataHolder.shared.arrLinkingDB = []
                    
                    if let _ = form.sqliteId {
                        FPFormsDatabaseManager().deleteFormBySqliteId(form: form, moduleId: FPFormMduleId, ticketId: ticketId) { _ in
                            FPFormsDatabaseManager().insertForm(form: formOnline, ticketId: ticketId, moduleId: FPFormMduleId) { _ , success in
                                if success {
                                    completion(formOnline, nil)
                                }else {
                                    let tempError = FPErrorHandler.getError(code: 401, message: FPLocalizationHelper.localize("lbl_Something_went_wrong"))
                                    completion(nil, tempError)
                                }
                            }
                        }
                    }else {
                        FPFormsDatabaseManager().insertForm(form: formOnline, ticketId: ticketId, moduleId: FPFormMduleId) { _  , _ in
                            completion(formOnline, nil)
                        }
                    }
                } else {
                    FPUtility.hideHUD()
                    completion(nil, _error)
                }
            }
        }
    }
    
    
    @objc class func getFPFormTemplates(shouldFetchOnline:Bool, showLoader: Bool, isOnlyActive:Bool, completion:  GetFormsWithError? = nil) {
        if showLoader {
            DispatchQueue.main.async {
                FPUtility.showHUDWithLoadingMessage()
            }
        }
        if shouldFetchOnline {
            self.fetchFPFormTemplates(showLoader: showLoader) { result, _  in
                FPUtility.hideHUD()
                completion?(result, nil)
            }
        }else {
            FPFormsDatabaseManager().fetchFPFormTemplatesFromLocal() { forms in
                FPUtility.hideHUD()
                completion?(forms ?? [], nil)
            }
            
        }
    }
    
    @objc class func fetchFPFormTemplates(showLoader: Bool, completion:  GetFormsWithError? = nil) {
        if showLoader {
            DispatchQueue.main.async {
                FPUtility.showHUDWithLoadingMessage()
            }
        }
        guard FPUtility.isConnectedToNetwork() else {
            if showLoader {
                FPUtility.hideHUD()
            }
            completion?([FPForms](), nil)
            return
        }
        router.request(.getFPFormTemplates) { (json, _data, response, _error) in
            DispatchQueue.global(qos: .background).async {
                var formTemplatesArray = [FPForms]()
                var localFormTemplatesArray = [FPForms]()
                if _error == nil {
                    guard let results = json?["result"] as? [[String: Any]] else {
                        completion?(formTemplatesArray, nil)
                        return
                    }
                    for item in results {
                        let fpTemplate = FPForms(dict: item, isForLocal: false)
                        fpTemplate.isTemplate = true
                        formTemplatesArray.append(fpTemplate)
                        
                        let localTemplate = FPForms(dict: item, isForLocal: true)
                        localTemplate.isTemplate = true
                        localFormTemplatesArray.append(localTemplate)
                    }
                    
                    if showLoader {
                        FPUtility.hideHUD()
                    }
                    completion?(formTemplatesArray, nil)
                    
                    FPFormsDatabaseManager().deleteAllFPFormsFromLocal(ticketId: 0, moduleId: FPFormTemplateModuleId) { success in
                        FPFormsDatabaseManager().insertAllFPForms(forms: localFormTemplatesArray, ticketId: 0, moduleId: FPFormTemplateModuleId) {
                            self.updateDifferentialMetaAndFetch(isFetching: false, shouldChangeUpdatedAt: true, shouldFetch: false, completion: { _, _ in
                            })
                        }
                    }
                } else {
                    if showLoader {
                        FPUtility.hideHUD()
                    }
                    FPUtility.printErrorAndShowAlert(error: _error)
                }
            }
        }
    }
    
    class func getPreviousFPForms(customerId: NSNumber, showLoader: Bool, completion: @escaping  (_ customForms: [FPForms]) -> Void) {
        guard FPUtility.isConnectedToNetwork() else {
            completion([FPForms]())
            return
        }
        if showLoader {
            DispatchQueue.main.async {
                FPUtility.showHUDWithLoadingMessage()
            }
        }
        let params = ["serviceAddressId": customerId,"limit":1000]
        router.request(.getPreviousFPForms(params)) { (json, _data, response, error) in
            if showLoader {
                FPUtility.hideHUD()
            }
            var formsArray = [FPForms]()
            if error == nil {
                guard let result = json?["result"] as? [String: Any] else {
                    completion(formsArray)
                    return
                }
                guard let results = result["results"] as? [[String: Any]] else {
                    completion(formsArray)
                    return
                }
                for item in results {
                    formsArray.append(FPForms(dict: item, isForLocal: true))
                }
            } else {
                FPUtility.printErrorAndShowAlert(error: error)
            }
            completion(formsArray)
        }
    }
    
    class func getFPFormDetails(formId: String,ticketId:NSNumber, showLoader: Bool, isUpdateToLocal: Bool = false, completion: @escaping  (_ form: FPForms) -> Void) {
        guard FPUtility.isConnectedToNetwork() else {
            completion(FPForms())
            return
        }
        if showLoader {
            DispatchQueue.main.async {
                FPUtility.showHUDWithLoadingMessage()
            }
        }
        let params = ["id": formId,"ticketId":ticketId] as [String : Any]
        router.request(.getFPFormDetails(params)) { json, _, _, error in
            if showLoader {
                FPUtility.hideHUD()
            }
            if error == nil {
                guard let result = json?["result"] as? [String: Any] else {
                    completion(FPForms())
                    return
                }
                if isUpdateToLocal{
                    let localform = FPForms(dict: result, isForLocal: true)
                    FPFormsDatabaseManager().upsert(form: localform, ticketId: ticketId) { _ in
                        completion(localform)
                    }
                }else{
                    let onlineform = FPForms(dict: result, isForLocal: false)
                    completion(onlineform)
                }
               
            } else {
                FPUtility.printErrorAndShowAlert(error: error)
            }
        }
    }
    
    class func getFPFormUpsertDeleteArray(result:[String:Any], isForTemplate:Bool, isForLocal:Bool) -> ([FPForms],[FPForms]) {
        var fpformArray = [FPForms]()
        var deletedArray = [FPForms]()
        for (key, values) in result {
            for item in values as! [[String: Any]] {
                let item = FPForms(dict: item, isForLocal: isForLocal)
                if isForTemplate {
                    item.isTemplate = true
                }
                if key.lowercased() == "added" ||  key.lowercased() == "updated" {
                    fpformArray.append(item)
                }else {
                    deletedArray.append(item)
                }
            }
        }
        return (fpformArray, deletedArray)
    }
    
    class func deleteCustomForms(ticketId: NSNumber, forms: [FPForms], showLoader: Bool, completion: @escaping ((_ success: Bool, _ error: Error?) -> ())) {
        var params = [String: Any]()
        params["ticketId"] = ticketId
        let formIds = forms.compactMap({$0.objectId})
        params["fpFormIds"] = formIds
        if showLoader{
            DispatchQueue.main.async {
                FPUtility.showHUDWithDeleteMessage()
            }
        }
        router.request(.deleteCustomForms(params)) { (json, _data, response, _error ) in
            if showLoader{
                FPUtility.hideHUD()
            }
            if _error == nil {
                guard let _ = json?["result"] as? [[String: Any]] else {
                    completion(false, FPErrorHandler.getError(code: 401, message: FPLocalizationHelper.localize("lbl_Something_went_wrong")))
                    return
                }
                FPFormsDatabaseManager().deleteFormsByObjectId(forms: forms, moduleId: FPFormMduleId, ticketId: ticketId) {
                    completion(true, nil)
                }
                completion(true, nil)
            } else {
                completion(false, _error)
            }
        }
    }
    
    class func downloadCustomForm(ticketId: NSNumber, showLoader: Bool, params: [String:Any], completion: @escaping(_ strUrl: String?, Error?) -> ()) {
        if showLoader{
            DispatchQueue.main.async {
                FPUtility.showHUDWithLoadingMessage()
            }
        }
        
        router.request(.downloadCustomForm(params)) { (json, _data, response, _error ) in
            if showLoader{
                FPUtility.hideHUD()
            }
            if _error == nil {
                guard let result = json?["result"] as? [String: Any] else {
                    completion(nil, FPErrorHandler.getError(code: 401, message: FPLocalizationHelper.localize("lbl_Something_went_wrong")))
                    return
                }
                if let location = result["Location"] as? String{
                    completion(location, nil)
                }else if let location = result["location"] as? String{
                    completion(location, nil)
                }
            } else {
                completion(nil, _error)
            }
        }
    }
    
    class func requestDownloadCustomForm(formId: String, params : [String: Any], showLoader: Bool, completion: @escaping ((_ success: Bool, _ error: Error?) -> ()))  {
        if showLoader{
            DispatchQueue.main.async {
                FPUtility.showHUDWithLoadingMessage()
            }
        }
        router.request(.requestDownloadCustomForm(formId, params: params)) { (json, _data, response, _error ) in
            if showLoader{
                FPUtility.hideHUD()
            }
            if _error == nil {
                guard let _ = json?["result"] as? [String: Any] else {
                    let tempError = FPErrorHandler.getError(code: 401, message: FPLocalizationHelper.localize("lbl_Something_went_wrong"))
                    FPUtility.printErrorAndShowAlert(error: tempError)
                    completion(false, _error)
                    return
                }
                completion(true, nil)
            } else {
                completion(false, _error)
            }
        }
    }
    
    class func fetchDownloadStatus(showLoader: Bool, params: [String:Any], completion: @escaping ((_ result: [String:Any]?, _ error: Error?) -> ()))  {
        if showLoader{
            DispatchQueue.main.async {
                FPUtility.showHUDWithLoadingMessage()
            }
        }
        
        router.request(.fetchDownloadStatus(params: params)) { (json, _data, response, _error ) in
            if showLoader{
                FPUtility.hideHUD()
            }
            if _error == nil {
                guard let result = json?["result"] as? [String: Any] else {
                    let tempError = FPErrorHandler.getError(code: 401, message: FPLocalizationHelper.localize("lbl_Something_went_wrong"))
                    FPUtility.printErrorAndShowAlert(error: tempError)
                    completion(nil, _error)
                    return
                }
                completion(result, nil)
            } else {
                completion(nil, _error)
            }
        }
    }
    
    @objc class func getFPFormTemplatesOnline(showLoader: Bool, completion: @escaping GetFormsWithError) {
        if showLoader {
            DispatchQueue.main.async {
                FPUtility.showHUDWithLoadingMessage()
            }
        }
        guard FPUtility.isConnectedToNetwork() else {
            FPFormsDatabaseManager().fetchFPFormTemplatesFromLocal() { forms in
                if showLoader {
                    FPUtility.hideHUD()
                }
                completion(forms ?? [], nil)
            }
            return
        }
        let param = self.getParamFor(item: commonFPFormTemplates)
        let paramApi:[String: Any] = ["objectsToFetch": param["objectsToFetch"] ?? [String](), "options": param["options"] ?? [String:Any]()]
        router.request(.getCommonTemplates(paramApi)) { (json, data, response, error) in
            DispatchQueue.global(qos: .utility).async {
                if showLoader {
                    FPUtility.hideHUD()
                }
                if error == nil{
                    guard let result = json?["result"] as? [String: Any] else {
                        self.updateDifferentialMeta(isFetching: false, shouldChangeUpdatedAt: false) {
                            let tempError = FPErrorHandler.getError(code: 401, message: FPLocalizationHelper.localize("lbl_Something_went_wrong"))
                            FPUtility.printErrorAndShowAlert(error: tempError)
                            completion([], error)
                        }
                        return
                    }
                    
                    let group = DispatchGroup()
                    
                    if let fpForms = result[commonFPFormTemplates] {
                        group.enter()
                        var preUpdatedAt = ""
                        if let options = param["optionsRaw"] as? [String:Any], let updatedAt = options[commonFPFormTemplates] as? String {
                            preUpdatedAt = updatedAt
                        }
                        FPFormsServiceManager.upsertFPFormTemplatesLocallyAndFetchToDisplay(json: ["result": fpForms], updatedAt: preUpdatedAt) { forms, _error in
                            group.leave()
                            completion(forms, _error)
                        }
                    }
                    
                } else {
                    self.updateDifferentialMeta(isFetching: false, shouldChangeUpdatedAt: false) {
                        FPUtility.printErrorAndShowAlert(error: error)
                        completion([], error)
                    }
                }
            }
        }
    }
    
    @objc class func getParamFor(item: String) -> [String:Any] {
        var param = [String:Any]()
        var objectsToFetch = [String]()
        var options = [String:Any]()
        var optionsUpdatedAt = [String:Any]()
        let diffMeta = self.getTemplateDifferential(isFetching: true, item: item, shouldClearUpdatedAt: false)
        FPDifferentialMetaDatabaseManager().upsertDifferetialMeta(differentialMeta: diffMeta, shouldChangeUpdatedAt: false) { success, updatedAt in
            objectsToFetch.append(item)
            if updatedAt != "" {
                options[item] = ["updatedAt" : FPUtility.getDateStringWithBySubtractingTimeInterval(sec:5, from:updatedAt)]
            }
            optionsUpdatedAt[item] = updatedAt
        }
        param["objectsToFetch"] = objectsToFetch
        param["options"] = options
        param["optionsRaw"] = optionsUpdatedAt
        return param
    }
    
    @objc class func updateDifferentialMeta(isFetching:Bool, shouldChangeUpdatedAt:Bool, completion: @escaping completionHandler) {
        let diffMeta = self.getTemplateDifferential(isFetching: isFetching, item: commonFPFormTemplates, shouldClearUpdatedAt: false)
        FPDifferentialServiceManager.upsertDifferentialMeta(differentialMeta: diffMeta, shouldChangeUpdatedAt: shouldChangeUpdatedAt) { success, updatedAt in
            completion()
        }
    }
    
    class func getTemplateDifferential(isFetching: Bool, item: String,shouldClearUpdatedAt:Bool) -> FPDifferentialMeta {
        let diff = FPDifferentialMeta()
        diff.apiName = FPFormsApiName.getCommonTemplates([String : Any]()).path
        diff.isFetching = isFetching
        diff.payload = item
        
        if shouldClearUpdatedAt{
            diff.updatedAt = ""
        }else{
            diff.updatedAt = FPUtility.getUTCDateSQLiteQuery(date: Date()) ?? ""
        }
        return diff
    }
    
    @objc class func updateDifferentialMetaAndFetch(isFetching:Bool, shouldChangeUpdatedAt:Bool, shouldFetch:Bool, completion: @escaping GetFormsWithError) {
        let moduldId = FPFormTemplateModuleId
        self.updateDifferentialMeta(isFetching: false, shouldChangeUpdatedAt: true) {
            if shouldFetch {
                FPFormsDatabaseManager().fetchFormsFromLocal(ticketId: 0, moduleId: moduldId) { forms in
                    completion(forms ?? [FPForms](), nil)
                }
            }else {
                completion([FPForms](), nil)
            }
        }
    }
    
    
    @objc class func resetDifferntialMetaFor(commonTemplate:String,completion: @escaping completionHandler) {
        let diffMeta = self.getTemplateDifferential(isFetching: false, item: commonTemplate,shouldClearUpdatedAt: true)
        FPDifferentialServiceManager.upsertDifferentialMeta(differentialMeta: diffMeta, shouldChangeUpdatedAt: true) { success, updatedAt in
            completion()
        }
    }
    
    
    
    @objc class func upsertFPFormTemplatesLocallyAndFetchToDisplay(json: [String: Any]?, updatedAt: String, completion: @escaping GetFormsWithError) {
        var formTemplatesArray = [FPForms]()
        var localFormTemplatesArray = [FPForms]()
        var deletedArray = [FPForms]()
        if updatedAt != "" {
            guard let result = json?["result"] as? [String: Any] else {
                self.updateDifferentialMeta(isFetching: false, shouldChangeUpdatedAt: false) {
                    let tempError = FPErrorHandler.getError(code: 401, message: FPLocalizationHelper.localize("lbl_Something_went_wrong"))
                    FPUtility.printErrorAndShowAlert(error: tempError)
                    completion(formTemplatesArray, tempError)
                }
                return
            }
            (formTemplatesArray, deletedArray) = self.getFPFormUpsertDeleteArray(result: result, isForTemplate: true, isForLocal: false)
        } else {
            guard let results = json?["result"] as? [[String: Any]] else {
                self.updateDifferentialMeta(isFetching: false, shouldChangeUpdatedAt: false) {
                    let tempError = FPErrorHandler.getError(code: 401, message: FPLocalizationHelper.localize("lbl_Something_went_wrong"))
                    FPUtility.printErrorAndShowAlert(error: tempError)
                    completion(formTemplatesArray, tempError)
                }
                return
            }
            for dict in results {
                let item = FPForms(dict: dict, isForLocal: false)
                item.isTemplate = true
                formTemplatesArray.append(item)
                
                let localTemplate = FPForms(dict: dict, isForLocal: true)
                localTemplate.isTemplate = true
                localFormTemplatesArray.append(localTemplate)
            }
        }
        
        guard updatedAt != "" else {
            
            FPFormsDatabaseManager().deleteAllFPFormsFromLocal(ticketId: 0, moduleId: FPFormTemplateModuleId) { success in
                FPFormsDatabaseManager().insertAllFPForms(forms: localFormTemplatesArray, ticketId: 0, moduleId: FPFormTemplateModuleId) {
                    self.updateDifferentialMetaAndFetch(isFetching: false, shouldChangeUpdatedAt: true, shouldFetch: false, completion: { results, error in
                        completion(results, error)
                    })
                }
            }
            return
        }
        
        FPFormsDatabaseManager().upsertFormsByObjectId(forms: localFormTemplatesArray, moduleId: FPFormTemplateModuleId, ticketId: 0) {
            if deletedArray.count > 0 {
                FPFormsDatabaseManager().deleteFormsByObjectId(forms: deletedArray, moduleId: FPFormTemplateModuleId, ticketId: 0) {
                    self.updateDifferentialMetaAndFetch(isFetching: false, shouldChangeUpdatedAt: true, shouldFetch: false, completion: { results, error in
                        completion(results, error)
                    })
                }
            }else{
                self.updateDifferentialMetaAndFetch(isFetching: false, shouldChangeUpdatedAt: true, shouldFetch: false, completion: { results, error in
                    completion(results, error)
                })
            }
        }
    }
    
    class func getRecommendationCheckList(recommendation: String,checkListData: [String],completion: @escaping GetCheckListWithError) {
        var summaryParms = [String:Any]()
        summaryParms["deficiency"] = "inspection is been done"
        summaryParms["deficiencyReason"] = recommendation
        summaryParms["checklist"] = checkListData
        summaryParms["actions"] = ["get_covered_checklist"]
        router.request(.getChecklistAndSummary(summaryParms)) { (json, _data, response, _error ) in
            if _error == nil {
                if let result = json?["result"] as? [String:Any]{
                    if let suggestions = result["suggestions"] as? [String:Any], let actions = suggestions["actions"] as? [String:Any]{
                        if let checklist = actions["get_covered_checklist"] as? [String:Any],
                           let answer = checklist["answer"] as? [String:Any],
                           let message = answer["message"] as? [String:Any],
                           let checklist_covered = message["content"] as? String{
                            let dict = checklist_covered.getDictonary()
                            completion(dict, _error)
                        }
                    }
                }
            } else {
                completion([:], _error)
            }
        }
    }
    
    class func getRecommendationSuggestions(reason: String,completion: @escaping GetRecomendationListWithError) {
        var parms = [String:Any]()
        parms["query"] = reason
        router.request(.getRecommendationSuggestions(parms)) { (json, _data, response, _error ) in
            if _error == nil {
                if let result = json?["result"] as? [String:Any]{
                    let result = result["response"] as? [String:Any]
                    let recommendations = result?["recommendations"] as? [String] ?? []
                    completion(recommendations, _error)
                }
            } else {
                completion([], _error)
            }
        }
    }
}

// MARK: - FP Form List Revamp

extension FPFormsServiceManager {
    class func getAllInspectionFormsFor(ticketId: NSNumber, params:[String:Any], showLoader: Bool, completion: @escaping GetInspectionFormsCompletionBlock) {
        router.request(.getInspectionForms(params)) { (json, _data, response, _error) in
            if _error == nil {
                guard let result = json?["result"] as? [String: Any] else {
                    if showLoader {
                        FPUtility.hideHUD()
                    }
                    completion([FPForms](), 0, FPErrorHandler.getError(code: 401, message: FPLocalizationHelper.localize("lbl_Something_went_wrong")))
                    return
                }
                guard let results = result["data"] as? [[String:Any]] else {
                    if showLoader {
                        FPUtility.hideHUD()
                    }
                    completion([FPForms](), 0, FPErrorHandler.getError(code: 401, message: FPLocalizationHelper.localize("lbl_Something_went_wrong")))
                    return
                }
                if let deletedFpFormIds = result["deleted"] as? [NSNumber], !deletedFpFormIds.isEmpty{
                    ZenForms.deleteInspectionFormsByIds(deletedFpFormIds.map{$0.stringValue}, ticketId: ticketId) { }
                }
                let total = result["total"] as? Int ?? 0
                self.processInspectionForms(arrResults: results, total: total, ticketId) { forms, total,  error  in
                    completion(forms, total, error)
                }
            } else {
                if showLoader {
                    FPUtility.hideHUD()
                }
                completion([FPForms](), 0, _error)
            }
        }
    }
    
    class func processInspectionForms(arrResults: [[String: Any]], total:Int, _ ticketId: NSNumber, completion: @escaping GetInspectionFormsCompletionBlock) {
        var arrForms = [FPForms]()
        for item in arrResults {
            arrForms.append(FPForms(dict: item, isForLocal: false))
        }
        if arrForms.count > 0{
            let arrIds = arrForms.map { $0.objectId ?? "0" }
            var params = [String:Any]()
            params["ids"] = arrIds
            params["ticketIds"] = [ticketId]
            self.queryInspectionFormsFor(ticketId: ticketId, params: params, mtotal: total, showLoader: false) { forms, quryTotal, error  in
                completion(forms, quryTotal, error)
            }
        }else{
            completion(arrForms, total, nil)
        }
    }

    class func upsertInspectionFormsFor(ticketId: NSNumber, forms: [FPForms], completion:@escaping (_ forms: [FPForms]?) -> ()) {
        serialQueueUpsertFPForms.async {
            FPFormsDatabaseManager().insertORUpdate(forms: forms, ticketId: ticketId) { forms in
                DispatchQueue.main.async {
                    completion(forms)
                }
            }
        }
    }
    
    
    class func queryInspectionFormsFor(ticketId: NSNumber, params:[String:Any], mtotal:Int? = 1, showLoader: Bool, completion: @escaping GetInspectionFormsCompletionBlock) {
        
        if showLoader {
            DispatchQueue.main.async {
                FPUtility.showHUDWithLoadingMessage()
            }
        }
        router.request(.queryInspectionForms(params)) { (json, _data, response, _error) in
            if _error == nil {
                guard let results = json?["result"] as? [[String: Any]] else {
                    if showLoader {
                        FPUtility.hideHUD()
                    }
                    completion([], 0, FPErrorHandler.getError(code: 401, message: FPLocalizationHelper.localize("lbl_Something_went_wrong")))
                    return
                }
                var arrForms = [FPForms]()
                for item in results {
                    arrForms.append(FPForms(dict: item, isForLocal: false))
                }
                self.upsertInspectionFormsFor(ticketId: ticketId, forms: arrForms) { forms in
                    DispatchQueue.main.async {
                        if showLoader {
                            FPUtility.hideHUD()
                        }
                        completion(arrForms, mtotal ?? 1, nil)
                    }
                }
                
            } else {
                if showLoader {
                    DispatchQueue.main.async {
                        FPUtility.hideHUD()
                    }
                }
                completion([], 0, _error)
            }
        }
    }
}
