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

    public var store: URLImageStoreType? {
        get {
            synchronizationQueue.sync {
                _store
            }
        }

        set {
            synchronizationQueue.async(flags: .barrier) {
                self._store = newValue
            }
        }
    }

    // MARK: - Internal

    let downloadManager = DownloadManager()

    let inMemoryCache = InMemoryCache()

    // MARK: - Private

    private init() {
    }

    public var _store: URLImageStoreType? = nil

    private let synchronizationQueue = DispatchQueue(label: "URLImageService.synchronizationQueue", attributes: .concurrent)
}
