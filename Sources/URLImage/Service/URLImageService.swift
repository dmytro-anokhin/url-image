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

@propertyWrapper
public final class Synchronized<Value> {

    public var wrappedValue: Value {
        get {
            synchronizationQueue.sync {
                value
            }
        }

        set {
            synchronizationQueue.async(flags: .barrier) {
                self.value = newValue
            }
        }
    }

    public init(wrappedValue: Value) {
        value = wrappedValue
    }

    private let synchronizationQueue = DispatchQueue(label: "Synchronized.synchronizationQueue.\(UUID().uuidString)", attributes: .concurrent)

    private var value: Value
}


@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public class URLImageService {

    public static let shared = URLImageService()

    @Synchronized public var store: URLImageStoreType?

    // MARK: - Internal

    let downloadManager = DownloadManager()

    let inMemoryCache = InMemoryCache()

    // MARK: - Private

    private init() {
    }
}
