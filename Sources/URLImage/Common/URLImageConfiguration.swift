//
//  URLImageConfiguration.swift
//  
//
//  Created by Dmytro Anokhin on 02/10/2020.
//

import Foundation


public struct URLImageConfiguration {

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

    public init(identifier: String? = nil, cachePolicy: CachePolicy = .returnCacheElseLoad) {
        self.identifier = identifier
        self.cachePolicy = cachePolicy
    }
}
