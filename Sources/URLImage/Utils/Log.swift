//
//  Log.swift
//  
//
//  Created by Dmytro Anokhin on 24/11/2019.
//

import os.log


private func log(_ object: Any? = nil, _ message: String, type osLogType: OSLogType = .default) {
    if let object = object {
        let typeString = String(reflecting: type(of: object))
        os_log("[%@] %@", log: .default, type: osLogType, typeString, message)
    }
    else {
        os_log("%@", log: .default, type: osLogType, message)
    }
}

func log_info(_ object: Any?, _ message: String) {
    log(object, message, type: .info)
}

func log_debug(_ object: Any?, _ message: String) {
    log(object, message, type: .debug)
}

func log_error(_ object: Any?, _ message: String) {
    log(object, message, type: .error)
}

func log_fault(_ object: Any?, _ message: String) {
    log(object, message, type: .fault)
}
