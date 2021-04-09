//
//  URLImageService+RemoteImage.swift
//  
//
//  Created by Dmytro Anokhin on 15/01/2021.
//

import Foundation
import Combine

#if canImport(Model)
import Model
#endif

#if canImport(DownloadManager)
import DownloadManager
#endif


@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension URLImageService {

    public struct RemoteImagePublisher: Publisher {

        public typealias Output = ImageInfo
        public typealias Failure = Error

        public func receive<S>(subscriber: S) where S: Subscriber,
                                                    RemoteImagePublisher.Failure == S.Failure,
                                                    RemoteImagePublisher.Output == S.Input {

            let subscription = RemoteImageSubscription(subscriber: subscriber, remoteImage: remoteImage)
            subscriber.receive(subscription: subscription)
        }

        let remoteImage: RemoteImage

        init(remoteImage: RemoteImage) {
            self.remoteImage = remoteImage
        }
    }

    final class RemoteImageSubscription<SubscriberType: Subscriber>: Subscription where SubscriberType.Input == ImageInfo,
                                                                                       SubscriberType.Failure == Error {

        private var subscriber: SubscriberType?

        private let remoteImage: RemoteImage

        init(subscriber: SubscriberType, remoteImage: RemoteImage) {
            self.subscriber = subscriber
            self.remoteImage = remoteImage
        }

        private var cancellable: AnyCancellable?

        func request(_ demand: Subscribers.Demand) {
            guard demand > 0 else {
                return
            }

            cancellable = remoteImage.$loadingState.sink(receiveValue: { [weak self] loadingState in
                guard let self = self else {
                    return
                }

                switch loadingState {
                    case .initial:
                        break

                    case .inProgress:
                        break

                    case .success(let transientImage):
                        let _ = self.subscriber?.receive(transientImage.info)
                        self.subscriber?.receive(completion: .finished)

                    case .failure(let error):
                        self.subscriber?.receive(completion: .failure(error))
                }
            })

            remoteImage.load()
        }

        func cancel() {
            remoteImage.cancel()
            cancellable = nil
        }
    }

    public func makeRemoteImage(url: URL, identifier: String?, options: URLImageOptions) -> RemoteImage {
        let inMemory = fileStore == nil

        let destination = makeDownloadDestination(inMemory: inMemory)
        let urlRequestConfiguration = options.urlRequestConfiguration ?? makeURLRequestConfiguration(inMemory: inMemory)

        let download = Download(url: url, destination: destination, urlRequestConfiguration: urlRequestConfiguration)

        return RemoteImage(service: self, download: download, identifier: identifier, options: options)
    }

    public func remoteImagePublisher(_ url: URL, identifier: String?, options: URLImageOptions = URLImageOptions()) -> RemoteImagePublisher {
        let remoteImage = makeRemoteImage(url: url, identifier: identifier, options: options)
        return RemoteImagePublisher(remoteImage: remoteImage)
    }

    /// Creates download destination depending if download must happen in memory or on disk
    private func makeDownloadDestination(inMemory: Bool) -> Download.Destination {
        if inMemory {
            return .inMemory
        }
        else {
            let path = FileManager.default.tmpFilePathInCachesDirectory()
            return .onDisk(path)
        }
    }

    private func makeURLRequestConfiguration(inMemory: Bool) -> Download.URLRequestConfiguration {
        if inMemory {
            return Download.URLRequestConfiguration()
        }
        else {
            return Download.URLRequestConfiguration(allHTTPHeaderFields: nil,
                                                    cachePolicy: .reloadIgnoringLocalCacheData)
        }
    }
}
