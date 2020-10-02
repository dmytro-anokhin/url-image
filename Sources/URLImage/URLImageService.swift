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

    public let downloadManager = DownloadManager()

    public let diskCache = DiskCache()

    public let inMemoryCache = InMemoryCache()

    init() {
    }
}
