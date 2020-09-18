//
//  Utils.swift
//  
//
//  Created by Dmytro Anokhin on 10/07/2020.
//

import Foundation


extension Encodable {

    var jsonString: String {
        let encoder = JSONEncoder()

        guard let data = try? encoder.encode(self), let result = String(data: data, encoding: .utf8) else {
            return "{}"
        }

        return result
    }
}


extension CustomStringConvertible where Self: Encodable {

    public var description: String {
        "<\(type(of: self)): \(jsonString)>"
    }
}


extension CustomStringConvertible where Self: Encodable, Self: AnyObject {

    public var description: String {
        "<\(type(of: self)) \(Unmanaged.passUnretained(self).toOpaque()): \(jsonString)>"
    }
}
