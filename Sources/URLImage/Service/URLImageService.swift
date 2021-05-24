//
//  URLImageService.swift
//  
//
//  Created by Dmytro Anokhin on 25/08/2020.
//

import Foundation
import CoreGraphics
import Combine
import Model
import DownloadManager


@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public class URLImageService {

    public init(fileStore: URLImageFileStoreType? = nil, inMemoryStore: URLImageInMemoryStoreType? = nil) {
        self.fileStore = fileStore
        self.inMemoryStore = inMemoryStore
    }

    public let fileStore: URLImageFileStoreType?

    public let inMemoryStore: URLImageInMemoryStoreType?

    // MARK: - Internal

    let downloadManager = DownloadManager()

    func remoteImage(url: URL, identifier: String?, options: URLImageOptions) -> RemoteImage {
        let key = RemoteImageKey(url: url, identifier: identifier, options: options)

        if let remoteImage = remoteImages[key] {
            return remoteImage
        }

        let remoteImage = makeRemoteImage(url: url, identifier: identifier, options: options)
        remoteImages[key] = remoteImage

        return remoteImage
    }

    // MARK: - Private

    private var remoteImages: [RemoteImageKey: RemoteImage] = [:]
}
