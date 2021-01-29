//
//  URLImageStoreType.swift
//  
//
//  Created by Dmytro Anokhin on 10/01/2021.
//

import Foundation
import Combine
import CoreGraphics

#if canImport(Common)
import Common
#endif

#if canImport(DownloadManager)
import DownloadManager
#endif


public enum URLImageKey {

    case identifier(_ identifier: String)

    case url(_ url: URL)
}


@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public protocol URLImageStoreType {

    /// Get image from the cache.
    ///
    /// The `load` closure is used to delegate decoding image file.
    func getImage<T>(_ key: URLImageKey,
                     open: @escaping (_ location: URL) throws -> T?,
                     completion: @escaping (_ result: Result<T?, Swift.Error>) -> Void)

    func cacheImageData(_ data: Data,
                        url: URL,
                        identifier: String?,
                        fileName: String?,
                        fileExtension: String?,
                        expireAfter expiryInterval: TimeInterval?)

    func cacheImageFile(at location: URL,
                        url: URL,
                        identifier: String?,
                        fileName: String?,
                        fileExtension: String?,
                        expireAfter expiryInterval: TimeInterval?)
}


@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension URLImageStoreType {

    func getImagePublisher(_ key: URLImageKey, maxPixelSize: CGSize?) -> AnyPublisher<TransientImage?, Swift.Error> {
        Future<TransientImage?, Swift.Error> { promise in
            self.getImage(key) { location -> TransientImage in
                guard let transientImage = TransientImage(location: location, maxPixelSize: maxPixelSize) else {
                    throw URLImageError.decode
                }

                return transientImage
            }
            completion: { result in
                promise(result)
            }
        }.eraseToAnyPublisher()
    }
}
