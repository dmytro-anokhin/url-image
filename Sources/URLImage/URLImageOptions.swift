//
//  URLImageOptions.swift
//  
//
//  Created by Dmytro Anokhin on 02/10/2020.
//

import Foundation
import CoreGraphics
import DownloadManager


/// Options to control how the image is downloaded and stored
@available(macOS 10.15, iOS 14.0, tvOS 13.0, watchOS 6.0, *)
public struct URLImageOptions {

    /// The `FetchPolicy` allows to choose between returning stored image or downloading the remote one.
    public enum FetchPolicy: Hashable {

        /// Return an image from the store or download it
        ///
        /// - `downloadDelay`: delay before starting download.
        case returnStoreElseLoad(downloadDelay: TimeInterval? = nil)

        /// Return an image from the store, do not download it
        case returnStoreDontLoad
    }

    /// Controls some aspects of download process
    public struct LoadOptions: OptionSet, Hashable {

        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        /// Start load when the image view is rendered
        public static let loadImmediately: LoadOptions = .init(rawValue: 1 << 0)

        /// Start load when the image view appears
        public static let loadOnAppear: LoadOptions = .init(rawValue: 1 << 1)

        /// Cancel load when the image view disappears
        public static let cancelOnDisappear: LoadOptions = .init(rawValue: 1 << 2)
    }

    /// The fetch policy defines when to load or use stored image.
    public var fetchPolicy: FetchPolicy

    /// The load options specifies when to start or cancel loading.
    public var loadOptions: LoadOptions

    public var urlRequestConfiguration: Download.URLRequestConfiguration?

    /// Maximum size of a decoded image in pixels. If this property is not specified, the width and height of a decoded is not limited and may be as big as the image itself.
    public var maxPixelSize: CGSize?

    public init(fetchPolicy: FetchPolicy = .returnStoreElseLoad(downloadDelay: 0.25),
                loadOptions: LoadOptions = [ .loadImmediately ],
                urlRequestConfiguration: Download.URLRequestConfiguration? = nil,
                maxPixelSize: CGSize? = nil) {
        self.fetchPolicy = fetchPolicy
        self.loadOptions = loadOptions
        self.urlRequestConfiguration = urlRequestConfiguration
        self.maxPixelSize = maxPixelSize
    }
}


@available(macOS 10.15, iOS 14.0, tvOS 13.0, watchOS 6.0, *)
extension URLImageOptions: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(fetchPolicy)
        hasher.combine(loadOptions)
        hasher.combine(urlRequestConfiguration)

        if let maxPixelSize = maxPixelSize {
            hasher.combine(maxPixelSize.width)
            hasher.combine(maxPixelSize.height)
        }
    }
}
