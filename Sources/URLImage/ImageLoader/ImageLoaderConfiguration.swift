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

    /// Shared URLSession with default configuration that runs one connection per host
    public static let sharedURLSession = URLSession(configuration: {
        let configuration = URLSessionConfiguration.default.copy() as! URLSessionConfiguration
        configuration.httpMaximumConnectionsPerHost = 1

        return configuration
    }())

    /// `URLSession` used to download an image
    public var urlSession: URLSession

    /// Delay before the `URLImage` instance fetches an image from local store or starts download operation
    public var delay: Double

    /// Enables/disables in-memory caching of downloaded images
    public var useInMemoryCache: Bool

    public init(urlSession: URLSession = ImageLoaderConfiguration.sharedURLSession, delay: Double = 0.0, useInMemoryCache: Bool = false) {
        self.urlSession = urlSession
        self.delay = delay
        self.useInMemoryCache = useInMemoryCache
    }
}
