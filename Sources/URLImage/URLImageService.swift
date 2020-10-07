//
//  URLImageService.swift
//  
//
//  Created by Dmytro Anokhin on 25/08/2020.
//

import Foundation
import Combine
import DownloadManager


public final class URLImageService {

    public static let shared = URLImageService()

    let downloadManager = DownloadManager()

    let diskCache = DiskCache()

    let inMemoryCache = InMemoryCache()

    init() {
    }

    public func cleanup() {
        diskCache.cleanup()
        inMemoryCache.cleanup()
    }
}
