//
//  URLImageStoreInfo.swift
//  
//
//  Created by Dmytro Anokhin on 09/02/2021.
//

import Foundation


/// Information that describes an image in a store
public struct URLImageStoreInfo: Sendable {

    /// Original URL of the image
    public var url: URL

    /// Optional unique identifier of the image
    public var identifier: String?

    /// The uniform type identifier (UTI) of the image.
    public var uti: String
    
    public init(url: URL, identifier: String? = nil, uti: String) {
        self.url = url
        self.identifier = identifier
        self.uti = uti
    }
}
