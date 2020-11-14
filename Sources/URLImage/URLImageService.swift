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


@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public final class URLImageService {

    public static let shared = URLImageService()

    /// The default options
    ///
    /// The default options are used to provide default values to properties when `URLImageOptions` is created. This allows to customize individual properties of the `URLImageOptions` object retaining default values.
    ///
    ///     let myOptions = URLImageOptions(identifier: "MyImage")
    ///
    /// In this example `myOptions` will retain default values set using this property.
    public var defaultOptions = URLImageOptions(identifier: nil,
                                                expireAfter: 24 * 60 * 60,
                                                cachePolicy: .returnCacheElseLoad(),
                                                load: [ .loadImmediately, .loadOnAppear, .cancelOnDisappear ],
                                                maxPixelSize: CGSize(width: 300.0, height: 300.0))

    /// Remove expired images from the disk and in memory caches
    public func cleanup() {
        performPreviousVersionCleanup()

        diskCache.cleanup()
        inMemoryCache.cleanup()
    }

    /// Remove all cached images from the disk and in-memory caches
    public func removeAllCachedImages() {
        diskCache.deleteAll()
        inMemoryCache.removeAll()
    }

    /// Remove the image downloaded from the specified URL from the disk and in-memory caches
    public func removeImageWithURL(_ url: URL) {
        diskCache.delete(withIdentifier: nil, orURL: url)
        inMemoryCache.delete(withIdentifier: nil, orURL: url)
    }

    /// Remove the image cached with the specified identifier from the disk and in-memory caches
    public func removeImageWithIdentifier(_ identifier: String) {
        diskCache.delete(withIdentifier: identifier, orURL: nil)
        inMemoryCache.delete(withIdentifier: identifier, orURL: nil)
    }

    // MARK: - Internal

    let downloadManager = DownloadManager()

    let diskCache = DiskCache()

    let inMemoryCache = InMemoryCache()

    // MARK: - Private

    private init() {
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
