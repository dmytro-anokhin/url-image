//
//  URLImageConfiguration.swift
//  
//
//  Created by Dmytro Anokhin on 02/10/2020.
//


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

    public var cachePolicy: CachePolicy

    public init(cachePolicy: CachePolicy = .returnCacheElseLoad) {
        self.cachePolicy = cachePolicy
    }
}
