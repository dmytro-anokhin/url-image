//
//  URLImageService+RemoteImage.swift
//  
//
//  Created by Dmytro Anokhin on 15/01/2021.
//

import Foundation
import Combine

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

    public func makeRemoteImage(url: URL, options: URLImageOptions? = nil) -> RemoteImage {
        let options = options ?? defaultOptions
        let download = Download(url: url, options: options)

        return RemoteImage(service: self, download: download, options: options)
    }

    public func remoteImagePublisher(_ url: URL, options: URLImageOptions? = nil) -> RemoteImagePublisher {
        let remoteImage = makeRemoteImage(url: url, options: options)
        return RemoteImagePublisher(remoteImage: remoteImage)
    }
}
