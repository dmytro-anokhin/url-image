//
//  Log.swift
//  
//
//  Created by Dmytro Anokhin on 16/10/2020.
//

import Foundation
import os.log

public let log_default = 1
public let log_normal = 2
public let log_detailed = 3

let log_none = Int.min
let log_all = Int.max

private let log_detail = log_none


@inline(__always)
private func log(_ object: Any? = nil, _ function: String?, _ message: String?, type osLogType: OSLogType = .default) {
    switch (object, function, message) {

        case (.some(let object), .some(let function), .some(let message)):
            let typeString = String(reflecting: type(of: object))
            os_log("[%@] (%@) %@", log: .default, type: osLogType, typeString, function, message)

        case (.some(let object), .some(let function), _):
            let typeString = String(reflecting: type(of: object))
            os_log("[%@] (%@)", log: .default, type: osLogType, typeString, function)

        case (.some(let object), _, .some(let message)):
            let typeString = String(reflecting: type(of: object))
            os_log("[%@] %@", log: .default, type: osLogType, typeString, message)

        case (.some(let object), _, _):
            let typeString = String(reflecting: type(of: object))
            os_log("[%@]", log: .default, type: osLogType, typeString)

        case (_, _, .some(let message)):
            os_log("%@", log: .default, type: osLogType, message)

        default:
            break
    }
}

@inline(__always)
public func log_info(_ object: Any?, _ function: String?, _ message: String) {
    log(object, function, message, type: .info)
}

public func log_debug(_ object: Any?, _ function: String?, _ message: @autoclosure () -> String?, detail: Int = log_default) {
    guard detail <= log_detail else {
        return
    }

    log(object, function, message(), type: .debug)
}

@inline(__always)
public func log_error(_ object: Any?, _ function: String?, _ message: String) {
    log(object, function, message, type: .error)
}

@inline(__always)
public func log_fault(_ object: Any?, _ function: String?, _ message: String) {
    log(object, function, message, type: .fault)
}
