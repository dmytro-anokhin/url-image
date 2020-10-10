//
//  URLImageOptions.swift
//  
//
//  Created by Dmytro Anokhin on 02/10/2020.
//

import Foundation


public struct URLImageOptions {

    public enum CachePolicy {

        case returnCacheElseLoad(cacheDelay: TimeInterval? = nil, downloadDelay: TimeInterval? = nil)

        case returnCacheDontLoad(delay: TimeInterval? = nil)

        case returnCacheReload(cacheDelay: TimeInterval? = nil, downloadDelay: TimeInterval? = nil)

        case ignoreCache(delay: TimeInterval? = nil)

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

    public init(identifier: String? = nil,
                cachePolicy: CachePolicy = .returnCacheElseLoad(),
                expireAfter expiryInterval: TimeInterval? = nil) {
        self.identifier = identifier
        self.cachePolicy = cachePolicy
        self.expiryInterval = expiryInterval
    }
}
