//
//  Bundle+Extensions.swift
//  
//
//  Created by Dmytro Anokhin on 11/09/2020.
//

import Foundation


extension Bundle {

    var name: String? {
        object(forInfoDictionaryKey: kCFBundleNameKey as String) as? String
    }

    var identifier: String? {
        object(forInfoDictionaryKey: kCFBundleIdentifierKey as String) as? String
    }
}
