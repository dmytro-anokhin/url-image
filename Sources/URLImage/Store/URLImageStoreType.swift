//
//  URLImageStoreType.swift
//  
//
//  Created by Dmytro Anokhin on 15/02/2021.
//

import Foundation


/// General set of functions a store is expected to implement
public protocol URLImageStoreType {

    func removeAllImages()

    func removeImageWithURL(_ url: URL)

    func removeImageWithIdentifier(_ identifier: String)
}
