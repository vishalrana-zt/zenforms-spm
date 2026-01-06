//
//  FPFormDataManager.swift
//  crm
//
//  Created by SmartServ-Kuldeep on 3/11/22.
//  Copyright © 2022 SmartServ. All rights reserved.
//
//   This class is responsible for handling data related to the specific
//  custom form for Fire protection

import Foundation
internal import SSMediaManager
import UIKit
internal import  GRDB
let hiddenAssetIdColumnKey = "assetId"
struct FPFormDataHolder{
    private var internalForm:FPForms?
    var customForm:FPForms?{
        set {
            if let fPForm = newValue{
                internalForm = fPForm
                let result = fPForm.sections?.reduce(into:([String:[FPSectionDetails]](),
                                                           [FPSectionDetails]())){ partialResult, section in

                    guard section.isHidden else {
                        var sectionFields = section.fields
                        
                        //We are adding assetID as hidden field in the section where asset is attached
                        //As it is showing an empty cell in the table so moved it at the buttom of field array
                        if let index = sectionFields
                            .firstIndex(where: {$0.getUIType() == .HIDDEN && $0.name == "assetId"}){
                            let assetField = sectionFields
                                .remove(at: index)
                            sectionFields
                                .append(assetField)
                            
                            if let assetID =  Int(assetField.value ?? "0"),assetID>0 {
                                attachedAssetIds.append(assetID)
                            }
                        }
                        section.fields = sectionFields
                        partialResult.1.append(section)
                        return }
                    guard let sectionMappingValue = section.sectionMappingValue else { return }
                    partialResult.0[sectionMappingValue,default: []]
                        .append(section)
                };
                
                hiddenSections = result?.0
                sections = result?.1
            }
        }
        get{
            if let internalForm{
                let mergedSections = getFormSectionsWithHidden()
                var customFormTemp = internalForm
                customFormTemp.sections = mergedSections
                return customFormTemp
            }
            return nil
        }
    }
    
    
    //Kept section array as in future their could be more then one  sctions for same type
    private var hiddenSections:[String:[FPSectionDetails]]?
    public var sections:[FPSectionDetails]?
    private var rows :[IndexPath:Int] = [:]
    private var tableComponents :[IndexPath:TableComponent] = [:]
    private var filesAtIndex:[IndexPath:[SSMedia]] = [:]
    public var attachedAssetIds:[Int] = []
    private var suggestionAtIndex:[IndexPath:[String]] = [:]
    private var checkListAtIndex:[IndexPath:[String:Any]] = [:]
    
    var arrLinkingDB = [AssetFormMappingData]()

    var tableMedia:[TableMedia] = []
    var tableMediaCache:[TableMedia] = [] // This is used hold table tempTable media for edit page Clear before closing edit table page

    public static var shared = FPFormDataHolder()
    
    private init(){
    }
    
    public func getFormSections() -> [FPSectionDetails] {
        return sections?.sorted(by:{$0.sortPosition ?? "" < $1.sortPosition ?? ""}) ?? []
    }
    
    public func getFormSectionsWithHidden() -> [FPSectionDetails] {
        let mergerdArray = (sections ?? []) + (hiddenSections?.values.flatMap { $0 } ??  [])
        return mergerdArray
    }
    
    public func getTemplateName()->String? {
        return (customForm?.displayName != nil) ? customForm?.name : ""
    }
    
    public func getRowForSection(_ section:Int, at index:Int) -> FPFieldDetails? {
        let fields = getFieldsIn(section: section)
        let item = fields[safe:index]
        return item
    }
    
    public func getHiddenSections(using sectionMappingValue:String)->[FPSectionDetails]{
        return hiddenSections?[sectionMappingValue] ?? []
    }
    
    public func getHiddenDynamicSections(using sectionName:String)->FPSectionDetails?{
        if let dynamicIndex = self.getFormSectionsWithHidden().firstIndex(where: {$0.name == sectionName && $0.isHidden == true}){
            return self.getFormSectionsWithHidden()[safe: dynamicIndex]
        }
        return nil
    }
    
    public func assetAddedAtSection(_ assetID:Int) -> Int?{
        if (attachedAssetIds.contains(assetID)){
        let sectionIndex = sections?.firstIndex(where: {$0.fields.contains(
                where:{$0.name == "assetId" && Int($0.value ?? "0") == assetID})})
            return sectionIndex;
        }
        return nil
        
    }
    
    public mutating func addSection(_ section:FPSectionDetails,at sectionIndex:Int,forAsset asset:[FPSectionDetails]?, assetData:AssetInspectionData, completion:@escaping (_ status:Bool)->Void) {
        var sectionOption = section.sectionOptions
        sectionOption?.removeValue(forKey:"isHidden")
        let scannerSection = sections?[sectionIndex]
        if let scannerSectionId = scannerSection?.objectId{
            sectionOption?["parentSectionId"] = scannerSectionId
        }else if let scannerSectionId = UserDefaults.currentScannerSectionId {
            sectionOption?["parentSectionId"] = scannerSectionId
        }
        UserDefaults.currentScannerSectionId = nil
        let scannerSortPosition = scannerSection?.sortPosition ?? ""
        scannerSection?.sortPosition = "\(scannerSortPosition)1"
        sections?[sectionIndex] = scannerSection!
        scannerSection?.moduleEntityLocalId = self.customForm?.sqliteId ?? 0
        FPSectionDetailsDatabaseManager().updateSectionDetails(scannerSection!)
        var sectionToInsert = section.copyFPSectionDetails(false)
        sectionToInsert.sectionOptions = sectionOption
        sectionToInsert.sortPosition = scannerSortPosition
        sectionToInsert.displayName = "\(sectionToInsert.name ?? "")(\(asset?.first?.fields.first(where: {$0.name == "serialNumber"})?.value ?? ""))"
        sectionToInsert.objectId = nil
        sectionToInsert.objectStringId = nil
        if let assetData = asset {
            let insertSectionOptions = sectionToInsert.sectionOptions
            //Auto Populate ASSET based on mapping
            if let  assetMapping = insertSectionOptions?["assetMapping"] as?[String:String] {
                assetMapping.forEach { mappingKey, mappingValue in
                    let assetField = getAssetField(assetData, forField:mappingValue)
                    if let fieldIndex = sectionToInsert.fields.firstIndex(where: {$0.name?.lowercased() == mappingKey.lowercased()}){
                        if mappingValue.lowercased() == "assetConditionId".lowercased() ||  mappingValue.lowercased() == "assetTypeId".lowercased(){
                            //if mapping value name is assetConditionId/assetTypeId then fetch value from dropdown options as asset condition/type value will be id not value.
                            let options = assetField?.getDropdownOptions()
                            if let indexItm = options?.firstIndex(where: {$0.value == assetField?.value}){
                                sectionToInsert.fields[fieldIndex].value = options?[safe:indexItm]?.label
                            }
                        }else{
                            sectionToInsert.fields[fieldIndex].value = assetField?.value
                        }
                    }
                }
            }
        }
        //Removing Fields ID and section id
        sectionToInsert.fields = sectionToInsert.fields.map({ field in
            field.objectId = nil
            field.objectStringId = nil
            field.sectionId = nil
            if field.getUIType() == .BUTTON_RADIO {
                field.reasons = stripReasonIdsFromButtonRadioField(field: field)
            }
            return field
        })
        if let assetObjectId = assetData.assetObjectId {
            sectionToInsert = self.addHiddenAssetFieldIn(sectionToInsert: sectionToInsert, assetId: assetObjectId, sortPostion: "\(sectionToInsert.fields.first?.sortPosition ?? "00")0")
        }
        if let assetID = assetData.assetObjectId?.intValue{
            attachedAssetIds.append(assetID)
        }
        sectionToInsert.isSyncedToServer = false
        FPSectionDetailsDatabaseManager().insertSectionDetails([sectionToInsert], self.customForm?.sqliteId ?? 0) { localSections in
            if let newSection = localSections.first{
                FPFormDataHolder.shared.sections?.insert(newSection, at: sectionIndex)
                FPFormDataHolder.shared.insertSectionAssetLinkIntoDB(assetData:assetData, section: newSection)
            }
            completion(true)
        }
    }
    
    func stripReasonIdsFromButtonRadioField(field:FPFieldDetails) -> String? {
        if var predefinedReasonArray = field.reasons?.getArray() as? [[String: Any]] {
            predefinedReasonArray.enumerated().forEach { (indx,reason) in
                var reason = predefinedReasonArray[indx]
                reason["id"] = nil
                predefinedReasonArray[indx] = reason
            }
            return predefinedReasonArray.getJson()
        }
        return field.reasons
    }
    
    func generateDyanmicSectionName(for sectionName:String) -> String {
        let arrSections = self.getFormSections().filter { $0.name == sectionName && $0.isHidden == false }
        if arrSections.isEmpty{
            return sectionName
        }
        let newSectionName = sectionName + " (\(arrSections.count))"
        return newSectionName
    }
    
    public mutating func addDynamicSection(_ section:FPSectionDetails, at sectionIndex:Int, completion:@escaping (_ status:Bool)->Void) {
        var sectionOption = section.sectionOptions
        sectionOption?.removeValue(forKey:"isHidden")
        let scannerSection = sections?[sectionIndex]
        if let scannerSectionId = scannerSection?.objectId{
            sectionOption?["parentSectionId"] = scannerSectionId
        }
        let scannerSortPosition = scannerSection?.sortPosition ?? ""
        scannerSection?.sortPosition = "\(scannerSortPosition)1"
        sections?[sectionIndex] = scannerSection!
        scannerSection?.moduleEntityLocalId = self.customForm?.sqliteId ?? 0
        FPSectionDetailsDatabaseManager().updateSectionDetails(scannerSection!)
        var sectionToInsert = section.copyFPSectionDetails(false)
        sectionToInsert.sectionOptions = sectionOption
        sectionToInsert.sortPosition = scannerSortPosition
//        sectionToInsert.displayName = "\(sectionToInsert.name ?? "")"
        sectionToInsert.displayName = self.generateDyanmicSectionName(for: sectionToInsert.name ?? "")
        sectionToInsert.objectId = nil
        sectionToInsert.objectStringId = nil
        
        //Removing Fields ID and section id
        sectionToInsert.fields = sectionToInsert.fields.map({ field in
            field.objectId = nil
            field.objectStringId = nil
            field.sectionId = nil
            if field.getUIType() == .BUTTON_RADIO {
                field.reasons = stripReasonIdsFromButtonRadioField(field: field)
            }
            return field
        })
       
        sectionToInsert.isSyncedToServer = false
        FPSectionDetailsDatabaseManager().insertSectionDetails([sectionToInsert], self.customForm?.sqliteId ?? 0) { localSections in
            if let newSection = localSections.first{
                FPFormDataHolder.shared.sections?.insert(newSection, at: sectionIndex)
            }
            completion(true)
        }
    }

    
    func insertSectionAssetLinkIntoDB(assetData:AssetInspectionData, section:FPSectionDetails?){
        let data = AssetFormMappingData()
        data.assetId = assetData.assetObjectId
        data.assetLocalId = assetData.assetLocalId
        data.isAssetSynced = assetData.isAssetSyncedToServer
        data.customFormId = FPUtility.getNumberValue(FPFormDataHolder.shared.customForm?.objectId)
        data.customFormLocalId = FPFormDataHolder.shared.customForm?.sqliteId ?? 0
        data.formTemplateId = FPFormDataHolder.shared.customForm?.templateId ?? "0"
        data.sectionTemplateId = section?.templateId
        data.sectionLocalId  = section?.sqliteId
        data.sectionId  = section?.objectId
        data.isSyncedToServer = false
        data.addLinking = false
        data.sectionLinking = true
        data.deleteLinking = false
        data.isNotConfirmed = true
        if FPFormDataHolder.shared.customForm?.sqliteId == nil{
            FPFormDataHolder.shared.arrLinkingDB.append(data)
        }else{
            AssetFormLinkingDatabaseManager().insertSectionAsset(item: data) { success in }
        }
    }
    
    func addHiddenAssetFieldIn(sectionToInsert:FPSectionDetails, assetId:NSNumber, sortPostion:String) -> FPSectionDetails{
        let sectionUpdated = sectionToInsert
        let hiddenField  = self.getHiddenAssetField(assetId: assetId, sortPostion: sortPostion)
        sectionUpdated.fields.append(hiddenField)
        return sectionUpdated
    }
    
    func getHiddenAssetField(assetId:NSNumber, sortPostion:String) -> FPFieldDetails{
        let hiddenField  = FPFieldDetails()
        hiddenField.dataType = "TEXT"
        hiddenField.displayName  = "Asset ID"
        hiddenField.mandatory = false
        hiddenField.readOnly = true
        hiddenField.name = "assetId"
        hiddenField.uiType = "HIDDEN"
        hiddenField.value = assetId.stringValue
        hiddenField.sortPosition = sortPostion
        return hiddenField
    }
    
    public mutating func updateAssetSection(_ section:FPSectionDetails,at sectionIndex:Int,forAsset asset:[FPSectionDetails]?,assetObjectId:NSNumber?,completion:@escaping (_ error:Error?,_ response:Any?)->Void) {
        var sectionOption = section.sectionOptions
        sectionOption?.removeValue(forKey:"isHidden")
        let prevSection = sections?[sectionIndex]
        let prevSectionFields = prevSection?.fields.count ?? 0
        //remove if any table exist at same index
        for fieldIndex in(0 ..< prevSectionFields){
            if let field = prevSection?.fields[safe:fieldIndex], field.getUIType() == .TABLE || field.getUIType() == .TABLE_RESTRICTED{
                let tblIndex = IndexPath(row: fieldIndex, section: sectionIndex)
                self.removeTableComponentAt(index: tblIndex)
            }
        }
        if let prevAssetField = prevSection?.fields
            .first(where: {$0.name == "assetId" && $0.getUIType() == .HIDDEN}){
            if let prevAssetID =  Int(prevAssetField.value ?? "0"),prevAssetID>0 {
                attachedAssetIds.removeObject(prevAssetID)
            }
        }
        let prevSectionPosition = prevSection?.sortPosition ?? ""
        let prevSectionID = prevSection?.objectId
        var formDeletedSections = self.customForm?.deletedSections?.components(separatedBy: ",") ?? []
        if let deletedID = prevSectionID?.stringValue {
            formDeletedSections.append(deletedID)
        }
        self.customForm?.deletedSections = formDeletedSections.joined(separator: ",")
        let sectionsTOdelete = [prevSection!]
        FPSectionDetailsDatabaseManager()
            .deleteSectionDetails(forArray: sectionsTOdelete)
        var sectionToInsert = section.copyFPSectionDetails(false)
        if let scannerSectionId = prevSection?.sectionOptions?["parentSectionId"]{
            sectionOption?["parentSectionId"] = scannerSectionId
        }else if let scannerSectionId = UserDefaults.currentScannerSectionId{
            sectionOption?["parentSectionId"] = scannerSectionId
        }
        UserDefaults.currentScannerSectionId = nil
        sectionToInsert.sectionOptions = sectionOption
        sectionToInsert.sortPosition = prevSectionPosition
        sectionToInsert.objectId = nil
        sectionToInsert.objectStringId = nil
        sectionToInsert.displayName = "\(sectionToInsert.name ?? "")(\(asset?.first?.fields.first(where: {$0.name == "serialNumber"})?.value ?? ""))"
        if let assetData = asset {
            let insertSectionOptions = sectionToInsert.sectionOptions
            //Auto Populate ASSET based on mapping
            if let  assetMapping = insertSectionOptions?["assetMapping"] as?[String:String] {
                assetMapping.forEach { mappingKey, mappingValue in
                    let assetField = getAssetField(assetData, forField:mappingValue)
                    if let fieldIndex = sectionToInsert.fields.firstIndex(where: {$0.name?.lowercased() == mappingKey.lowercased()}){
                        if mappingValue.lowercased() == "assetConditionId".lowercased() ||  mappingValue.lowercased() == "assetTypeId".lowercased(){
                            //if mapping value name is assetConditionId/assetTypeId then fetch value from dropdown options as asset condition/type value will be id not value.
                            let options = assetField?.getDropdownOptions()
                            if let indexItm = options?.firstIndex(where: {$0.value == assetField?.value}){
                                sectionToInsert.fields[fieldIndex].value = options?[safe:indexItm]?.label
                            }
                        }else{
                            sectionToInsert.fields[fieldIndex].value = assetField?.value
                        }
                    }
                }
            }
        }
        sectionToInsert.fields = sectionToInsert.fields.map({ field in
            field.objectId = nil
            field.objectStringId = nil
            field.sectionId = nil
            if field.getUIType() == .BUTTON_RADIO {
                field.reasons = stripReasonIdsFromButtonRadioField(field: field)
            }
            return field
        })
        if let assetObjectId {
            sectionToInsert = self.addHiddenAssetFieldIn(sectionToInsert: sectionToInsert, assetId: assetObjectId, sortPostion: "\(sectionToInsert.fields.first?.sortPosition ?? "00")0")

        }
        sections?.remove(at: sectionIndex)

        sectionToInsert.isSyncedToServer = false
        FPSectionDetailsDatabaseManager()
            .insertSectionDetails(
                [sectionToInsert],
                internalForm?.sqliteId ?? 0) { section in
                    FPFormDataHolder.shared.sections?.insert(contentsOf: section, at: sectionIndex)
                    completion(nil, section.first)
                }
       
    }

    private func getAssetField(_ asset:[FPSectionDetails],forField field:String) -> FPFieldDetails? {
        var assetField : FPFieldDetails?
        asset.forEach { section in
             assetField = section.fields
                .first(where: { $0.name?.lowercased() == field.lowercased()})
        }
        
        return assetField
    }
        
    public func getSection(at index:Int)-> FPSectionDetails?{
        return getFormSections()[safe:index]
    }
    
    public func getScannebleSection() -> FPSectionDetails?{
        return sections?.first(where: {$0.fields.contains(where: {$0.scannable})})
    }
    
    public func getFieldsIn(section:Int)->[FPFieldDetails]{
        let section = getFormSections()[safe: section]
        return section?.fields ?? []
    }
    
    public func getSectionCount()->Int{
        return getFormSections().count
    }
    
    public func getFieldsCountFor(section:Int)->Int{
        return getFieldsIn(section: section).count
    }
    
    public mutating func saveFilesForOfflineSupport(){
        filesAtIndex.forEach { item in
            var dict = [[String:Any]]()
            item.value.forEach { media in
                dict.append(["name": media.name, "filePath": media.filePath,
                             "templateId": media.templateId, "mimeType": media.mimeType, "section": item.key.section,
                             "row": item.key.row, "id": media.id, "serverUrl": media.serverUrl])
            }
            updateRowWith(value: dict.getJson(), inSection: item.key.section, atIndex: item.key.row)
        }
    }
    
    public mutating func saveFilesForOfflineSupportPartialSection(sectionfiledFiles:[IndexPath:[SSMedia]]){
        sectionfiledFiles.forEach { item in
            var dict = [[String:Any]]()
            item.value.forEach { media in
                dict.append(["name": media.name, "filePath": media.filePath,
                             "templateId": media.templateId, "mimeType": media.mimeType, "section": item.key.section,
                             "row": item.key.row, "id": media.id, "serverUrl": media.serverUrl])
            }
            updateRowWith(value: dict.getJson(), inSection: item.key.section, atIndex: item.key.row)
        }
    }
    
    fileprivate mutating func addFileItem(_ item: [String : Any]) {
        if let section = item["section"] as? Int, let row = item["row"] as? Int, let name = item["name"] as? String, let serverUrl = item["serverUrl"] as? String, let id = item["id"] as? String {
            let indexPath = IndexPath.init(row: row, section: section)
            let ssMedia = SSMedia.init(name: name, id: id, serverUrl: serverUrl, moduleType: .forms)
            if !(filesAtIndex[indexPath]?.contains(ssMedia) ?? false) {
                addFileAt(index: indexPath, withMedia: ssMedia)
            }
        } else if let section = item["section"] as? Int, let row = item["row"] as? Int, let name = item["name"] as? String, let mimeType = item["mimeType"] as? String, let templateId = item["templateId"] as? String{
            let indexPath = IndexPath.init(row: row, section: section)
            let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsUrl.appendingPathComponent(name)
            let ssMedia = SSMedia.init(name: name, mimeType: mimeType, filePath: fileURL.path, templateId: templateId, serverUrl: item["file"] as? String, moduleType: .forms)
            if !(filesAtIndex[indexPath]?.contains(ssMedia) ?? false) {
                addFileAt(index: indexPath, withMedia: ssMedia)
            }
        }else if let section = item["section"] as? Int, let row = item["row"] as? Int, let name = item["name"] as? String, let mimeType = item["mimeType"] as? String, let filePath = item["filePath"] as? String{
            let indexPath = IndexPath.init(row: row, section: section)
            let ssMedia = SSMedia.init(name: name, mimeType: mimeType, filePath: filePath, moduleType: .forms)
            if !(filesAtIndex[indexPath]?.contains(ssMedia) ?? false) {
                addFileAt(index: indexPath, withMedia: ssMedia)
            }
        }
    }
    
    public mutating func getFilesFromValue(form: FPForms){
        self.getFormSections().enumerated().forEach({ (sectionIndex,item) in
            if let item = item as? FPSectionDetails {
                let section = item
                section.fields.enumerated().forEach {(fieldIndex, fieldDetails) in
                    let indexPath = IndexPath(row:fieldIndex, section: sectionIndex)

                    if fieldDetails.getUIType() == .FILE {
                        (fieldDetails.value?.getArray() as? [[String:Any]])?.forEach { item in
                            addFileItem(item)
                        }
                    }else if fieldDetails.getUIType() == .BUTTON_RADIO {
                        (fieldDetails.attachments?.getArray() as? [[String:Any]])?.forEach { item in
                            addFileItem(item)
                        }
                    }else if  fieldDetails.getUIType() == .SIGNATURE_PAD && fieldDetails.value != nil {
                        if let fileDict  = fieldDetails.value?.getArray() as? [[String:Any]]{
                            fileDict.forEach { item in
                                addFileItem(item)
                            }
                        }else {
                            var media: SSMedia
                            if(fieldDetails.value!.contains("https")){
                                media  = SSMedia.init(name:"signature.png",serverUrl: fieldDetails.value!, moduleType: .forms)
                            }else{
                                media  = SSMedia.init(name:"signature.png",filePath: fieldDetails.value!, moduleType: .forms)
                            }
                            if !(filesAtIndex[indexPath]?.contains(media) ?? false) {
                                addFileAt(index: indexPath, withMedia: media)
                            }
                        }
                    }else if fieldDetails.getUIType() == .TABLE || fieldDetails.getUIType() == .TABLE_RESTRICTED {
                        let tableOptions = fieldDetails.getTableOptions(strJson: fieldDetails.options ?? "")
                        let tableComponent = TableComponent().prepareData(item: tableOptions ?? TableOptions(), values: fieldDetails.value,index: indexPath, fieldDetails: fieldDetails, customForm: form)
                        tableComponent.rows?.enumerated().forEach({ (rowIndex, row) in
                            row.columns.enumerated().forEach { (columnIndex, data) in
                                if(data.uiType == "ATTACHMENT"){
                                   let dataObject = data.value.getDictonary()
                                   if(!dataObject.isEmpty){
                                           if let files =  dataObject["filesToUpload"] as? [[String:Any]],!files.isEmpty{
                                               var mediasAdded:[SSMedia] = []
                                               files.forEach { file in
                                                   if((tableMedia.first(where: {$0.mediaAdded.contains(where: {$0.name == file["altText"] as? String ?? "" })})) == nil){
                                                       
                                                       let mediaAdded = SSMedia(name:file["altText"] as? String ?? "",mimeType:file["type"] as? String ?? "",filePath: file["localPath"] as? String ?? "", moduleType: .forms)
                                                       mediasAdded.append(mediaAdded)
                                                   }
                                               }
                                               if mediasAdded.count>0{
                                                   if let mediaIndex = tableMedia.firstIndex(where: {$0.parentTableIndex == indexPath && $0.childTableIndex == IndexPath(row: columnIndex, section: rowIndex+1)}){
                                                       var tableMedia = tableMedia[mediaIndex]
                                                       tableMedia.mediaAdded = mediasAdded
                                                       updateTableFieldValue(media: tableMedia)
                                                       
                                                   }else{
                                                       let tableMedia = TableMedia(columnIndex: columnIndex,key:data.key,parentTableIndex: indexPath,childTableIndex:  IndexPath(row: columnIndex, section: rowIndex+1), mediaAdded: mediasAdded, mediaDeleted: [])
                                                       updateTableFieldValue(media: tableMedia)
                                                   }
                                               }
                                               
                                           }
                                       }
                                   }
                               
                            }
                        })
                        
                    }
                }
            }
        })
        
    }
    
    private mutating func updateFieldFiles(
        files: [SSMedia]?,
        inSection section:Int,
        atIndex index:Int
    ){
        var sections = getFormSections()
        if let files = files, let sectionObject = sections[safe:section]{
            var sectionFields = sectionObject.fields
            if let tmpfield = sectionFields[safe: index]{
                let field = tmpfield
                if(field.getUIType() == .SIGNATURE_PAD){
                    if files.isEmpty{
                        field.value = ""
                    }else{
                        if let serverUrl = files.first?.serverUrl{
                            field.value = serverUrl
                        }else if let localPath = files.first?.filePath{
                            field.value = localPath
                        }
                    }
                }else{
                    field.files = files
                }
                sectionFields[index] = field
            }
            sectionObject.fields = sectionFields
            sections[section] = sectionObject
            self.sections = sections
        }
    }
    
    private mutating func updateFileToRemove(
        file: String,
        inSection section:Int,
        atIndex index:Int
    ){
        var sections = getFormSections()
        if  let sectionObject = sections[safe:section]{
            var sectionFields = sectionObject.fields
            let field = sectionFields[index]
            field.deletedFiles.append(file)
            sectionFields[index] = field
            sectionObject.fields = sectionFields
            sections[section] = sectionObject
            self.sections = sections
            
        }
    }
    
    public mutating func updateServerUrl(url: String, key: IndexPath, index: Int){
       var media  =  filesAtIndex[key]?[index]
        media?.serverUrl = url
        media?.filePath =  nil
        filesAtIndex[key]?[index] = media!
        updateFieldFiles(files: filesAtIndex[key], inSection: key.section, atIndex: key.row)
    }
    
    public mutating func updateFieldOptions(
        options:String,
        inSection section:Int,
        atIndex index:Int
    ){
        var sections = getFormSections()
        let sectionObject = sections[section]
        var sectionFields = sectionObject.fields
        let field = sectionFields[index]
        field.options = options
        sectionFields[index] = field
        sectionObject.fields = sectionFields
        sections[section] = sectionObject
        self.sections = sections
    }
    
    public mutating func updateRowWith(value:String,inSection section:Int, atIndex index:Int,reloadSummary:((_ index:IndexPath)->Void)? = nil){
        var sections = getFormSections()
        let sectionObject = sections[safe:section]
        var sectionFields = sectionObject?.fields
        if let field = sectionFields?[safe:index]{
            if(field.getUIType() == .BUTTON_RADIO){
                field.value = "NO"
                let arrFiles = value.getArray()
                var dict = [[String:Any]]()
                arrFiles.forEach { dictFile in
                    dict.append(["altText" : dictFile["name"] as? String ?? nil,
                                 "name" : dictFile["name"] as? String ?? nil,
                                 "id" : dictFile["id"] as? String ?? nil,
                                 "serverUrl" : dictFile["serverUrl"] as? String ?? nil,
                                 "filePath" : dictFile["filePath"] as? String ?? nil,
                                 "mimeType" : dictFile["mimeType"] as? String ?? nil,
                                 "templateId" : dictFile["templateId"] as? String ?? nil,
                                 "section": dictFile["section"] as? Int ?? nil,
                                 "row": dictFile["row"] as? Int ?? nil])
                }
                field.attachments = dict.getJson()
            }else if(field.getUIType() == .DROPDOWN){
                field.value = value
//                var valueString = value
//                if valueString.replacingOccurrences(of: " ", with: "") != ""{
//                    var options = field.options?.getDictonary()
//                    var dropDownDict = options?["dropdownOptions"] as? [[String:Any]]
//                    if dropDownDict?.contains(where: {$0["value"] as? String == value}) == false{
//                        dropDownDict?.append(["key":value,"value":value,"label":value])
//                        options?["dropdownOptions"] = dropDownDict
//                        field.options = options?.getJson()
//                    }
//                }
            }else if (field.getUIType() == .TABLE) || (field.getUIType() == .TABLE_RESTRICTED){
                field.value = value
            }else{
                field.value = value
            }
            sectionFields![index] = field
            sectionObject!.fields = sectionFields!
            sections[section] = sectionObject!
            self.sections = sections
        }
    }
    
    public func getValue(inSection section:Int, atIndex index:Int)->String?{
        let sections = getFormSections()
        let sectionObject = sections[safe:section]
        let sectionFields = sectionObject?.fields
        if let field = sectionFields?[safe:index]{
            return field.value
        }
        return nil
    }
    
    public func getFieldTemplateId(inSection section:Int, atIndex index:Int)->String?{
        let sections = getFormSections()
        let sectionObject = sections[safe:section]
        let sectionFields = sectionObject?.fields
        if let field = sectionFields?[safe:index]{
            return field.templateId
        }
        return nil
    }
    
    public mutating func updateRowWith(date:Date,inSection section:Int, atIndex index:Int){
        let value = FPUtility.getStringWithTZFormat(date) ?? ""
        updateRowWith(value: value, inSection: section, atIndex: index)
    }
    
    
    public mutating func updateRowWith(
        reasons:String,
        value:String,
        inSection section:Int,
        atIndex index:Int
    ){
        var sections = getFormSections()
        if  let sectionObject = sections[safe:section]{
            var sectionFields = sectionObject.fields
            if var field = sectionFields[safe:index]{
                field.value = value
                field.reasons = reasons
                sectionFields[index] = field
            }
            sectionObject.fields = sectionFields
            sections[section] = sectionObject
            self.sections = sections
        }
    }
    
    public func isFormAnalysed()->Bool{
        return customForm?.isAnalysed ?? false
    }
    
    mutating func addRowAT(index:IndexPath){
        if let row = rows[index]{
            rows[index] = row+1
        }else{
            rows[index] = 1
        }
    }
    private mutating func addUpdateTableMedia( media:inout TableMedia){
        var mediaObject =  media
        if let index = tableMedia.firstIndex(where: {$0.parentTableIndex == media.parentTableIndex && $0.childTableIndex == media.childTableIndex && $0.columnIndex == media.columnIndex}){
            let tblMedia = tableMedia[index]
            if(tblMedia.mediaDeleted.count>0&&mediaObject.mediaDeleted.count == 0){
                mediaObject.mediaDeleted = tblMedia.mediaDeleted
            }else{
                var mediaAdded = mediaObject.mediaAdded
                let existingDeletedMedia =  tblMedia.mediaDeleted.filter({!mediaObject.mediaDeleted.contains($0)});
                mediaAdded.append(contentsOf: existingDeletedMedia)
            }
            tableMedia.remove(at: index)
        }
        media = mediaObject
        tableMedia.append(mediaObject)
    }
    
    mutating func addUpdateTableMediaCache(media: TableMedia){
        var mediaObject =  media
        if let index = tableMediaCache.firstIndex(where: {$0.parentTableIndex == media.parentTableIndex && $0.childTableIndex == media.childTableIndex && $0.columnIndex == media.columnIndex}){
            let tblMedia = tableMediaCache[index]
            if(tblMedia.mediaDeleted.count>0&&mediaObject.mediaDeleted.count == 0){
                mediaObject.mediaDeleted = tblMedia.mediaDeleted
            }else{
                var mediaAdded = mediaObject.mediaAdded
                let existingDeletedMedia =  tblMedia.mediaDeleted.filter({!mediaObject.mediaDeleted.contains($0)});
                mediaAdded.append(contentsOf: existingDeletedMedia)
            }
            tableMediaCache.remove(at: index)
        }
        self.tableMediaCache.append(mediaObject)
    }
    
    mutating func getValueFromTableMedia(tableMedia:TableMedia,tableValues:[[String:Any]]?)->(valueArray:[[String:Any]],columnValue:String)?{
        let mediaObjct = tableMedia
        var columnValue = ""
        if var valueArray = tableValues{
            var rowValue:[String:Any] = [:]
            if(valueArray.count>tableMedia.childTableIndex!.section-1){
                rowValue = valueArray[tableMedia.childTableIndex!.section-1]
            }
            var mediaDict:[String:Any]
            if let  mediaObject = rowValue[tableMedia.key!] as? String{
                 mediaDict = mediaObject.getDictonary()
            }else{
                mediaDict = (rowValue[mediaObjct.key!] as? [String:Any]) ?? [:]
            }
            var mediaAddedDicts:[[String:Any]] = []
            mediaObjct.mediaAdded.forEach { media in
                var mediaDict:[String:Any] = [:]
                mediaDict["altText"] =  media.name
                mediaDict["file"] =  media.serverUrl ?? ""
                mediaDict["localPath"] =  media.filePath ?? ""
                mediaDict["type"] =  media.mimeType ?? ""
                mediaAddedDicts.append(mediaDict)
            }
            mediaDict["filesToUpload"] = mediaAddedDicts
            mediaDict["filesToDelete"] = mediaObjct.mediaDeleted.compactMap({$0.id})
            if var files = mediaDict["files"] as? [[String:Any]]{
                let tempFile = files
                _ = 0
                tempFile.forEach { file in
                    if(mediaObjct.mediaDeleted.contains(where: {$0.id == file["id"] as? String ?? ""})){
                        if let fileIndex = files.firstIndex(where: {$0["id"] as! String ==  file["id"] as! String}){
                            files.remove(at:fileIndex)
                        }
                    }
                }
                mediaDict["files"] = files
            }
        
            rowValue[tableMedia.key!] = mediaDict
            columnValue = mediaDict.getJson()
            if (valueArray.count>tableMedia.childTableIndex!.section-1){
                valueArray[tableMedia.childTableIndex!.section-1] = rowValue
            }else{
                valueArray.append(rowValue)
            }
            return (valueArray,columnValue)
        }
        return nil
    }
    
    mutating func updateTableFieldValue(media:TableMedia,isPostUpload:Bool = false){
        var mediaObjct = media
        addUpdateTableMedia(media: &mediaObjct)
        var sections = getFormSections()
        if var sectionObject = sections[safe:mediaObjct.parentTableIndex!.section]{
            var sectionFields = sectionObject.fields
            if let field = sectionFields[safe:mediaObjct.parentTableIndex!.row]{
                if(field.getUIType() == .TABLE || field.getUIType() == .TABLE_RESTRICTED){
                    var  tempValue = field.value
                    if var valueArray = tempValue?.getArray(){
                        var rowValue:[String:Any] = [:]
                        if(valueArray.count>mediaObjct.childTableIndex!.section-1){
                            rowValue = valueArray[safe:mediaObjct.childTableIndex!.section-1] ?? [:]
                        }
                        var mediaDict = [String:Any]()
                        if let  mediaObject = rowValue[mediaObjct.key!] as? String{
                             mediaDict = mediaObject.getDictonary()
                        }else{
                            mediaDict = (rowValue[mediaObjct.key!] as? [String:Any]) ?? [:]
                        }
                        var mediaAddedDicts:[[String:Any]] = []
                        mediaObjct.mediaAdded.forEach { media in
                            var mediaDict:[String:Any] = [:]
                            mediaDict["altText"] =  media.name
                            mediaDict["file"] =  media.serverUrl ?? ""
                            if(isPostUpload){
                                mediaDict.removeValue(forKey:"localPath")
                            }else{
                                mediaDict["localPath"] =  media.filePath ?? ""
                            }
                            mediaDict["type"] =  media.mimeType ?? ""
                            mediaAddedDicts.append(mediaDict)
                        }
                        mediaDict["filesToUpload"] = mediaAddedDicts
                        mediaDict["filesToDelete"] = mediaObjct.mediaDeleted.compactMap({$0.id})
                        if var files = mediaDict["files"] as? [[String:Any]]{
                            let tempFile = files
                            _ = 0
                            tempFile.forEach { file in
                                if(mediaObjct.mediaDeleted.contains(where: {$0.id == file["id"] as? String ?? ""})){
                                    if let fileIndex = files.firstIndex(where: {$0["id"] as! String ==  file["id"] as! String}){
                                        files.remove(at:fileIndex)
                                    }
                                }
                            }
                            mediaDict["files"] = files
                        }
                    
                        rowValue[media.key!] = mediaDict
                        if(valueArray.count>mediaObjct.childTableIndex!.section-1){
                            valueArray[mediaObjct.childTableIndex!.section-1] = rowValue
                        }else{
                            valueArray.append(rowValue)
                        }
                        if let component  = tableComponents[mediaObjct.parentTableIndex!]{
                            component.values = valueArray
                            var rowIndex = mediaObjct.childTableIndex!.section-1
                            if(component.rows!.count <= rowIndex) {
                                rowIndex -= 1
                            }
                            var row = component.rows![rowIndex]
                            if let columnIndex = row.columns.firstIndex(where: {$0.key == media.key}){
                                var column  = row.columns[columnIndex]
                                column.value = mediaDict.getJson()
                                row.columns[columnIndex] = column
                            }
                            component.rows![rowIndex] = row
                            tableComponents[mediaObjct.parentTableIndex!] = component
                        }
                        tempValue = valueArray.getJson()
                    }
                    field.value = tempValue
                }
                sectionFields[media.parentTableIndex!.row] = field
            }
            sectionObject.fields = sectionFields
            sections[media.parentTableIndex!.section] = sectionObject
        }
        self.sections = sections
    }
    
    mutating func clearFileAt(index:IndexPath){
        if filesAtIndex[index] != nil {
            filesAtIndex[index] = nil
        }
    }
    
    mutating func addFileAt(index:IndexPath,withMedia media:SSMedia){
        if filesAtIndex[index] == nil {
            filesAtIndex[index] = [media]
        } else {
            if let mediaId = media.id, !mediaId.trim.isEmpty{
                var files = filesAtIndex[index]
                if let mediaIndex = files?.firstIndex(where: {$0.serverUrl == media.serverUrl}){
                    files?[mediaIndex] = media
                    filesAtIndex[index] = files
                }else{
                    filesAtIndex[index]?.append(media)
                }
            }else{
                var arrNames = filesAtIndex[index]?.map({ $0.name })
                if !(arrNames?.contains(media.name) ?? false){
                    filesAtIndex[index]?.append(media)
                }
            }
        }
        updateFieldFiles(files: filesAtIndex[index], inSection: index.section, atIndex: index.row)
    }

    
    func getFiledFilesArray() -> [IndexPath:[SSMedia]] {
        return filesAtIndex
    }
    
    func getFiledSuggestionArray() -> [IndexPath:[String]] {
        return suggestionAtIndex
    }
    
    func getFiledCheckListArray() -> [IndexPath:[String:Any]] {
        return checkListAtIndex
    }
    
    //MARK: TODO - Need to Test this multiple section with multiple attachment files
    
    func getFiledFilesArrayForSection(section:Int) -> [IndexPath:[SSMedia]] {
        return filesAtIndex.filter({$0.key.section == section})
    }
    
    mutating func clearFiledFilesArray(){
        filesAtIndex.removeAll()
    }
    
    mutating func resetData(){
        rows.removeAll()
        tableComponents.removeAll()
        tableMedia.removeAll()
        filesAtIndex.removeAll()
    }
    
    mutating func removeMediaAt(indexPath: IndexPath, index: Int){
        if let media = filesAtIndex[indexPath]?[index], media.filePath == nil, let id = media.id{
            updateFileToRemove(file: id, inSection: indexPath.section, atIndex: indexPath.row)
        }
        filesAtIndex[indexPath]?.remove(at: index)
        updateFieldFiles(files: filesAtIndex[indexPath], inSection: indexPath.section, atIndex: indexPath.row)
    }
    mutating func removeMediaAt(indexPath: IndexPath){
        filesAtIndex[indexPath]?.removeAll()
    }
    
    mutating func removeRowAT(index:IndexPath){
        if let row = rows[index] {
            if(row > 1){
                rows[index] = row-1
            }
        }else{
            rows[index] = 1
        }
    }
    
    mutating func addTableComponentAt(index:IndexPath,component:TableComponent){
        
        tableComponents[index] = component
    }
    
    mutating func getRowsAt(index:IndexPath)->Int{
        if let row = rows[index]{
            return row
        }else{
            rows[index] = 1
            return 1
        }
    }
    
    func getTableComponentAt(index:IndexPath)->TableComponent?{
        return tableComponents[index]
    }
    
    mutating func removeTableComponentAt(index:IndexPath){
        if let _ = tableComponents[index]{
            tableComponents.removeValue(forKey: index)
        }
    }
    
    mutating func getProcessedForm(isNew:Bool,form:FPForms? = nil)->FPForms?{
        if(form != nil){ customForm = form}
        if let customForm = customForm {
            let sections = getFormSectionsWithHidden()
            var tempSections = sections
            sections.enumerated().forEach { (index,section) in
                let tempSection = section
                var tempFields = section.fields
                section.fields.enumerated().forEach { (fieldIndex,field) in
                    let tempField = field
                    if(field.reasons != nil){
                        if let reasons = field.reasons?.getArray(){
                            var tempReason = reasons
                            reasons.enumerated().forEach { (index,dict) in
                                if(dict["id"] != nil){
                                    let tempID = dict["id"]
                                    var tempDict =  dict
                                    if(isNew){
                                        tempDict.removeValue(forKey: "id")
                                        if tempDict["reasonTemplateId"] == nil {
                                            tempDict["reasonTemplateId"] = tempID
                                        }
                                    } else {
                                        if let objectId = tempID as? String {
                                            tempDict["id"] = Int(objectId)
                                        } else if let objectId = tempID as? NSNumber {
                                            tempDict["id"] = objectId
                                        } else {
                                            tempDict["id"] = tempID
                                        }
                                    }
                                    tempReason[index] = tempDict
                                }
                            }
                            tempField.reasons = tempReason.getJson()
                        }
                    }
                    tempFields[fieldIndex] = tempField
                }
                tempSection.fields = tempFields
                tempSections[index] = tempSection
            }
            customForm.sections =  tempSections
            return customForm
        }
        return nil
    }
    
    
    func getProcessedSection(sectionIndex:Int)->FPSectionDetails?{
        let tempSection = getSection(at: sectionIndex)
        var tempFields = tempSection?.fields
        tempSection?.fields.enumerated().forEach { (fieldIndex,field) in
            let tempField = field
            if(field.reasons != nil){
                if let reasons = field.reasons?.getArray(){
                    var tempReason=reasons
                    reasons.enumerated().forEach { (index,dict) in
                        if(dict["id"] != nil){
                            let tempID = dict["id"]
                            var tempDict =  dict
                            if let objectId = tempID as? String {
                                tempDict["id"] = Int(objectId)
                            } else if let objectId = tempID as? NSNumber {
                                tempDict["id"] = objectId
                            } else {
                                tempDict["id"] = tempID
                            }
                            tempReason[index] = tempDict
                        }
                    }
                    tempField.reasons = tempReason.getJson()
                }
            }
            tempFields?[fieldIndex] = tempField
        }
        tempSection?.fields = tempFields ?? []
        return tempSection
    }
    
    mutating func saveAiSuggestion(suggestion:[String],indexPath:IndexPath){
        suggestionAtIndex[indexPath] = suggestion
    }
    
    mutating func removeAiSuggestion(indexPath:IndexPath){
        if let index = suggestionAtIndex.firstIndex(where: {$0.key == indexPath}){
            suggestionAtIndex.remove(at: index)
        }
    }
    
    mutating func saveAiCheckList(checkList:[String:Any],indexPath:IndexPath){
        checkListAtIndex[indexPath] = checkList
    }
    
    mutating func removeAiCheckList(indexPath:IndexPath){
        if let index = checkListAtIndex.firstIndex(where: {$0.key == indexPath}){
            checkListAtIndex.remove(at: index)
        }
    }
    
    mutating func reset(){
        customForm = nil
        rows = [:]
        filesAtIndex = [:]
        tableComponents = [:]
        tableMedia.removeAll()
        arrLinkingDB.removeAll()
        //        image = nil
    }
    
    
}

struct ColumnFormula:Codable{
    var name:String?
    var expression:String?
}

struct TableMedia{
    var columnIndex:Int?
    var key:String? = ""
    var parentTableIndex:IndexPath?
    var childTableIndex:IndexPath?
    var mediaAdded:[SSMedia]
    var mediaDeleted:[SSMedia]
}

class TableOptions: NSObject, Codable, FetchableRecord, PersistableRecord  {
    var columns: [Columns]?
    var formulas: [ColumnFormula]?
    var isAssetTable: Bool?
    var assetMapping: [String:String]?
    enum CodingKeys: String, CodingKey {
        case columns = "columns"
        case isAssetTable = "isAssetTable"
        case assetMapping = "assetMapping"
        case formulas = "formulas"
    }
}

class Columns: NSObject, Codable, FetchableRecord, PersistableRecord {
    let name: String
    let displayName: String
    let uiType: String
    let dataType: String
    let columnOptions: ColumnOptions?
    let defaultValue:String?
    let readonly:Bool?
    let scannable:Bool?
    let isPartOfFormula:Bool?

    enum CodingKeys: String, CodingKey {
        case name
        case displayName
        case uiType
        case dataType
        case columnOptions
        case defaultValue
        case readonly
        case scannable
        case isPartOfFormula
    }
}

class ColumnOptions: NSObject, Codable, FetchableRecord, PersistableRecord {
    let dropdownOptions: [DropdownOptions]?
    let dateFormat: String?
    let generateDynamically:Bool?

    enum CodingKeys: String, CodingKey {
        case dropdownOptions
        case dateFormat
        case generateDynamically
    }
}
