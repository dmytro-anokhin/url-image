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
public struct URLImage<Content, Placeholder, Failure> : View where Content : View, Placeholder : View, Failure : View {

    // MARK: Public

    var url: URL { urlRequest.url! }

    let urlRequest: URLRequest

    let fileIdentifier: String

    let delay: TimeInterval

    let incremental: Bool

    let animated: Bool

    let expiryDate: Date?

    let processors: [ImageProcessing]?

    public init(_ url: URL, fileIdentifier: String? = nil, delay: TimeInterval = 0.0, incremental: Bool = false, animated: Bool = false, expireAfter expiryDate: Date? = nil, processors: [ImageProcessing]? = nil, placeholder: @escaping (_ downloadProgressWrapper: DownloadProgressWrapper) -> Placeholder, failure: @escaping (_ error: Error) -> Failure, content: @escaping (_ imageProxy: ImageProxy) -> Content) {

        self.init(makeRequest(with: url), fileIdentifier: fileIdentifier, delay: delay, incremental: incremental, animated: animated, expireAfter: expiryDate, processors: processors, placeholder: placeholder, failure: failure, content: content)
    }

    public init(_ urlRequest: URLRequest, fileIdentifier: String? = nil, delay: TimeInterval = 0.0, incremental: Bool = false, animated: Bool = false, expireAfter expiryDate: Date? = nil, processors: [ImageProcessing]? = nil, placeholder: @escaping (_ downloadProgressWrapper: DownloadProgressWrapper) -> Placeholder, failure: @escaping (_ error: Error) -> Failure, content: @escaping (_ imageProxy: ImageProxy) -> Content) {

        assert(!(incremental && processors != nil), "Using image processing with incremental download is not supported")
        assert(urlRequest.url != nil)
        assert(urlRequest.httpMethod == "GET")

        self.urlRequest = urlRequest
        self.fileIdentifier = fileIdentifier ?? urlRequest.url!.absoluteString
        self.placeholder = placeholder
        self.failure = failure
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
                self.error = nil
            }
        }

        return ZStack {
            if self.error != nil {
                failure(error!)
            }
            else if self.imageProxy != nil {
                content(imageProxy!)
            }
            else {
                ImageLoaderView(properties: .init(urlRequest: urlRequest, fileIdentifier: fileIdentifier, delay: delay, incremental: incremental, animated: animated, expiryDate: expiryDate ?? Date(timeIntervalSinceNow: URLImageService.shared.defaultExpiryTime), processors: processors), services: URLImageService.shared.services, placeholder: placeholder, content: content)
                .onLoad { result in
                    switch result {
                        case .success(let imageProxy):
                            self.error = nil
                            self.imageProxy = imageProxy
                        case .failure(let error):
                            self.imageProxy = nil
                            self.error = error
                    }

                    self.previousURL = self.url
                }
            }
        }
    }

    // MARK: Private

    private let placeholder: (_ downloadProgressWrapper: DownloadProgressWrapper) -> Placeholder

    private let failure: (_ error: Error) -> Failure

    private let content: (_ imageProxy: ImageProxy) -> Content

    @State private var imageProxy: ImageProxy? = nil
    @State private var error: Error? = nil
    @State private var previousURL: URL? = nil
}


// MARK: Extensions

// This extensions are combinations of Content, Placeholder, and Failure as Image.


@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
public extension URLImage where Content == Image {

    // MARK: Content == Image

    init(_ url: URL, fileIdentifier: String? = nil, delay: TimeInterval = 0.0, incremental: Bool = false, animated: Bool = false, expireAfter expiryDate: Date? = nil, processors: [ImageProcessing]? = nil, placeholder: @escaping (_ downloadProgressWrapper: DownloadProgressWrapper) -> Placeholder, failure: @escaping (_ error: Error) -> Failure, content: @escaping (_ imageProxy: ImageProxy) -> Content = { $0.image }) {

        self.init(makeRequest(with: url), fileIdentifier: fileIdentifier, delay: delay, incremental: incremental, animated: animated, expireAfter: expiryDate, processors: processors, placeholder: placeholder, failure: failure, content: content)
    }

    init(_ urlRequest: URLRequest, fileIdentifier: String? = nil, delay: TimeInterval = 0.0, incremental: Bool = false, animated: Bool = false, expireAfter expiryDate: Date? = nil, processors: [ImageProcessing]? = nil, placeholder: @escaping (_ downloadProgressWrapper: DownloadProgressWrapper) -> Placeholder, failure: @escaping (_ error: Error) -> Failure, content: @escaping (_ imageProxy: ImageProxy) -> Content = { $0.image }) {

        assert(!(incremental && processors != nil), "Using image processing with incremental download is not supported")
        assert(urlRequest.url != nil)
        assert(urlRequest.httpMethod == "GET")

        self.urlRequest = urlRequest
        self.fileIdentifier = fileIdentifier ?? urlRequest.url!.absoluteString
        self.placeholder = placeholder
        self.failure = failure
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

    // MARK: Placeholder == Image

    init(_ url: URL, fileIdentifier: String? = nil, delay: TimeInterval = 0.0, incremental: Bool = false, animated: Bool = false, expireAfter expiryDate: Date? = nil, processors: [ImageProcessing]? = nil, placeholder placeholderImage: Image = {
#if canImport(AppKit) && !targetEnvironment(macCatalyst)
return Image(nsImage: NSImage())
#else
return Image(systemName: "photo")
#endif
    }(), failure: @escaping (_ error: Error) -> Failure, content: @escaping (_ imageProxy: ImageProxy) -> Content) {

        self.init(makeRequest(with: url), fileIdentifier: fileIdentifier, delay: delay, incremental: incremental, animated: animated, expireAfter: expiryDate, processors: processors, placeholder: placeholderImage, failure: failure, content: content)
    }

    init(_ urlRequest: URLRequest, fileIdentifier: String? = nil, delay: TimeInterval = 0.0, incremental: Bool = false, animated: Bool = false, expireAfter expiryDate: Date? = nil, processors: [ImageProcessing]? = nil, placeholder placeholderImage: Image = {
#if canImport(AppKit) && !targetEnvironment(macCatalyst)
return Image(nsImage: NSImage())
#else
return Image(systemName: "photo")
#endif
    }(), failure: @escaping (_ error: Error) -> Failure, content: @escaping (_ imageProxy: ImageProxy) -> Content) {

        assert(!(incremental && processors != nil), "Using image processing with incremental download is not supported")
        assert(urlRequest.url != nil)
        assert(urlRequest.httpMethod == "GET")

        self.urlRequest = urlRequest
        self.fileIdentifier = fileIdentifier ?? urlRequest.url!.absoluteString
        self.placeholder = { _ in placeholderImage }
        self.failure = failure
        self.content = content
        self.delay = delay
        self.incremental = incremental
        self.animated = animated
        self.expiryDate = expiryDate
        self.processors = processors
    }
}


@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
public extension URLImage where Failure == Image {

    // MARK: Failure == Image

    init(_ url: URL, fileIdentifier: String? = nil, delay: TimeInterval = 0.0, incremental: Bool = false, animated: Bool = false, expireAfter expiryDate: Date? = nil, processors: [ImageProcessing]? = nil, placeholder: @escaping (_ downloadProgressWrapper: DownloadProgressWrapper) -> Placeholder, failure: Image = {
#if canImport(AppKit) && !targetEnvironment(macCatalyst)
return Image(nsImage: NSImage())
#else
return Image(systemName: "exclamationmark.triangle")
#endif
    }(), content: @escaping (_ imageProxy: ImageProxy) -> Content) {

        self.init(makeRequest(with: url), fileIdentifier: fileIdentifier, delay: delay, incremental: incremental, animated: animated, expireAfter: expiryDate, processors: processors, placeholder: placeholder, failure: failure, content: content)
    }

    init(_ urlRequest: URLRequest, fileIdentifier: String? = nil, delay: TimeInterval = 0.0, incremental: Bool = false, animated: Bool = false, expireAfter expiryDate: Date? = nil, processors: [ImageProcessing]? = nil, placeholder: @escaping (_ downloadProgressWrapper: DownloadProgressWrapper) -> Placeholder, failure: Image = {
#if canImport(AppKit) && !targetEnvironment(macCatalyst)
return Image(nsImage: NSImage())
#else
return Image(systemName: "exclamationmark.triangle")
#endif
        }(), content: @escaping (_ imageProxy: ImageProxy) -> Content) {

        assert(!(incremental && processors != nil), "Using image processing with incremental download is not supported")
        assert(urlRequest.url != nil)
        assert(urlRequest.httpMethod == "GET")

        self.urlRequest = urlRequest
        self.fileIdentifier = fileIdentifier ?? urlRequest.url!.absoluteString
        self.placeholder = placeholder
        self.failure = { _ in failure }
        self.content = content
        self.delay = delay
        self.incremental = incremental
        self.animated = animated
        self.expiryDate = expiryDate
        self.processors = processors
    }
}


@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
public extension URLImage where Content == Image, Placeholder == Image {

    // MARK: Content == Image, Placeholder == Image

    init(_ url: URL, fileIdentifier: String? = nil, delay: TimeInterval = 0.0, incremental: Bool = false, animated: Bool = false, expireAfter expiryDate: Date? = nil, processors: [ImageProcessing]? = nil, placeholder placeholderImage: Image = {
#if canImport(AppKit) && !targetEnvironment(macCatalyst)
return Image(nsImage: NSImage())
#else
return Image(systemName: "photo")
#endif
    }(), failure: @escaping (_ error: Error) -> Failure, content: @escaping (_ imageProxy: ImageProxy) -> Content = { $0.image }) {

        self.init(makeRequest(with: url), fileIdentifier: fileIdentifier, delay: delay, incremental: incremental, animated: animated, expireAfter: expiryDate, processors: processors, placeholder: placeholderImage, failure: failure, content: content)
    }

    init(_ urlRequest: URLRequest, fileIdentifier: String? = nil, delay: TimeInterval = 0.0, incremental: Bool = false, animated: Bool = false, expireAfter expiryDate: Date? = nil, processors: [ImageProcessing]? = nil, placeholder placeholderImage: Image = {
#if canImport(AppKit) && !targetEnvironment(macCatalyst)
return Image(nsImage: NSImage())
#else
return Image(systemName: "photo")
#endif
    }(), failure: @escaping (_ error: Error) -> Failure, content: @escaping (_ imageProxy: ImageProxy) -> Content = { $0.image }) {

        assert(!(incremental && processors != nil), "Using image processing with incremental download is not supported")
        assert(urlRequest.url != nil)
        assert(urlRequest.httpMethod == "GET")

        self.urlRequest = urlRequest
        self.fileIdentifier = fileIdentifier ?? urlRequest.url!.absoluteString
        self.placeholder = { _ in placeholderImage }
        self.failure = failure
        self.content = content
        self.delay = delay
        self.incremental = incremental
        self.animated = animated
        self.expiryDate = expiryDate
        self.processors = processors
    }
}


@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
public extension URLImage where Content == Image, Failure == Image {

    // MARK: Content == Image, Failure == Image

    init(_ url: URL, fileIdentifier: String? = nil, delay: TimeInterval = 0.0, incremental: Bool = false, animated: Bool = false, expireAfter expiryDate: Date? = nil, processors: [ImageProcessing]? = nil, placeholder: @escaping (_ downloadProgressWrapper: DownloadProgressWrapper) -> Placeholder, failure: Image = {
#if canImport(AppKit) && !targetEnvironment(macCatalyst)
return Image(nsImage: NSImage())
#else
return Image(systemName: "exclamationmark.triangle")
#endif
    }(), content: @escaping (_ imageProxy: ImageProxy) -> Content = { $0.image }) {

        self.init(makeRequest(with: url), fileIdentifier: fileIdentifier, delay: delay, incremental: incremental, animated: animated, expireAfter: expiryDate, processors: processors, placeholder: placeholder, failure: failure, content: content)
    }

    init(_ urlRequest: URLRequest, fileIdentifier: String? = nil, delay: TimeInterval = 0.0, incremental: Bool = false, animated: Bool = false, expireAfter expiryDate: Date? = nil, processors: [ImageProcessing]? = nil, placeholder: @escaping (_ downloadProgressWrapper: DownloadProgressWrapper) -> Placeholder, failure: Image = {
#if canImport(AppKit) && !targetEnvironment(macCatalyst)
return Image(nsImage: NSImage())
#else
return Image(systemName: "exclamationmark.triangle")
#endif
        }(), content: @escaping (_ imageProxy: ImageProxy) -> Content = { $0.image }) {

        assert(!(incremental && processors != nil), "Using image processing with incremental download is not supported")
        assert(urlRequest.url != nil)
        assert(urlRequest.httpMethod == "GET")

        self.urlRequest = urlRequest
        self.fileIdentifier = fileIdentifier ?? urlRequest.url!.absoluteString
        self.placeholder = placeholder
        self.failure = { _ in failure }
        self.content = content
        self.delay = delay
        self.incremental = incremental
        self.animated = animated
        self.expiryDate = expiryDate
        self.processors = processors
    }
}


@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
public extension URLImage where Placeholder == Image, Failure == Image {

    // MARK: Placeholder == Image, Failure == Image

    init(_ url: URL, fileIdentifier: String? = nil, delay: TimeInterval = 0.0, incremental: Bool = false, animated: Bool = false, expireAfter expiryDate: Date? = nil, processors: [ImageProcessing]? = nil, placeholder placeholderImage: Image = {
#if canImport(AppKit) && !targetEnvironment(macCatalyst)
return Image(nsImage: NSImage())
#else
return Image(systemName: "photo")
#endif
    }(), failure: Image = {
#if canImport(AppKit) && !targetEnvironment(macCatalyst)
return Image(nsImage: NSImage())
#else
return Image(systemName: "exclamationmark.triangle")
#endif
    }(), content: @escaping (_ imageProxy: ImageProxy) -> Content) {

        self.init(makeRequest(with: url), fileIdentifier: fileIdentifier, delay: delay, incremental: incremental, animated: animated, expireAfter: expiryDate, processors: processors, placeholder: placeholderImage, failure: failure, content: content)
    }

    init(_ urlRequest: URLRequest, fileIdentifier: String? = nil, delay: TimeInterval = 0.0, incremental: Bool = false, animated: Bool = false, expireAfter expiryDate: Date? = nil, processors: [ImageProcessing]? = nil, placeholder placeholderImage: Image = {
#if canImport(AppKit) && !targetEnvironment(macCatalyst)
return Image(nsImage: NSImage())
#else
return Image(systemName: "photo")
#endif
    }(), failure: Image = {
#if canImport(AppKit) && !targetEnvironment(macCatalyst)
return Image(nsImage: NSImage())
#else
return Image(systemName: "exclamationmark.triangle")
#endif
        }(), content: @escaping (_ imageProxy: ImageProxy) -> Content) {

        assert(!(incremental && processors != nil), "Using image processing with incremental download is not supported")
        assert(urlRequest.url != nil)
        assert(urlRequest.httpMethod == "GET")

        self.urlRequest = urlRequest
        self.fileIdentifier = fileIdentifier ?? urlRequest.url!.absoluteString
        self.placeholder = { _ in placeholderImage }
        self.failure = { _ in failure }
        self.content = content
        self.delay = delay
        self.incremental = incremental
        self.animated = animated
        self.expiryDate = expiryDate
        self.processors = processors
    }
}


@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
public extension URLImage where Content == Image, Placeholder == Image, Failure == Image {

    // MARK: Content == Image, Placeholder == Image, Failure == Image

    init(_ url: URL, fileIdentifier: String? = nil, delay: TimeInterval = 0.0, incremental: Bool = false, animated: Bool = false, expireAfter expiryDate: Date? = nil, processors: [ImageProcessing]? = nil, placeholder placeholderImage: Image = {
#if canImport(AppKit) && !targetEnvironment(macCatalyst)
return Image(nsImage: NSImage())
#else
return Image(systemName: "photo")
#endif
    }(), failure: Image = {
#if canImport(AppKit) && !targetEnvironment(macCatalyst)
return Image(nsImage: NSImage())
#else
return Image(systemName: "exclamationmark.triangle")
#endif
    }(), content: @escaping (_ imageProxy: ImageProxy) -> Content = { $0.image }) {

        self.init(makeRequest(with: url), fileIdentifier: fileIdentifier, delay: delay, incremental: incremental, animated: animated, expireAfter: expiryDate, processors: processors, placeholder: placeholderImage, failure: failure, content: content)
    }

    init(_ urlRequest: URLRequest, fileIdentifier: String? = nil, delay: TimeInterval = 0.0, incremental: Bool = false, animated: Bool = false, expireAfter expiryDate: Date? = nil, processors: [ImageProcessing]? = nil, placeholder placeholderImage: Image = {
#if canImport(AppKit) && !targetEnvironment(macCatalyst)
return Image(nsImage: NSImage())
#else
return Image(systemName: "photo")
#endif
    }(), failure: Image = {
#if canImport(AppKit) && !targetEnvironment(macCatalyst)
return Image(nsImage: NSImage())
#else
return Image(systemName: "exclamationmark.triangle")
#endif
        }(), content: @escaping (_ imageProxy: ImageProxy) -> Content = { $0.image }) {

        assert(!(incremental && processors != nil), "Using image processing with incremental download is not supported")
        assert(urlRequest.url != nil)
        assert(urlRequest.httpMethod == "GET")

        self.urlRequest = urlRequest
        self.fileIdentifier = fileIdentifier ?? urlRequest.url!.absoluteString
        self.placeholder = { _ in placeholderImage }
        self.failure = { _ in failure }
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
