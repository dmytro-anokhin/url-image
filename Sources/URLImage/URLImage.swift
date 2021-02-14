//
//  URLImage.swift
//  
//
//  Created by Dmytro Anokhin on 16/08/2020.
//

import SwiftUI

#if canImport(DownloadManager)
import DownloadManager
#endif

#if canImport(Common)
import Common
#endif


@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public struct URLImage<Empty, InProgress, Failure, Content> : View where Empty : View,
                                                                         InProgress : View,
                                                                         Failure : View,
                                                                         Content : View
{
    @Environment(\.urlImageService) var service: URLImageService

    let url: URL

    let options: URLImageOptions

    public var body: some View {
        let remoteImage = service.makeRemoteImage(url: url, options: options)

        return RemoteImageContainerView(remoteImage: remoteImage,
                                        loadOptions: options.loadOptions,
                                        empty: empty, inProgress: inProgress,
                                        failure: failure,
                                        content: content)
    }

    private let empty: () -> Empty
    private let inProgress: (_ progress: Float?) -> InProgress
    private let failure: (_ error: Error, _ retry: @escaping () -> Void) -> Failure
    private let content: (_ image: TransientImage) -> Content

    private init(_ url: URL,
                 options: URLImageOptions,
                 empty: @escaping () -> Empty,
                 inProgress: @escaping (_ progress: Float?) -> InProgress,
                 failure: @escaping (_ error: Error, _ retry: @escaping () -> Void) -> Failure,
                 content: @escaping (_ transientImage: TransientImage) -> Content) {

        assert(options.loadOptions.contains(.loadImmediately) || options.loadOptions.contains(.loadOnAppear),
               "Options must specify how to load the image")

        self.url = url
        self.options = options

        self.empty = empty
        self.inProgress = inProgress
        self.failure = failure
        self.content = content
    }
}


@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension URLImage {

    init(_ url: URL,
         options: URLImageOptions? = nil,
         empty: @escaping () -> Empty,
         inProgress: @escaping (_ progress: Float?) -> InProgress,
         failure: @escaping (_ error: Error, _ retry: @escaping () -> Void) -> Failure,
         content: @escaping (_ image: Image) -> Content) {

        self.init(url,
                  options: options ?? URLImageOptions.default,
                  empty: empty,
                  inProgress: inProgress,
                  failure: failure,
                  content: { (transientImage: TransientImage) -> Content in
                      content(transientImage.image)
                  })
    }

    init(_ url: URL,
         options: URLImageOptions? = nil,
         empty: @escaping () -> Empty,
         inProgress: @escaping (_ progress: Float?) -> InProgress,
         failure: @escaping (_ error: Error, _ retry: @escaping () -> Void) -> Failure,
         content: @escaping (_ image: Image, _ info: ImageInfo) -> Content) {

        self.init(url,
                  options: options ?? URLImageOptions.default,
                  empty: empty,
                  inProgress: inProgress,
                  failure: failure,
                  content: { (transientImage: TransientImage) -> Content in
                      content(transientImage.image, transientImage.info)
                  })
    }
}


@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension URLImage where Empty == EmptyView {

    init(_ url: URL,
         options: URLImageOptions? = nil,
         inProgress: @escaping (_ progress: Float?) -> InProgress,
         failure: @escaping (_ error: Error, _ retry: @escaping () -> Void) -> Failure,
         content: @escaping (_ image: Image) -> Content) {

        self.init(url,
                  options: options,
                  empty: { EmptyView() },
                  inProgress: inProgress,
                  failure: failure,
                  content: content)
    }

    init(_ url: URL,
         options: URLImageOptions? = nil,
         inProgress: @escaping (_ progress: Float?) -> InProgress,
         failure: @escaping (_ error: Error, _ retry: @escaping () -> Void) -> Failure,
         content: @escaping (_ image: Image, _ info: ImageInfo) -> Content) {

        self.init(url,
                  options: options,
                  empty: { EmptyView() },
                  inProgress: inProgress,
                  failure: failure,
                  content: content)
    }
}


@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension URLImage where Empty == EmptyView,
                                InProgress == ActivityIndicator {

    init(_ url: URL,
         options: URLImageOptions? = nil,
         failure: @escaping (_ error: Error, _ retry: @escaping () -> Void) -> Failure,
         content: @escaping (_ image: Image) -> Content) {

        self.init(url,
                  options: options,
                  empty: { EmptyView() },
                  inProgress: { _ in ActivityIndicator() },
                  failure: failure,
                  content: content)
    }

    init(_ url: URL,
         options: URLImageOptions? = nil,
         failure: @escaping (_ error: Error, _ retry: @escaping () -> Void) -> Failure,
         content: @escaping (_ image: Image, _ info: ImageInfo) -> Content) {

        self.init(url,
                  options: options,
                  empty: { EmptyView() },
                  inProgress: { _ in ActivityIndicator() },
                  failure: failure,
                  content: content)
    }
}


@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension URLImage where Empty == EmptyView,
                                Failure == EmptyView {

    init(_ url: URL,
         options: URLImageOptions? = nil,
         inProgress: @escaping (_ progress: Float?) -> InProgress,
         content: @escaping (_ image: Image) -> Content) {

        self.init(url,
                  options: options,
                  empty: { EmptyView() },
                  inProgress: inProgress,
                  failure: { _, _ in EmptyView() },
                  content: content)
    }

    init(_ url: URL,
         options: URLImageOptions? = nil,
         inProgress: @escaping (_ progress: Float?) -> InProgress,
         content: @escaping (_ image: Image, _ info: ImageInfo) -> Content) {

        self.init(url,
                  options: options,
                  empty: { EmptyView() },
                  inProgress: inProgress,
                  failure: { _, _ in EmptyView() },
                  content: content)
    }
}


@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension URLImage where Empty == EmptyView,
                                InProgress == ActivityIndicator,
                                Failure == EmptyView {

    init(_ url: URL,
         options: URLImageOptions? = nil,
         content: @escaping (_ image: Image) -> Content) {

        self.init(url,
                  options: options,
                  empty: { EmptyView() },
                  inProgress: { _ in ActivityIndicator() },
                  failure: { _, _ in EmptyView() },
                  content: content)
    }

    init(_ url: URL,
         options: URLImageOptions? = nil,
         content: @escaping (_ image: Image, _ info: ImageInfo) -> Content) {

        self.init(url,
                  options: options,
                  empty: { EmptyView() },
                  inProgress: { _ in ActivityIndicator() },
                  failure: { _, _ in EmptyView() },
                  content: content)
    }
}
