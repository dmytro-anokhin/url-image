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


public enum URLImageStoreKey {

    case identifier(_ identifier: String)

    case url(_ url: URL)
}


public struct URLImageStoreInfo {

    /// Original URL of the image
    public var url: URL

    /// Optional unique identifier of the image
    public var identifier: String?

    /// The uniform type identifier (UTI) of the image.
    public var uti: String

    /// Time interval after which the image is considered expired and must be deleted
    public var expiryInterval: TimeInterval?
}


@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public protocol URLImageStoreType {

    /// Get image from the strore.
    ///
    /// - parameters:
    ///     - keys: An array of keys used to lookup the image
    ///     - open: A closure used to open the image file by delegating its decoding to the calling routine
    func getImage<T>(_ keys: [URLImageStoreKey],
                     open: @escaping (_ location: URL) throws -> T?,
                     completion: @escaping (_ result: Result<T?, Swift.Error>) -> Void)

    /// Write image data to the store.
    func storeImageData(_ data: Data, info: URLImageStoreInfo)

    /// Move image file from the temporary location to the store.
    func moveImageFile(from location: URL, info: URLImageStoreInfo)
}


@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension URLImageStoreType {

    func getImagePublisher(_ keys: [URLImageStoreKey], maxPixelSize: CGSize?) -> AnyPublisher<TransientImage?, Swift.Error> {
        Future<TransientImage?, Swift.Error> { promise in
            self.getImage(keys) { location -> TransientImage in
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
