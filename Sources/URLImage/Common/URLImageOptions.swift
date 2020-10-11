//
//  URLImageOptions.swift
//  
//
//  Created by Dmytro Anokhin on 02/10/2020.
//

import Foundation


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

        /// Return an image from cache and reload it
        ///
        /// - `cacheDelay`: delay before accessing disk cache.
        /// - `downloadDelay`: delay before starting download.
        ///
        /// There is no delay for in memory cache lookup.
        case returnCacheReload(cacheDelay: TimeInterval? = nil, downloadDelay: TimeInterval? = nil)

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

    public init(identifier: String? = nil,
                expireAfter expiryInterval: TimeInterval? = URLImageService.shared.defaultOptions.expiryInterval,
                cachePolicy: CachePolicy = URLImageService.shared.defaultOptions.cachePolicy) {
        self.identifier = identifier
        self.expiryInterval = expiryInterval
        self.cachePolicy = cachePolicy
    }
}
