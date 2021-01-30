//
//  URLImage.swift
//  
//
//  Created by Dmytro Anokhin on 16/08/2020.
//

import SwiftUI

#if canImport(RemoteContentView)
import RemoteContentView
#endif

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
    let url: URL

    let options: URLImageOptions

    public var body: some View {
        RemoteContentView(remoteContent: remoteImage,
                          loadOptions: RemoteContentViewLoadOptions(options.loadOptions),
                          empty: empty,
                          inProgress: inProgress,
                          failure: failure,
                          content: content)
    }

    private let empty: () -> Empty
    private let inProgress: (_ progress: Float?) -> InProgress
    private let failure: (_ error: Error, _ retry: @escaping () -> Void) -> Failure
    private let content: (_ image: TransientImageType) -> Content

    private let remoteImage: RemoteImage

    private init(url: URL,
         options: URLImageOptions,
         empty: @escaping () -> Empty,
         inProgress: @escaping (_ progress: Float?) -> InProgress,
         failure: @escaping (_ error: Error, _ retry: @escaping () -> Void) -> Failure,
         content: @escaping (_ transientImage: TransientImageType) -> Content) {

        assert(options.loadOptions.contains(.loadImmediately) || options.loadOptions.contains(.loadOnAppear),
               "Options must specify how to load the image")

        self.url = url
        self.options = options
        self.empty = empty
        self.inProgress = inProgress
        self.failure = failure
        self.content = content

        remoteImage = URLImageService.shared.makeRemoteImage(url: url, options: options)
    }
}


@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension URLImage {

    init(url: URL,
         options: URLImageOptions = URLImageService.shared.defaultOptions,
         empty: @escaping () -> Empty,
         inProgress: @escaping (_ progress: Float?) -> InProgress,
         failure: @escaping (_ error: Error, _ retry: @escaping () -> Void) -> Failure,
         content: @escaping (_ image: Image) -> Content) {

        self.init(url: url, options: options, empty: empty, inProgress: inProgress, failure: failure) { (transientImage: TransientImageType) -> Content in
            content(transientImage.image)
        }
    }

    init(url: URL,
         options: URLImageOptions = URLImageService.shared.defaultOptions,
         empty: @escaping () -> Empty,
         inProgress: @escaping (_ progress: Float?) -> InProgress,
         failure: @escaping (_ error: Error, _ retry: @escaping () -> Void) -> Failure,
         content: @escaping (_ image: Image, _ info: ImageInfo) -> Content) {

        self.init(url: url, options: options, empty: empty, inProgress: inProgress, failure: failure) { (transientImage: TransientImageType) -> Content in
            content(transientImage.image, transientImage.info)
        }
    }
}


@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension URLImage where Empty == EmptyView {

    init(url: URL,
         options: URLImageOptions = URLImageService.shared.defaultOptions,
         inProgress: @escaping (_ progress: Float?) -> InProgress,
         failure: @escaping (_ error: Error, _ retry: @escaping () -> Void) -> Failure,
         content: @escaping (_ image: Image) -> Content) {

        self.init(url: url,
                  options: options,
                  empty: { EmptyView() },
                  inProgress: inProgress,
                  failure: failure,
                  content: content)
    }

    init(url: URL,
         options: URLImageOptions = URLImageService.shared.defaultOptions,
         inProgress: @escaping (_ progress: Float?) -> InProgress,
         failure: @escaping (_ error: Error, _ retry: @escaping () -> Void) -> Failure,
         content: @escaping (_ image: Image, _ info: ImageInfo) -> Content) {

        self.init(url: url,
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

    init(url: URL,
         options: URLImageOptions = URLImageService.shared.defaultOptions,
         failure: @escaping (_ error: Error, _ retry: @escaping () -> Void) -> Failure,
         content: @escaping (_ image: Image) -> Content) {

        self.init(url: url,
                  options: options,
                  empty: { EmptyView() },
                  inProgress: { _ in ActivityIndicator() },
                  failure: failure,
                  content: content)
    }

    init(url: URL,
         options: URLImageOptions = URLImageService.shared.defaultOptions,
         failure: @escaping (_ error: Error, _ retry: @escaping () -> Void) -> Failure,
         content: @escaping (_ image: Image, _ info: ImageInfo) -> Content) {

        self.init(url: url,
                  options: options,
                  empty: { EmptyView() },
                  inProgress: { _ in ActivityIndicator() },
                  failure: failure,
                  content: content)
    }
}


@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension URLImage where Empty == EmptyView,
                                InProgress == ActivityIndicator,
                                Failure == EmptyView {

    init(url: URL,
         options: URLImageOptions = URLImageService.shared.defaultOptions,
         content: @escaping (_ image: Image) -> Content) {

        self.init(url: url,
                  options: options,
                  empty: { EmptyView() },
                  inProgress: { _ in ActivityIndicator() },
                  failure: { _, _ in EmptyView() },
                  content: content)
    }

    init(url: URL,
         options: URLImageOptions = URLImageService.shared.defaultOptions,
         content: @escaping (_ image: Image, _ info: ImageInfo) -> Content) {

        self.init(url: url,
                  options: options,
                  empty: { EmptyView() },
                  inProgress: { _ in ActivityIndicator() },
                  failure: { _, _ in EmptyView() },
                  content: content)
    }
}
