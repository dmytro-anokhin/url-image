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

    // Stores properties are synchronized to make accessors thread safe. Avoid changing a store after the app finished launching, this could lead to unexpected side effects.

    @Synchronized public var fileStore: URLImageFileStoreType?
    
    @Synchronized public var inMemoryStore: URLImageInMemoryStoreType?

    // MARK: - Internal

    let downloadManager = DownloadManager()

    // MARK: - Private

    private init() {
    }
}
