//
//  URLImageService+Cache.swift
//  
//
//  Created by Dmytro Anokhin on 17/11/2020.
//

import Foundation


@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension URLImageService {

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

    // MARK: - Private

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
