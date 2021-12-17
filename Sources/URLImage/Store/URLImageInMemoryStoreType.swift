//
//  URLImageInMemoryStore.swift
//  
//
//  Created by Dmytro Anokhin on 09/02/2021.
//

import Foundation
import CoreGraphics
import Model


/// The `URLImageInMemoryStoreType` describes an object used to store images in-memory for fast access.
public protocol URLImageInMemoryStoreType: URLImageStoreType {

    func getImage<T>(_ keys: [URLImageKey]) -> T?

    func store<T>(_ image: T, info: URLImageStoreInfo)
}


@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
public extension URLImageInMemoryStoreType {

    func getImage(_ identifier: String) -> CGImage? {
        let transientImage: TransientImage? = getImage([ .identifier(identifier) ])
        return transientImage?.cgImage
    }

    func getImage(_ url: URL) -> CGImage? {
        let transientImage: TransientImage? = getImage([ .url(url) ])
        return transientImage?.cgImage
    }
}
