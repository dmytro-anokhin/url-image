//
//  URLImage.swift
//
//
//  Created by Dmytro Anokhin on 16/08/2020.
//

import SwiftUI
import DownloadManager
import Model


@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
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


@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
public extension URLImage {

    init(_ url: URL,
         identifier: String? = nil,
         scale: CGFloat = 1,
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
                      content(transientImage.image(scale: scale))
                  })
    }

    init(_ url: URL,
         identifier: String? = nil,
         scale: CGFloat = 1,
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
                      content(transientImage.image(scale: scale), transientImage.info)
                  })
    }
}


@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
public extension URLImage where Empty == EmptyView {

    init(_ url: URL,
         identifier: String? = nil,
         scale: CGFloat = 1,
         @ViewBuilder inProgress: @escaping (_ progress: Float?) -> InProgress,
         @ViewBuilder failure: @escaping (_ error: Error, _ retry: @escaping () -> Void) -> Failure,
         @ViewBuilder content: @escaping (_ image: Image) -> Content) {

        self.init(url,
                  identifier: identifier,
                  scale: scale,
                  empty: { EmptyView() },
                  inProgress: inProgress,
                  failure: failure,
                  content: content)
    }

    init(_ url: URL,
         identifier: String? = nil,
         scale: CGFloat = 1,
         @ViewBuilder inProgress: @escaping (_ progress: Float?) -> InProgress,
         @ViewBuilder failure: @escaping (_ error: Error, _ retry: @escaping () -> Void) -> Failure,
         @ViewBuilder content: @escaping (_ image: Image, _ info: ImageInfo) -> Content) {

        self.init(url,
                  identifier: identifier,
                  scale: scale,
                  empty: { EmptyView() },
                  inProgress: inProgress,
                  failure: failure,
                  content: content)
    }
}


@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
public extension URLImage where Empty == EmptyView,
                                InProgress == ActivityIndicator {

    init(_ url: URL,
         identifier: String? = nil,
         scale: CGFloat = 1,
         @ViewBuilder failure: @escaping (_ error: Error, _ retry: @escaping () -> Void) -> Failure,
         @ViewBuilder content: @escaping (_ image: Image) -> Content) {

        self.init(url,
                  identifier: identifier,
                  scale: scale,
                  empty: { EmptyView() },
                  inProgress: { _ in ActivityIndicator() },
                  failure: failure,
                  content: content)
    }

    init(_ url: URL,
         identifier: String? = nil,
         scale: CGFloat = 1,
         @ViewBuilder failure: @escaping (_ error: Error, _ retry: @escaping () -> Void) -> Failure,
         @ViewBuilder content: @escaping (_ image: Image, _ info: ImageInfo) -> Content) {

        self.init(url,
                  identifier: identifier,
                  scale: scale,
                  empty: { EmptyView() },
                  inProgress: { _ in ActivityIndicator() },
                  failure: failure,
                  content: content)
    }
}


@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
public extension URLImage where Empty == EmptyView,
                                Failure == EmptyView {

    init(_ url: URL,
         identifier: String? = nil,
         scale: CGFloat = 1,
         @ViewBuilder inProgress: @escaping (_ progress: Float?) -> InProgress,
         @ViewBuilder content: @escaping (_ image: Image) -> Content) {

        self.init(url,
                  identifier: identifier,
                  scale: scale,
                  empty: { EmptyView() },
                  inProgress: inProgress,
                  failure: { _, _ in EmptyView() },
                  content: content)
    }

    init(_ url: URL,
         identifier: String? = nil,
         scale: CGFloat = 1,
         @ViewBuilder inProgress: @escaping (_ progress: Float?) -> InProgress,
         @ViewBuilder content: @escaping (_ image: Image, _ info: ImageInfo) -> Content) {

        self.init(url,
                  identifier: identifier,
                  scale: scale,
                  empty: { EmptyView() },
                  inProgress: inProgress,
                  failure: { _, _ in EmptyView() },
                  content: content)
    }
}


@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
public extension URLImage where Empty == EmptyView,
                                InProgress == ActivityIndicator,
                                Failure == EmptyView {

    init(_ url: URL,
         identifier: String? = nil,
         scale: CGFloat = 1,
         @ViewBuilder content: @escaping (_ image: Image) -> Content) {

        self.init(url,
                  identifier: identifier,
                  scale: scale,
                  empty: { EmptyView() },
                  inProgress: { _ in ActivityIndicator() },
                  failure: { _, _ in EmptyView() },
                  content: content)
    }

    init(_ url: URL,
         identifier: String? = nil,
         scale: CGFloat = 1,
         @ViewBuilder content: @escaping (_ image: Image, _ info: ImageInfo) -> Content) {

        self.init(url,
                  identifier: identifier,
                  scale: scale,
                  empty: { EmptyView() },
                  inProgress: { _ in ActivityIndicator() },
                  failure: { _, _ in EmptyView() },
                  content: content)
    }
}

@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
public enum URLImagePhase {

    /// No image is loaded.
    case empty

    /// An image succesfully loaded.
    case success(Image)

    /// An image failed to load with an error.
    case failure(Error)

    /// The loaded image, if any.
    ///
    /// If this value isn't `nil`, the image load operation has finished,
    /// and you can use the image to update the view. You can use the image
    /// directly, or you can modify it in some way. For example, you can add
    /// a ``Image/resizable(capInsets:resizingMode:)`` modifier to make the
    /// image resizable.
    public var image: Image? {
        switch self {
            case .success(let image):
                return image
            default:
                return nil
        }
    }

    /// The error that occurred when attempting to load an image, if any.
    public var error: Error? {
        switch self {
            case .failure(let error):
                return error
            default:
                return nil
        }
    }
}


@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
public extension URLImage where InProgress == Content,
                                Empty == Content,
                                Failure == Content {

    init(url: URL, scale: CGFloat = 1, @ViewBuilder content: @escaping (_ phase: URLImagePhase) -> Content) {
        self.init(url,
                  identifier: nil,
                  scale: scale,
                  empty: { content(.empty) },
                  inProgress: { _ in content(.empty) },
                  failure: { error, retry in content(.failure(error)) },
                  content: { image in content(.success(image)) })
    }
}
