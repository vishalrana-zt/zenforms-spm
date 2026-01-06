//
//  FPDatadogWrapper.swift
//  crm
//
//  Created by Apple on 19/04/21.
//  Copyright © 2021 SmartServ. All rights reserved.
//

import Foundation
internal import DatadogCore
internal import DatadogLogs
internal import DatadogInternal
internal import DatadogCrashReporting
import UIKit

struct FPLoggerNames {
    static let customForms = "CustomForms"
    static let dbManager = "DBManager"
    static let differentialMeta = "DifferentialMeta"
}

class FPDatadogWrapper:NSObject {
    static let shared = FPDatadogWrapper()
    private override init() {
        super.init()
    }
}

extension FPDatadogWrapper {
    
    func getMetaData(_ ddLoggerModal:FPLoggerModal) -> [AttributeKey:AttributeValue] {
        var meta = [AttributeKey:AttributeValue]()
        meta["meta.context"] = "crm"
        meta["meta.deviceType"] = UIDevice.current.model
        meta["meta.osVersion"] = UIDevice.current.systemVersion
        meta["meta.appVersion"] = FPUtility.getAppVersion()
        meta["meta.companyId"] = strCompanyId
        meta["meta.userId"] = strUserId
        meta["meta.username"] = strUserName
        meta["meta.timestamp"] = FPUtility.getUTCDateSQLiteQuery(date: Date())
        if let customAttributes = ddLoggerModal.attributes {
            for (key,value) in customAttributes {
//                if value != "" {
//                    meta["meta.\(key)"] = value
//                }
                meta["meta.\(key)"] = value as? AttributeValue
            }
        }
        return meta
    }
    func getLogger(_ ddLoggerModal:FPLoggerModal) -> LoggerProtocol  {
        let logger = Logger.create(with: Logger.Configuration(service: ddLoggerModal.serviceName, name: ddLoggerModal.loggerName, networkInfoEnabled: true, consoleLogFormat: .shortWith(prefix: "[iOS App] ")))
        return logger
    }
    
    func sendDebugLog(_ ddLoggerModal:FPLoggerModal) {
        ZenForms.shared.logDelegate?.sendDebugLog(ddLoggerModal.asDictionary())
//        logsMainDelegate?.insertOfflineLibLogsIntoDb(ddLoggerModal.asDictionary())
//        if datadogEnvironmentString == "crm-demo" || datadogEnvironmentString == "crm-prod"{
//            self.getLogger(ddLoggerModal).debug(ddLoggerModal.message, error: ddLoggerModal.error, attributes: self.getMetaData(ddLoggerModal))
//        }
    }
    
    func sendErrorLog(_ ddLoggerModal:FPLoggerModal) {
        ZenForms.shared.logDelegate?.sendErrorLog(ddLoggerModal.asDictionary())
//        logsMainDelegate?.insertOfflineLibLogsIntoDb(ddLoggerModal.asDictionary())
//        if datadogEnvironmentString == "crm-demo" || datadogEnvironmentString == "crm-prod"{
//            if ddLoggerModal.message.lowercased().contains(invalidJson.lowercased()){
//                return
//            }
//            self.getLogger(ddLoggerModal).error(ddLoggerModal.message, error: ddLoggerModal.error, attributes: self.getMetaData(ddLoggerModal))
//        }
    }
    
    
}


extension FPLoggerModal {
    func asDict(isError:Bool = false) -> [String:Any]{
        var dict = [String: Any]()
        dict["serviceType"] = self.serviceName
        dict["logType"] = isError ? "Error" : "Debug"
        dict["logEnv"] = datadogEnvironmentString
        dict["logMessage"] = self.message
        dict["createdAt"] = NSNumber(value: Date().millisecondsSince1970)
        return dict
    }
    
    func asDictionary() -> [String:Any]{
        var dict = [String: Any]()
        dict["serviceName"] = self.serviceName
        dict["loggerName"] = self.loggerName
        dict["message"] = self.message
        dict["attributes"] = self.attributes
        dict["error"] = self.error
        dict["logEnv"] = datadogEnvironmentString
        dict["createdAt"] = NSNumber(value: Date().millisecondsSince1970)
        return dict
    }
}
