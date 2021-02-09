//
//  URLImageStoreKey.swift
//  
//
//  Created by Dmytro Anokhin on 09/02/2021.
//

import Foundation


/// Various key types used to store and access images in a store.
public enum URLImageStoreKey {

    /// Unique identifier as a string
    case identifier(_ identifier: String)

    /// URL of an image
    case url(_ url: URL)
}
