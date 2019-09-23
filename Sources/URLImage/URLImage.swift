//
//  URLImage.swift
//  URLImage
//
//  Created by Dmytro Anokhin on 06/06/2019.
//  Copyright © 2019 Dmytro Anokhin. All rights reserved.
//

import SwiftUI


/**
    URLImage is a view that automatically loads an image from provided URL.

    The image is loaded on appearance. Loading operation is cancelled when the view disappears.
 */
@available(iOS 13.0, tvOS 13.0, *)
public struct URLImage<Content, Placeholder> : View where Content : View, Placeholder : View {

    // MARK: Public

    let url: URL

    let delay: TimeInterval

    public init(_ url: URL, delay: TimeInterval = 0.0, placeholder: @escaping (_ partialImage: PartialImage) -> Placeholder, content: @escaping (_ imageProxy: ImageProxy) -> Content) {
        self.url = url
        self.placeholder = placeholder
        self.content = content
        self.delay = delay
    }

    public var body: some View {
        DispatchQueue.main.async {
            if self.previousURL != self.url {
                self.imageProxy = nil
            }
        }

        if let imageProxy = self.imageProxy {
            let imageView = content(imageProxy)

            return AnyView(imageView)
        }
        else {
            let loaderView = ImageLoaderView(url, delay: delay, placeholder: placeholder)
                .onLoad { imageProxy in
                    self.imageProxy = imageProxy
                    self.previousURL = self.url
                }

            return AnyView(loaderView)
        }
    }

    // MARK: Private

    private let placeholder: (_ partialImage: PartialImage) -> Placeholder

    private let content: (_ imageProxy: ImageProxy) -> Content

    @State private var imageProxy: ImageProxy? = nil

    @State private var previousURL: URL? = nil
}


// MARK: Extensions


@available(iOS 13.0, tvOS 13.0, *)
public extension URLImage where Content == Image {

    init(_ url: URL, delay: TimeInterval = 0.0, placeholder: @escaping (_ partialImage: PartialImage) -> Placeholder, content: @escaping (_ imageProxy: ImageProxy) -> Content = { $0.image }) {
        self.url = url
        self.placeholder = placeholder
        self.content = content
        self.delay = delay
    }
}


@available(iOS 13.0, tvOS 13.0, *)
public extension URLImage where Placeholder == Image {

    init(_ url: URL, delay: TimeInterval = 0.0, placeholder placeholderImage: Image = Image(systemName: "photo"), content: @escaping (_ imageProxy: ImageProxy) -> Content) {
        self.url = url
        self.placeholder = { _ in placeholderImage }
        self.content = content
        self.delay = delay
    }
}


@available(iOS 13.0, tvOS 13.0, *)
public extension URLImage where Content == Image, Placeholder == Image {

    init(_ url: URL, delay: TimeInterval = 0.0, placeholder placeholderImage: Image = Image(systemName: "photo"), content: @escaping (_ imageProxy: ImageProxy) -> Content = { $0.image }) {
        self.url = url
        self.placeholder = { _ in placeholderImage }
        self.content = content
        self.delay = delay
    }
}
