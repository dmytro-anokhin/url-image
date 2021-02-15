//
//  URLImageStoreInfo.swift
//  
//
//  Created by Dmytro Anokhin on 09/02/2021.
//

import Foundation


/// Information that describes an image in a store
public struct URLImageStoreInfo {

    /// Original URL of the image
    public var url: URL

    /// Optional unique identifier of the image
    public var identifier: String?

    /// The uniform type identifier (UTI) of the image.
    public var uti: String
}
