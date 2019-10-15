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
@available(iOS 13.0, tvOS 13.0, macOS 10.15, *)
public struct URLImage<Content, Placeholder> : View where Content : View, Placeholder : View {

    // MARK: Public

    let url: URL

    let delay: TimeInterval

    let incremental: Bool

    let expiryDate: Date?

    public init(_ url: URL, delay: TimeInterval = 0.0, incremental: Bool = false, expireAfter expiryDate: Date? = nil, placeholder: @escaping (_ downloadProgressWrapper: DownloadProgressWrapper) -> Placeholder, content: @escaping (_ imageProxy: ImageProxy) -> Content) {
        self.url = url
        self.placeholder = placeholder
        self.content = content
        self.delay = delay
        self.incremental = incremental
        self.expiryDate = expiryDate
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
                ImageLoaderView(url, delay: delay, incremental: incremental, expireAfter: expiryDate ?? Date(timeIntervalSinceNow: URLImageService.shared.defaultExpiryTime), imageLoaderService: URLImageService.shared.services.imageLoaderService, placeholder: placeholder, content: content)
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


@available(iOS 13.0, tvOS 13.0, macOS 10.15, *)
public extension URLImage where Content == Image {

    init(_ url: URL, delay: TimeInterval = 0.0, incremental: Bool = false, expireAfter expiryDate: Date? = nil, placeholder: @escaping (_ downloadProgressWrapper: DownloadProgressWrapper) -> Placeholder, content: @escaping (_ imageProxy: ImageProxy) -> Content = { $0.image }) {
        self.url = url
        self.placeholder = placeholder
        self.content = content
        self.delay = delay
        self.incremental = incremental
        self.expiryDate = expiryDate
    }
}


@available(iOS 13.0, tvOS 13.0, macOS 10.15, *)
public extension URLImage where Placeholder == Image {

    init(_ url: URL, delay: TimeInterval = 0.0, incremental: Bool = false, expireAfter expiryDate: Date? = nil, placeholder placeholderImage: Image = {
#if canImport(AppKit) && !targetEnvironment(macCatalyst)
return Image(nsImage: NSImage())
#else
return Image(systemName: "photo")
#endif
    }(), content: @escaping (_ imageProxy: ImageProxy) -> Content) {
        self.url = url
        self.placeholder = { _ in placeholderImage }
        self.content = content
        self.delay = delay
        self.incremental = incremental
        self.expiryDate = expiryDate
    }
}


@available(iOS 13.0, tvOS 13.0, macOS 10.15, *)
public extension URLImage where Content == Image, Placeholder == Image {

    init(_ url: URL, delay: TimeInterval = 0.0, incremental: Bool = false, expireAfter expiryDate: Date? = nil, placeholder placeholderImage: Image = {
#if canImport(AppKit) && !targetEnvironment(macCatalyst)
return Image(nsImage: NSImage())
#else
return Image(systemName: "photo")
#endif
    }(), content: @escaping (_ imageProxy: ImageProxy) -> Content = { $0.image }) {
        self.url = url
        self.placeholder = { _ in placeholderImage }
        self.content = content
        self.delay = delay
        self.incremental = incremental
        self.expiryDate = expiryDate
    }
}
