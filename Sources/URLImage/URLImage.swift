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
public struct URLImage<Content> : View where Content : View {

    @Environment(\.urlImageService) var service: URLImageService

    /// Options passed in the environment.
    @Environment(\.urlImageOptions) var urlImageOptions: URLImageOptions

    let url: URL?

    /// Unique identifier used to identify an image in cache.
    ///
    /// By default an image is identified by its URL. This is useful for static resources that have persistent URLs.
    /// For images that don't have a persistent URL create an identifier and store it with your model.
    ///
    /// Note: do not use sensitive information as identifier, the cache is stored in a non-encrypted database on disk.
    let identifier: String?

    public var body: some View {
        if let url = url {
            return content(.empty)
//            let remoteImage = service.makeRemoteImage(url: url, identifier: identifier, options: urlImageOptions)
//
//            return RemoteImageView(remoteImage: remoteImage,
//                                   loadOptions: urlImageOptions.loadOptions,
//                                   empty: { EmptyView() },
//                                   inProgress: { progress in EmptyView() },
//                                   failure: { error,retry in EmptyView() },
//                                   content: { value in EmptyView() })
        } else {
            return content(.empty)
        }
    }
//
//    private let empty: () -> Empty
//    private let inProgress: (_ progress: Float?) -> InProgress
//    private let failure: (_ error: Error, _ retry: @escaping () -> Void) -> Failure
//    private let content: (_ image: TransientImage) -> Content
//
//    private init(_ url: URL,
//                 identifier: String?,
//                 @ViewBuilder empty: @escaping () -> Empty,
//                 @ViewBuilder inProgress: @escaping (_ progress: Float?) -> InProgress,
//                 @ViewBuilder failure: @escaping (_ error: Error, _ retry: @escaping () -> Void) -> Failure,
//                 @ViewBuilder content: @escaping (_ transientImage: TransientImage) -> Content) {
//
//        self.url = url
//        self.identifier = identifier
//
//        self.empty = empty
//        self.inProgress = inProgress
//        self.failure = failure
//        self.content = content
//    }

    private let transaction: Transaction

    @ViewBuilder
    private let content: (URLImagePhase) -> Content

    public init(url: URL?, scale: CGFloat = 1, transaction: Transaction = Transaction(), @ViewBuilder content: @escaping (URLImagePhase) -> Content) {
        self.url = url
        self.identifier = nil
        self.transaction = transaction
        self.content = content
    }
}


@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
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
