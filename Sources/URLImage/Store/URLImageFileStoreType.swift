//
//  URLImageFileStoreType.swift
//  
//
//  Created by Dmytro Anokhin on 10/01/2021.
//

import Foundation


/// Type that declares requirements for a persistent store to store image files.
public protocol URLImageFileStoreType: URLImageStoreType {

    /// Get image from the strore.
    ///
    /// - parameters:
    ///     - keys: An array of keys used to lookup the image
    ///     - open: A closure used to open the image file by delegating its decoding to the calling routine
    func getImage<T>(_ keys: [URLImageKey],
                     open: @Sendable @escaping (_ location: URL) throws -> T?,
                     completion: @Sendable @escaping (_ result: Result<T?, Swift.Error>) -> Void)

    /// Write image data to the store.
    func storeImageData(_ data: Data, info: URLImageStoreInfo)

    /// Move image file from the temporary location to the store.
    func moveImageFile(from location: URL, info: URLImageStoreInfo)
}


/// Type that declares requirements for a persistent store to store image files.
@available(macOS 10.15.0, iOS 13.0, *)
public protocol URLImageFileStoreType_Concurrency: URLImageStoreType_Concurrency {

    /// Get image from the strore.
    ///
    /// - parameters:
    ///     - keys: An array of keys used to lookup the image
    ///     - open: A closure used to open the image file by delegating its decoding to the calling routine
    func getImage<T>(_ keys: [URLImageKey], open: @escaping (_ location: URL) async throws -> T?) async throws -> T?

    /// Write image data to the store.
    func storeImageData(_ data: Data, info: URLImageStoreInfo) async

    /// Move image file from the temporary location to the store.
    func moveImageFile(from location: URL, info: URLImageStoreInfo) async
}

