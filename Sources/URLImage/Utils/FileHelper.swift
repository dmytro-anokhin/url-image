//
//  FileHelper.swift
//  URLImage
//
//  Created by Dmytro Anokhin on 14/06/2019.
//  Copyright © 2019 Dmytro Anokhin. All rights reserved.
//

import Foundation


struct FileHelper {

    static let cachesDirectoryName = "URLImage"

    static let imageCachesDirectoryName = "images"

    /// App caches directory
    static var appCachesDirectoryURL: URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    }

    /// URLImage caches directory inside the app caches directory
    static var cachesDirectoryURL: URL {
        return appCachesDirectoryURL.appendingPathComponent(cachesDirectoryName, isDirectory: true)
    }

    /// Images directory inside the URLImage caches directory
    static var imageCachesDirectoryURL: URL {
        return cachesDirectoryURL.appendingPathComponent(imageCachesDirectoryName, isDirectory: true)
    }

    static func copyToCaches(from sourceURL: URL) throws -> URL {
        let fileManager = FileManager.default

        if !fileManager.fileExists(atPath: imageCachesDirectoryURL.path) {
            try fileManager.createDirectory(at: imageCachesDirectoryURL, withIntermediateDirectories: true, attributes: nil)
        }

        let uuid = UUID()
        let destinationURL = imageCachesDirectoryURL.appendingPathComponent(uuid.uuidString, isDirectory: false)

        try fileManager.copyItem(at: sourceURL, to: destinationURL)
        
        return destinationURL
    }
    
    static func delete(at url: URL) throws {
        try FileManager.default.removeItem(at: url)
    }
}
