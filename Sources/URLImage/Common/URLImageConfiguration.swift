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

/*
         NSURLRequestUseProtocolCachePolicy = 0,

         NSURLRequestReloadIgnoringLocalCacheData = 1,
         NSURLRequestReloadIgnoringLocalAndRemoteCacheData = 4,
         NSURLRequestReloadIgnoringCacheData = NSURLRequestReloadIgnoringLocalCacheData,

         NSURLRequestReturnCacheDataElseLoad = 2,
         NSURLRequestReturnCacheDataDontLoad = 3,

         NSURLRequestReloadRevalidatingCacheData = 5,

         */
    }

    public var isImmediate: Bool

    public init(isImmediate: Bool = false) {
        self.isImmediate = isImmediate
    }
}
