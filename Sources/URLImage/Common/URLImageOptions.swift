//
//  URLImageOptions.swift
//  
//
//  Created by Dmytro Anokhin on 02/10/2020.
//

import Foundation


public struct URLImageOptions {

    public enum CachePolicy {

        case returnCacheElseLoad

        case returnCacheDontLoad

        case returnCacheReload

        case ignoreCache

        var isReturnCache: Bool {
            switch self {
                case .returnCacheElseLoad, .returnCacheDontLoad, .returnCacheReload:
                    return true
                default:
                    return false
            }
        }
    }

    public var identifier: String?

    public var cachePolicy: CachePolicy

    public var expiryInterval: TimeInterval?

    public var diskCacheDelay: TimeInterval?

    public var downloadDelay: TimeInterval?

    public init(identifier: String? = nil,
                cachePolicy: CachePolicy = .returnCacheElseLoad,
                expireAfter expiryInterval: TimeInterval? = nil,
                diskCacheDelay: TimeInterval? = nil,
                downloadAfter downloadDelay: TimeInterval? = nil
    ) {
        self.identifier = identifier
        self.cachePolicy = cachePolicy
        self.expiryInterval = expiryInterval
        self.diskCacheDelay = diskCacheDelay
        self.downloadDelay = downloadDelay
    }
}
