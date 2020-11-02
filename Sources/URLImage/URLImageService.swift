//
//  URLImageService.swift
//  
//
//  Created by Dmytro Anokhin on 25/08/2020.
//

import Foundation
import Combine
import CoreGraphics

#if canImport(DownloadManager)
import DownloadManager
#endif


public final class URLImageService {

    public static let shared = URLImageService()

    let downloadManager = DownloadManager()

    let diskCache = DiskCache()

    let inMemoryCache = InMemoryCache()

    init() {
    }

    public var defaultOptions = URLImageOptions(identifier: nil,
                                                expireAfter: 24 * 60 * 60,
                                                cachePolicy: .returnCacheElseLoad(),
                                                isInMemoryDownload: false,
                                                maxPixelSize: CGSize(width: 300.0, height: 300.0))

    /// Remove expired images from the disk and in memory caches
    public func cleanup() {
        performPreviousVersionCleanup()

        diskCache.cleanup()
        inMemoryCache.cleanup()
    }

    public func removeAllCachedImages() {
        diskCache.deleteAll()
        inMemoryCache.removeAll()
    }

    public func removeImageWithURL(_ url: URL) {
        diskCache.delete(withIdentifier: nil, orURL: url)
        inMemoryCache.delete(withIdentifier: nil, orURL: url)
    }

    public func removeImageWithIdentifier(_ identifier: String) {
        diskCache.delete(withIdentifier: identifier, orURL: nil)
        inMemoryCache.delete(withIdentifier: identifier, orURL: nil)
    }

    private func performPreviousVersionCleanup() {
        let cachesURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let directoryURL = cachesURL.appendingPathComponent("URLImage", isDirectory: true)

        // First check if old version exists
        let versionFileURL = directoryURL.appendingPathComponent("filesCacheVersion")

        guard FileManager.default.fileExists(atPath: versionFileURL.path) else {
            return
        }

        let items = [
            // Files directory
            directoryURL.appendingPathComponent("files", isDirectory: true),
            // CoreData files
            directoryURL.appendingPathComponent("files").appendingPathExtension("db"),
            directoryURL.appendingPathComponent("files").appendingPathExtension("db-shm"),
            directoryURL.appendingPathComponent("files").appendingPathExtension("db-wal"),
            // Version file
            versionFileURL
        ]

        for itemURL in items {
            try? FileManager.default.removeItem(at: itemURL)
        }
    }
}
