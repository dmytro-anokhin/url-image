//
//  URLImageService.swift
//  
//
//  Created by Dmytro Anokhin on 25/08/2020.
//

import Foundation
import CoreGraphics
import Combine

#if canImport(Common)
import Common
#endif

#if canImport(DownloadManager)
import DownloadManager
#endif


@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public class URLImageService {

    public static let shared = URLImageService()

    @Synchronized public var store: URLImageStoreType?

    @Synchronized public var inMemory: URLImageInMemoryStoreType?

    // MARK: - Internal

    let downloadManager = DownloadManager()

    let inMemoryCache = InMemoryCache()

    // MARK: - Private

    private init() {
    }
}
