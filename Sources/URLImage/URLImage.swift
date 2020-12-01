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

    let empty: () -> Empty

    let inProgress: (_ progress: Float?) -> InProgress

    let failure: (_ error: Error, _ retry: @escaping () -> Void) -> Failure

    let content: (_ image: Image) -> Content

    public init(url: URL,
                options: URLImageOptions = URLImageService.shared.defaultOptions,
                empty: @escaping () -> Empty,
                inProgress: @escaping (_ progress: Float?) -> InProgress,
                failure: @escaping (_ error: Error, _ retry: @escaping () -> Void) -> Failure,
                content: @escaping (_ image: Image) -> Content)
    {
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

    let remoteImage: RemoteImage

    public var body: some View {
        RemoteContentView(remoteContent: remoteImage,
                          loadOptions: RemoteContentViewLoadOptions(options.loadOptions),
                          empty: empty,
                          inProgress: inProgress,
                          failure: failure,
                          content: { transientImage in
                            content(transientImage.image)
                          })
    }
}


@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension URLImage where Empty == EmptyView {

    init(url: URL,
         options: URLImageOptions = URLImageService.shared.defaultOptions,
         inProgress: @escaping (_ progress: Float?) -> InProgress,
         failure: @escaping (_ error: Error, _ retry: @escaping () -> Void) -> Failure,
         content: @escaping (_ image: Image) -> Content)
    {
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
         content: @escaping (_ image: Image) -> Content)
    {
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
         content: @escaping (_ image: Image) -> Content)
    {
        self.init(url: url,
                  options: options,
                  empty: { EmptyView() },
                  inProgress: { _ in ActivityIndicator() },
                  failure: { _, _ in EmptyView() },
                  content: content)
    }
}


@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
struct URLImage_Previews: PreviewProvider {
    static var previews: some View {
        URLImage(url: URL(string: "https://upload.wikimedia.org/wikipedia/en/7/7d/Lenna_%28test_image%29.png")!,
                 options: URLImageOptions(expireAfter: 60.0,
                                          cachePolicy: .ignoreCache()),
                 failure: { error, _ -> Text in
                    let string = "\(error)"
                    return Text(string)
                 },
                 content: { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipped()
                 })
            .frame(width: 320.0, height: 320.0)
    }
}
