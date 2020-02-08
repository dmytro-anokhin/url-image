//
//  URLImage.swift
//  URLImage
//
//  Created by Dmytro Anokhin on 06/06/2019.
//  Copyright © 2019 Dmytro Anokhin. All rights reserved.
//

import SwiftUI

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
#endif


/**
    URLImage is a view that automatically loads an image from provided URL.

    The image is loaded on appearance. Loading operation is cancelled when the view disappears.
 */
@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
public struct URLImage<Content, Placeholder> : View where Content : View, Placeholder : View {

    // MARK: Public

    var url: URL { urlRequest.url! }

    let urlRequest: URLRequest

    let delay: TimeInterval

    let incremental: Bool

    let animated: Bool

    let expiryDate: Date?

    let processors: [ImageProcessing]?

    public init(_ url: URL, delay: TimeInterval = 0.0, incremental: Bool = false, animated: Bool = false, expireAfter expiryDate: Date? = nil, processors: [ImageProcessing]? = nil, placeholder: @escaping (_ downloadProgressWrapper: DownloadProgressWrapper) -> Placeholder, content: @escaping (_ imageProxy: ImageProxy) -> Content) {

        assert(!(incremental && processors != nil), "Using image processing with incremental download is not supported")

        self.urlRequest = makeRequest(with: url)
        self.placeholder = placeholder
        self.content = content
        self.delay = delay
        self.incremental = incremental
        self.animated = animated
        self.expiryDate = expiryDate
        self.processors = processors
    }

    public init(_ urlRequest: URLRequest, delay: TimeInterval = 0.0, incremental: Bool = false, animated: Bool = false, expireAfter expiryDate: Date? = nil, processors: [ImageProcessing]? = nil, placeholder: @escaping (_ downloadProgressWrapper: DownloadProgressWrapper) -> Placeholder, content: @escaping (_ imageProxy: ImageProxy) -> Content) {

        assert(!(incremental && processors != nil), "Using image processing with incremental download is not supported")
        assert(urlRequest.url != nil)
        assert(urlRequest.httpMethod == "GET")

        self.urlRequest = urlRequest
        self.placeholder = placeholder
        self.content = content
        self.delay = delay
        self.incremental = incremental
        self.animated = animated
        self.expiryDate = expiryDate
        self.processors = processors
    }

    public var body: some View {
        DispatchQueue.main.async {
            if self.previousURL != self.url {
                self.imageProxy = nil
            }
        }

        return ZStack {
            if self.imageProxy != nil {
                content(imageProxy!)
            }
            else {
                ImageLoaderView(urlRequest, delay: delay, incremental: incremental, animated: animated, expireAfter: expiryDate ?? Date(timeIntervalSinceNow: URLImageService.shared.defaultExpiryTime), processors: processors, services: URLImageService.shared.services, placeholder: placeholder, content: content)
                .onLoad { imageProxy in
                    self.imageProxy = imageProxy
                    self.previousURL = self.url
                }
            }
        }
    }

    // MARK: Private

    private let placeholder: (_ downloadProgressWrapper: DownloadProgressWrapper) -> Placeholder

    private let content: (_ imageProxy: ImageProxy) -> Content

    @State private var imageProxy: ImageProxy? = nil
    @State private var previousURL: URL? = nil
}


// MARK: Extensions


@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
public extension URLImage where Content == Image {

    init(_ url: URL, delay: TimeInterval = 0.0, incremental: Bool = false, animated: Bool = false, expireAfter expiryDate: Date? = nil, processors: [ImageProcessing]? = nil, placeholder: @escaping (_ downloadProgressWrapper: DownloadProgressWrapper) -> Placeholder, content: @escaping (_ imageProxy: ImageProxy) -> Content = { $0.image }) {

        assert(!(incremental && processors != nil), "Using image processing with incremental download is not supported")

        self.urlRequest = makeRequest(with: url)
        self.placeholder = placeholder
        self.content = content
        self.delay = delay
        self.incremental = incremental
        self.animated = animated
        self.expiryDate = expiryDate
        self.processors = processors
    }

    init(_ urlRequest: URLRequest, delay: TimeInterval = 0.0, incremental: Bool = false, animated: Bool = false, expireAfter expiryDate: Date? = nil, processors: [ImageProcessing]? = nil, placeholder: @escaping (_ downloadProgressWrapper: DownloadProgressWrapper) -> Placeholder, content: @escaping (_ imageProxy: ImageProxy) -> Content = { $0.image }) {

        assert(!(incremental && processors != nil), "Using image processing with incremental download is not supported")
        assert(urlRequest.url != nil)
        assert(urlRequest.httpMethod == "GET")

        self.urlRequest = urlRequest
        self.placeholder = placeholder
        self.content = content
        self.delay = delay
        self.incremental = incremental
        self.animated = animated
        self.expiryDate = expiryDate
        self.processors = processors
    }
}


@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
public extension URLImage where Placeholder == Image {

    init(_ url: URL, delay: TimeInterval = 0.0, incremental: Bool = false, animated: Bool = false, expireAfter expiryDate: Date? = nil, processors: [ImageProcessing]? = nil, placeholder placeholderImage: Image = {
#if canImport(AppKit) && !targetEnvironment(macCatalyst)
return Image(nsImage: NSImage())
#else
return Image(systemName: "photo")
#endif
    }(), content: @escaping (_ imageProxy: ImageProxy) -> Content) {

        assert(!(incremental && processors != nil), "Using image processing with incremental download is not supported")

        self.urlRequest = makeRequest(with: url)
        self.placeholder = { _ in placeholderImage }
        self.content = content
        self.delay = delay
        self.incremental = incremental
        self.animated = animated
        self.expiryDate = expiryDate
        self.processors = processors
    }

    init(_ urlRequest: URLRequest, delay: TimeInterval = 0.0, incremental: Bool = false, animated: Bool = false, expireAfter expiryDate: Date? = nil, processors: [ImageProcessing]? = nil, placeholder placeholderImage: Image = {
#if canImport(AppKit) && !targetEnvironment(macCatalyst)
return Image(nsImage: NSImage())
#else
return Image(systemName: "photo")
#endif
    }(), content: @escaping (_ imageProxy: ImageProxy) -> Content) {

        assert(!(incremental && processors != nil), "Using image processing with incremental download is not supported")
        assert(urlRequest.url != nil)
        assert(urlRequest.httpMethod == "GET")

        self.urlRequest = urlRequest
        self.placeholder = { _ in placeholderImage }
        self.content = content
        self.delay = delay
        self.incremental = incremental
        self.animated = animated
        self.expiryDate = expiryDate
        self.processors = processors
    }
}


@inline(__always)
fileprivate func makeRequest(with url: URL) -> URLRequest {
    URLRequest(url: url, cachePolicy: .reloadIgnoringCacheData, timeoutInterval: 60.0)
}
