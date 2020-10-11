//
//  URLImageService.swift
//  
//
//  Created by Dmytro Anokhin on 25/08/2020.
//

import Foundation
import Combine
import DownloadManager


public final class URLImageService {

    public static let shared = URLImageService()

    let downloadManager = DownloadManager()

    let diskCache = DiskCache()

    let inMemoryCache = InMemoryCache()

    init() {
    }

    public var defaultOptions = URLImageOptions(identifier: nil,
                                                expireAfter: 24 * 60 * 60,
                                                cachePolicy: .returnCacheElseLoad())

    /// Remove expired images from the disk and in memory caches
    public func cleanup() {
        diskCache.cleanup()
        inMemoryCache.cleanup()
    }

    public func removeImageWithURL(_ url: URL) {
        diskCache.delete(withIdentifier: nil, orURL: url)
        inMemoryCache.delete(withIdentifier: nil, orURL: url)
    }

    public func removeImageWithIdentifier(_ identifier: String) {
        diskCache.delete(withIdentifier: identifier, orURL: nil)
        inMemoryCache.delete(withIdentifier: identifier, orURL: nil)
    }
}
