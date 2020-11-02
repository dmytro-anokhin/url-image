//
//  URLImageOptions.swift
//  
//
//  Created by Dmytro Anokhin on 02/10/2020.
//

import Foundation
import CoreGraphics


/// Options to control how the image is downloaded and stored
public struct URLImageOptions {

    public enum CachePolicy {

        /// Return an image from cache or download it
        ///
        /// - `cacheDelay`: delay before accessing disk cache.
        /// - `downloadDelay`: delay before starting download.
        ///
        /// There is no delay for in memory cache lookup.
        case returnCacheElseLoad(cacheDelay: TimeInterval? = nil, downloadDelay: TimeInterval? = nil)

        /// Return an image from cache, do not download it
        ///
        /// - `delay`: delay before accessing disk cache.
        ///
        /// There is no delay for in memory cache lookup.
        case returnCacheDontLoad(delay: TimeInterval? = nil)

        /// Ignore cached image and download remote one
        ///
        /// - `delay`: delay before starting download.
        case ignoreCache(delay: TimeInterval? = nil)
    }

    /// Unique identifier used to identify an image in cache.
    ///
    /// By default an image is identified by its URL. This is useful for static resources that have persistent URLs.
    /// For images that don't have a persistent URL create an identifier and store it with your model.
    ///
    /// Note: do not use sensitive information as identifier, the cache is stored in a non-encrypted database on disk.
    public var identifier: String?

    /// Time interval after which the cached image expires and can be deleted.
    public var expiryInterval: TimeInterval?

    /// The cache policy controls how the image loaded from cache
    public var cachePolicy: CachePolicy

    /// Download image data in memory or directly to the file on disk
    public var isInMemoryDownload: Bool

    /// Maximum size of a decoded image in pixels. If this property is not specified, the width and height of a decoded is not limited and may be as big as the image itself.
    public var maxPixelSize: CGSize?

    public init(identifier: String? = nil,
                expireAfter expiryInterval: TimeInterval? = URLImageService.shared.defaultOptions.expiryInterval,
                cachePolicy: CachePolicy = URLImageService.shared.defaultOptions.cachePolicy,
                isInMemoryDownload: Bool = URLImageService.shared.defaultOptions.isInMemoryDownload,
                maxPixelSize: CGSize? = URLImageService.shared.defaultOptions.maxPixelSize) {
        self.identifier = identifier
        self.expiryInterval = expiryInterval
        self.cachePolicy = cachePolicy
        self.isInMemoryDownload = isInMemoryDownload
        self.maxPixelSize = maxPixelSize
    }
}
