//
//  URLImageService+Decode.swift
//  
//
//  Created by Dmytro Anokhin on 19/11/2020.
//

import Foundation

#if canImport(DownloadManager)
import DownloadManager
#endif

#if canImport(ImageDecoder)
import ImageDecoder
#endif


@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension URLImageService {

    func decode(result: DownloadResult, download: Download, options: URLImageOptions) throws -> TransientImageType {
        switch result {
            case .data(let data):

                guard let transientImage = TransientImage(data: data, maxPixelSize: options.maxPixelSize) else {
                    throw URLImageError.decode
                }

                let fileName = UUID().uuidString
                let fileExtension = ImageDecoder.preferredFileExtension(forTypeIdentifier: transientImage.uti)

                if options.shouldCache {
                    diskCache.cacheImageData(data,
                                             url: download.url,
                                             identifier: options.identifier,
                                             fileName: fileName,
                                             fileExtension: fileExtension,
                                             expireAfter: options.expiryInterval)

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

                let fileName = UUID().uuidString
                let fileExtension: String?

                if !location.pathExtension.isEmpty {
                    fileExtension = location.pathExtension
                }
                else {
                    fileExtension = ImageDecoder.preferredFileExtension(forTypeIdentifier: transientImage.uti)
                }

                if options.shouldCache {
                    diskCache.cacheImageFile(at: location,
                                             url: download.url,
                                             identifier: options.identifier,
                                             fileName: fileName,
                                             fileExtension: fileExtension,
                                             expireAfter: options.expiryInterval)

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
