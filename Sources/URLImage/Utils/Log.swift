//
//  Log.swift
//  
//
//  Created by Dmytro Anokhin on 24/11/2019.
//

import os.log

let log_none = Int.min
let log_default = 1
let log_normal = 2
let log_detailed = 3
let log_all = Int.max

fileprivate let log_detail = log_none


@inline(__always)
private func log(_ object: Any? = nil, _ message: String, type osLogType: OSLogType = .default) {
    if let object = object {
        let typeString = String(reflecting: type(of: object))
        os_log("[%@] %@", log: .default, type: osLogType, typeString, message)
    }
    else {
        os_log("%@", log: .default, type: osLogType, message)
    }
}

@inline(__always)
func log_info(_ object: Any?, _ message: String) {
    log(object, message, type: .info)
}

@inline(__always)
func log_debug(_ object: Any?, _ message: String, detail: Int = log_default) {
    guard detail < log_detail else {
        return
    }

    log(object, message, type: .debug)
}

@inline(__always)
func log_error(_ object: Any?, _ message: String) {
    log(object, message, type: .error)
}

@inline(__always)
func log_fault(_ object: Any?, _ message: String) {
    log(object, message, type: .fault)
}
