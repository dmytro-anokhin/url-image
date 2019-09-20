//
//  ImageLoaderConfiguration.swift
//  URLImage
//
//
//  Created by Dmytro Anokhin on 29/08/2019.
//  Copyright © 2019 Dmytro Anokhin. All rights reserved.
//

import Foundation


public struct ImageLoaderConfiguration {

    /// Delay before the `URLImage` instance fetches an image from local store or starts download operation
    public var delay: TimeInterval

    /// Enables/disables in-memory caching of downloaded images
    public var useInMemoryCache: Bool

    public init(delay: Double = 0.0, useInMemoryCache: Bool = false) {
        self.delay = delay
        self.useInMemoryCache = useInMemoryCache
    }
}
