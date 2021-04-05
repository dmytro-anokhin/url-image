//
//  URLImageKey.swift
//  
//
//  Created by Dmytro Anokhin on 09/02/2021.
//

import Foundation


/// Various key types used to access images.
public enum URLImageKey {

    /// Unique identifier as a string
    case identifier(_ identifier: String)

    /// URL of an image
    case url(_ url: URL)
}


extension URLImageKey: Hashable {}
