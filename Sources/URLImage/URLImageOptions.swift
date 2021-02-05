//
//  URLImageOptions.swift
//  
//
//  Created by Dmytro Anokhin on 02/10/2020.
//

import Foundation
import CoreGraphics

#if canImport(DownloadManager)
import DownloadManager
#endif


/// Options to control how the image is downloaded and stored
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public struct URLImageOptions {

    /// The `FetchPolicy` allows to choose between returning stored image or downloading the remote one.
    public enum FetchPolicy {

        /// Return an image from the store or download it
        ///
        /// - `downloadDelay`: delay before starting download.
        case returnStoreElseLoad(downloadDelay: TimeInterval? = nil)

        /// Return an image from the store, do not download it
        case returnStoreDontLoad

        /// Ignore stored image and download the remote one
        ///
        /// - `downloadDelay`: delay before starting download.
        case ignoreStore(downloadDelay: TimeInterval? = nil)
    }

    /// Controls some aspects of download process
    public struct LoadOptions: OptionSet {

        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        /// Start load when the image view is created
        public static let loadImmediately: LoadOptions = .init(rawValue: 1 << 0)

        /// Start load when the image view appears
        public static let loadOnAppear: LoadOptions = .init(rawValue: 1 << 1)

        /// Cancel load when the image view disappears
        public static let cancelOnDisappear: LoadOptions = .init(rawValue: 1 << 2)

        /// Download image data in memory
        public static let inMemory: LoadOptions = .init(rawValue: 1 << 3)
    }

    public static var `default` = URLImageOptions(identifier: nil,
                                                  expiryInterval: 24 * 60 * 60,
                                                  fetchPolicy: .returnStoreElseLoad(),
                                                  loadOptions: [ .loadOnAppear, .cancelOnDisappear ],
                                                  urlRequestConfiguration: .init(),
                                                  maxPixelSize: nil)

    /// Unique identifier used to identify an image in cache.
    ///
    /// By default an image is identified by its URL. This is useful for static resources that have persistent URLs.
    /// For images that don't have a persistent URL create an identifier and store it with your model.
    ///
    /// Note: do not use sensitive information as identifier, the cache is stored in a non-encrypted database on disk.
    public var identifier: String?

    /// Time interval after which the cached image expires and can be deleted.
    public var expiryInterval: TimeInterval?

    /// The fetch policy defines when to load or use stored image.
    ///
    /// Fetch policy is only valid when there is a store on the service object.
    public var fetchPolicy: FetchPolicy

    public var loadOptions: LoadOptions

    public var urlRequestConfiguration: Download.URLRequestConfiguration

    /// Maximum size of a decoded image in pixels. If this property is not specified, the width and height of a decoded is not limited and may be as big as the image itself.
    public var maxPixelSize: CGSize?

    public init(identifier: String? = nil,
                expiryInterval: TimeInterval?,
                fetchPolicy: FetchPolicy,
                loadOptions: LoadOptions,
                urlRequestConfiguration: Download.URLRequestConfiguration,
                maxPixelSize: CGSize?) {
        self.identifier = identifier
        self.expiryInterval = expiryInterval
        self.fetchPolicy = fetchPolicy
        self.loadOptions = loadOptions
        self.urlRequestConfiguration = urlRequestConfiguration
        self.maxPixelSize = maxPixelSize
    }
}
