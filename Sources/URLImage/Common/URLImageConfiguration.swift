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
    }

    public var isImmediate: Bool

    public init(isImmediate: Bool = false) {
        self.isImmediate = isImmediate
    }
}
