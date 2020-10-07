//
//  URLImage.swift
//  
//
//  Created by Dmytro Anokhin on 16/08/2020.
//

import SwiftUI
import RemoteContentView
import DownloadManager


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
                options: URLImageOptions = URLImageOptions(),
                empty: @escaping () -> Empty,
                inProgress: @escaping (_ progress: Float?) -> InProgress,
                failure: @escaping (_ error: Error, _ retry: @escaping () -> Void) -> Failure,
                content: @escaping (_ image: Image) -> Content)
    {
        self.url = url
        self.options = options
        self.empty = empty
        self.inProgress = inProgress
        self.failure = failure
        self.content = content
    }

    public var body: some View {
        let download = Download(url: url)
        let remoteImage = RemoteImage(downloadManager: URLImageService.shared.downloadManager,
                                      download: download,
                                      options: options)

        return RemoteContentView(remoteContent: remoteImage,
                                 empty: empty,
                                 inProgress: inProgress,
                                 failure: failure,
                                 content: content)
    }
}


@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension URLImage where Empty == EmptyView, InProgress == ActivityIndicator {

    init(url: URL,
         options: URLImageOptions = URLImageOptions(),
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


//@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
//struct URLImage_Previews: PreviewProvider {
//    static var previews: some View {
//        URLImage()
//    }
//}
