//
//  URLImageService+Decode.swift
//  
//
//  Created by Dmytro Anokhin on 19/11/2020.
//

import Foundation

#if canImport(Common)
import Common
#endif

#if canImport(DownloadManager)
import DownloadManager
#endif


@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension URLImageService {

    func decode(result: DownloadResult, download: Download, options: URLImageOptions) throws -> TransientImage {
        switch result {
            case .data(let data):

                guard let transientImage = TransientImage(data: data, maxPixelSize: options.maxPixelSize) else {
                    throw URLImageError.decode
                }

                if options.shouldCache {
                    let info = URLImageStoreInfo(url: download.url,
                                                 identifier: options.identifier,
                                                 uti: transientImage.uti,
                                                 expiryInterval: options.expiryInterval)

                    store?.storeImageData(data, info: info)

                    inMemoryCache.cacheTransientImage(transientImage,
                                                      withURL: download.url,
                                                      identifier: options.identifier,
                                                      expireAfter: options.expiryInterval)
                }

                return transientImage

            case .file(let path):

                let location = URL(fileURLWithPath: path)

                guard let transientImage = TransientImage(location: location, maxPixelSize: options.maxPixelSize) else {
                    throw URLImageError.decode
                }

                if options.shouldCache {
                    let info = URLImageStoreInfo(url: download.url,
                                                 identifier: options.identifier,
                                                 uti: transientImage.uti,
                                                 expiryInterval: options.expiryInterval)

                    store?.moveImageFile(from: location, info: info)

                    inMemoryCache.cacheTransientImage(transientImage,
                                                      withURL: download.url,
                                                      identifier: options.identifier,
                                                      expireAfter: options.expiryInterval)
                }
                

                return transientImage
        }
    }
}


@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
private extension URLImageOptions {

    var shouldCache: Bool {
        switch cachePolicy {
            case .useProtocol:
                return false
            default:
                return true
        }
    }
}
