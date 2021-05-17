//
//  URLImage.swift
//  
//
//  Created by Dmytro Anokhin on 16/08/2020.
//

import SwiftUI
import DownloadManager
import Model


@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public struct URLImage<Empty, InProgress, Failure, Content> : View where Empty : View,
                                                                         InProgress : View,
                                                                         Failure : View,
                                                                         Content : View {

    @Environment(\.urlImageService) var service: URLImageService

    /// Options passed in the environment.
    @Environment(\.urlImageOptions) var urlImageOptions: URLImageOptions

    let url: URL

    /// Unique identifier used to identify an image in cache.
    ///
    /// By default an image is identified by its URL. This is useful for static resources that have persistent URLs.
    /// For images that don't have a persistent URL create an identifier and store it with your model.
    ///
    /// Note: do not use sensitive information as identifier, the cache is stored in a non-encrypted database on disk.
    let identifier: String?

    public var body: some View {
        let remoteImage = service.makeRemoteImage(url: url, identifier: identifier, options: urlImageOptions)

        return RemoteImageView(remoteImage: remoteImage,
                               loadOptions: urlImageOptions.loadOptions,
                               empty: empty,
                               inProgress: inProgress,
                               failure: failure,
                               content: content)
    }

    private let empty: () -> Empty
    private let inProgress: (_ progress: Float?) -> InProgress
    private let failure: (_ error: Error, _ retry: @escaping () -> Void) -> Failure
    private let content: (_ image: TransientImage) -> Content

    private init(_ url: URL,
                 identifier: String?,
                 @ViewBuilder empty: @escaping () -> Empty,
                 @ViewBuilder inProgress: @escaping (_ progress: Float?) -> InProgress,
                 @ViewBuilder failure: @escaping (_ error: Error, _ retry: @escaping () -> Void) -> Failure,
                 @ViewBuilder content: @escaping (_ transientImage: TransientImage) -> Content) {

        self.url = url
        self.identifier = identifier

        self.empty = empty
        self.inProgress = inProgress
        self.failure = failure
        self.content = content
    }
}


@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension URLImage {

    init(_ url: URL,
         identifier: String? = nil,
         @ViewBuilder empty: @escaping () -> Empty,
         @ViewBuilder inProgress: @escaping (_ progress: Float?) -> InProgress,
         @ViewBuilder failure: @escaping (_ error: Error, _ retry: @escaping () -> Void) -> Failure,
         @ViewBuilder content: @escaping (_ image: Image) -> Content) {

        self.init(url,
                  identifier: identifier,
                  empty: empty,
                  inProgress: inProgress,
                  failure: failure,
                  content: { (transientImage: TransientImage) -> Content in
                      content(transientImage.image)
                  })
    }

    init(_ url: URL,
         identifier: String? = nil,
         @ViewBuilder empty: @escaping () -> Empty,
         @ViewBuilder inProgress: @escaping (_ progress: Float?) -> InProgress,
         @ViewBuilder failure: @escaping (_ error: Error, _ retry: @escaping () -> Void) -> Failure,
         @ViewBuilder content: @escaping (_ image: Image, _ info: ImageInfo) -> Content) {

        self.init(url,
                  identifier: identifier,
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
         identifier: String? = nil,
         @ViewBuilder inProgress: @escaping (_ progress: Float?) -> InProgress,
         @ViewBuilder failure: @escaping (_ error: Error, _ retry: @escaping () -> Void) -> Failure,
         @ViewBuilder content: @escaping (_ image: Image) -> Content) {

        self.init(url,
                  identifier: identifier,
                  empty: { EmptyView() },
                  inProgress: inProgress,
                  failure: failure,
                  content: content)
    }

    init(_ url: URL,
         identifier: String? = nil,
         @ViewBuilder inProgress: @escaping (_ progress: Float?) -> InProgress,
         @ViewBuilder failure: @escaping (_ error: Error, _ retry: @escaping () -> Void) -> Failure,
         @ViewBuilder content: @escaping (_ image: Image, _ info: ImageInfo) -> Content) {

        self.init(url,
                  identifier: identifier,
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
         identifier: String? = nil,
         @ViewBuilder failure: @escaping (_ error: Error, _ retry: @escaping () -> Void) -> Failure,
         @ViewBuilder content: @escaping (_ image: Image) -> Content) {

        self.init(url,
                  identifier: identifier,
                  empty: { EmptyView() },
                  inProgress: { _ in ActivityIndicator() },
                  failure: failure,
                  content: content)
    }

    init(_ url: URL,
         identifier: String? = nil,
         @ViewBuilder failure: @escaping (_ error: Error, _ retry: @escaping () -> Void) -> Failure,
         @ViewBuilder content: @escaping (_ image: Image, _ info: ImageInfo) -> Content) {

        self.init(url,
                  identifier: identifier,
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
         identifier: String? = nil,
         @ViewBuilder inProgress: @escaping (_ progress: Float?) -> InProgress,
         @ViewBuilder content: @escaping (_ image: Image) -> Content) {

        self.init(url,
                  identifier: identifier,
                  empty: { EmptyView() },
                  inProgress: inProgress,
                  failure: { _, _ in EmptyView() },
                  content: content)
    }

    init(_ url: URL,
         identifier: String? = nil,
         @ViewBuilder inProgress: @escaping (_ progress: Float?) -> InProgress,
         @ViewBuilder content: @escaping (_ image: Image, _ info: ImageInfo) -> Content) {

        self.init(url,
                  identifier: identifier,
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
         identifier: String? = nil,
         @ViewBuilder content: @escaping (_ image: Image) -> Content) {

        self.init(url,
                  identifier: identifier,
                  empty: { EmptyView() },
                  inProgress: { _ in ActivityIndicator() },
                  failure: { _, _ in EmptyView() },
                  content: content)
    }

    init(_ url: URL,
         identifier: String? = nil,
         @ViewBuilder content: @escaping (_ image: Image, _ info: ImageInfo) -> Content) {

        self.init(url,
                  identifier: identifier,
                  empty: { EmptyView() },
                  inProgress: { _ in ActivityIndicator() },
                  failure: { _, _ in EmptyView() },
                  content: content)
    }
}
