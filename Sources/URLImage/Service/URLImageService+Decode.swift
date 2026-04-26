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

    func decode(result: DownloadResult, download: Download, identifier: String?, options: URLImageOptions) async throws -> TransientImage {
        switch result {
            case .data(let data):

                guard let transientImage = TransientImage(data: data, maxPixelSize: options.maxPixelSize) else {
                    throw URLImageError.decode
                }

                if shouldStore {
                    let info = URLImageStoreInfo(url: download.url, identifier: identifier, uti: transientImage.uti)
                    fileStore?.storeImageData(data, info: info)
                    if Self.shouldStoreInMemory(uti: transientImage.uti) {
                        await inMemoryStore?.store(transientImage, info: info)
                    }
                }

                return transientImage

            case .file(let path):

                let location = URL(fileURLWithPath: path)

                guard let transientImage = TransientImage(location: location, maxPixelSize: options.maxPixelSize) else {
                    throw URLImageError.decode
                }

                if shouldStore {
                    let info = URLImageStoreInfo(url: download.url, identifier: identifier, uti: transientImage.uti)
                    fileStore?.moveImageFile(from: location, info: info)
                    if Self.shouldStoreInMemory(uti: transientImage.uti) {
                        await inMemoryStore?.store(transientImage, info: info)
                    }
                }

                return transientImage
        }
    }

    private var shouldStore: Bool {
        fileStore != nil || inMemoryStore != nil
    }

    nonisolated static func shouldStoreInMemory(uti: String) -> Bool {
#if os(macOS)
        return uti != "com.compuserve.gif"
#else
        return true
#endif
    }
}
