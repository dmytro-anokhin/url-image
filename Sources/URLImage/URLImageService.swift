//
//  URLImageService.swift
//  
//
//  Created by Dmytro Anokhin on 25/08/2020.
//

import Foundation
import CoreGraphics
import Combine

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
                                                urlRequestConfiguration: .init(),
                                                maxPixelSize: URLImageService.suggestedMaxPixelSize)

    public var diskCacheURL: URL {
        diskCache.fileIndex.configuration.filesDirectoryURL
    }

    // MARK: - Internal

    let downloadManager = DownloadManager()

    let diskCache = DiskCache()

    let inMemoryCache = InMemoryCache()

    // MARK: - Private

    private init() {
    }
}
