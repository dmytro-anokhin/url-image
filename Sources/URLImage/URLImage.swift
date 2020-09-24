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
public struct URLImage<Empty, Progress, Failure, Content> : View where Empty : View,
                                                                       Progress : View,
                                                                       Failure : View,
                                                                       Content : View
{
    public struct Configuration {

        public var isImmediate: Bool

        public init(isImmediate: Bool = false) {
            self.isImmediate = isImmediate
        }
    }

    let url: URL

    let configuration: Configuration

    let empty: () -> Empty

    let inProgress: (_ progress: Float?) -> Progress

    let failure: (_ error: Error, _ retry: @escaping () -> Void) -> Failure

    let content: (_ image: Image) -> Content

    public init(url: URL,
                configuration: Configuration = Configuration(),
                empty: @escaping () -> Empty,
                inProgress: @escaping (_ progress: Float?) -> Progress,
                failure: @escaping (_ error: Error, _ retry: @escaping () -> Void) -> Failure,
                content: @escaping (_ image: Image) -> Content)
    {
        self.url = url
        self.configuration = configuration
        self.empty = empty
        self.inProgress = inProgress
        self.failure = failure
        self.content = content
    }

    public var body: some View {
        let download = Download(url: url)
        let remoteImage = RemoteImage(downloadManager: URLImageService.shared.downloadManager, download: download, isImmediate: configuration.isImmediate)

        return RemoteContentView(remoteContent: remoteImage, empty: empty, inProgress: inProgress, failure: failure, content: content)
    }
}


//@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
//struct URLImage_Previews: PreviewProvider {
//    static var previews: some View {
//        URLImage()
//    }
//}
