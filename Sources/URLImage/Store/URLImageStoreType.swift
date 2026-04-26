//
//  URLImageStoreType.swift
//  
//
//  Created by Dmytro Anokhin on 15/02/2021.
//

import Foundation


/// General set of functions a store is expected to implement
public protocol URLImageStoreType: Sendable {

    func removeAllImages()

    func removeImageWithURL(_ url: URL)

    func removeImageWithIdentifier(_ identifier: String)
}

@available(macOS 10.15.0, iOS 13.0, *)
public protocol URLImageStoreType_Concurrency {

    func removeAllImages() async

    func removeImageWithURL(_ url: URL) async

    func removeImageWithIdentifier(_ identifier: String) async
}
