//
//  DownloadManager+URLImage.swift
//
//
//  Created by Dmytro Anokhin on 02/10/2020.
//

import Foundation
import Combine
import DownloadManager
import ImageDecoder


extension DownloadManager {

    func transientImagePublisher(for download: Download, configuration: URLImageConfiguration) -> AnyPublisher<TransientImage, Error> {
        publisher(for: download)
            .tryMap { downloadResult -> TransientImage in
                switch downloadResult {
                    case .data(let data):

                        let decoder = ImageDecoder()
                        decoder.setData(data, allDataReceived: true)

                        guard let uti = decoder.uti else {
                            // Not an image data
                            throw URLImageError.decode
                        }

                        guard let image = decoder.createFrameImage(at: 0) else {
                            // Can not decode image, corrupted data
                            throw URLImageError.decode
                        }

                        let transientImage = TransientImage(cgImage: image,
                                                            cgOrientation: decoder.frameOrientation(at: 0),
                                                            uti: uti)

                        URLImageService.shared.diskCache.cacheImageData(data,
                                                                        url: download.url,
                                                                        identifier: configuration.identifier,
                                                                        fileName: configuration.identifier,
                                                                        fileExtension: ImageDecoder.preferredFileExtension(forTypeIdentifier: uti),
                                                                        expireAfter: configuration.expiryInterval)

                        URLImageService.shared.inMemoryCache.cacheTransientImage(transientImage,
                                                                                 withURL: download.url,
                                                                                 identifier: configuration.identifier,
                                                                                 expireAfter: configuration.expiryInterval)

                        return transientImage

                    case .file:
                        fatalError("Not implemented")
                }
            }
            .eraseToAnyPublisher()
    }
}
