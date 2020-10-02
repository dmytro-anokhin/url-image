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

    func transientImagePublisher(for download: Download) -> AnyPublisher<TransientImage, Error> {
        publisher(for: download)
            .tryMap { downloadResult -> TransientImage in
                switch downloadResult {
                    case .data(let data):

                        URLImageService.shared.diskCache.cacheImageData(data, for: download.url)

                        let decoder = ImageDecoder()
                        decoder.setData(data, allDataReceived: true)

                        guard let image = decoder.createFrameImage(at: 0) else {
                            throw URLImageError.decode
                        }

                        let transientImage = TransientImage(cgImage: image,
                                                            cgOrientation: decoder.frameOrientation(at: 0))

                        URLImageService.shared.inMemoryCache.cacheTransientImage(transientImage, for: download.url)

                        return transientImage

                    case .file:
                        fatalError("Not implemented")
                }
            }
            .eraseToAnyPublisher()
    }
}
