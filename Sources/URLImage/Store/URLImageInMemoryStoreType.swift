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

    @URLImageInMemoryStoreActor func getImage<T: Sendable>(_ keys: [URLImageKey]) -> T?

    @URLImageInMemoryStoreActor func store<T: Sendable>(_ image: T, info: URLImageStoreInfo)
}


@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
public extension URLImageInMemoryStoreType {
    func getImage(_ identifier: String) async -> CGImage? {
        let transientImage: TransientImage? = await getImage([ .identifier(identifier) ])
        return await transientImage?.cgImage
    }

    func getImage(_ url: URL) async -> CGImage? {
        let transientImage: TransientImage? = await getImage([ .url(url) ])
        return await transientImage?.cgImage
    }
}
