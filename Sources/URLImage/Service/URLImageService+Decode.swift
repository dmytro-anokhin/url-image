//
//  URLImageService+Decode.swift
//  
//
//  Created by Dmytro Anokhin on 19/11/2020.
//

import Foundation
import Model
import DownloadManager


@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
extension URLImageService {

    func decode(result: DownloadResult, download: Download, identifier: String?, options: URLImageOptions) throws -> TransientImage {
        switch result {
            case .data(let data):

                guard let transientImage = TransientImage(data: data, maxPixelSize: nil) else {
                    throw URLImageError.decode
                }

                if shouldStore {
                    let info = URLImageStoreInfo(url: download.url, identifier: identifier, uti: transientImage.uti)
                    fileStore?.storeImageData(data, info: info)
                    inMemoryStore?.store(transientImage, info: info)
                }

                return transientImage

            case .file(let path):

                let location = URL(fileURLWithPath: path)

                guard let transientImage = TransientImage(location: location, maxPixelSize: nil) else {
                    throw URLImageError.decode
                }

                if shouldStore {
                    let info = URLImageStoreInfo(url: download.url, identifier: identifier, uti: transientImage.uti)
                    fileStore?.moveImageFile(from: location, info: info)
                    inMemoryStore?.store(transientImage, info: info)
                }

                return transientImage
        }
    }

    private var shouldStore: Bool {
        fileStore != nil || inMemoryStore != nil
    }
}
