//
//  DownloadPublisher.swift
//  
//
//  Created by Dmytro Anokhin on 28/07/2020.
//

import Combine


@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public struct DownloadPublisher: Publisher {

    public typealias Output = DownloadResult
    public typealias Failure = DownloadError

    public let download: Download

    public func receive<S>(subscriber: S) where S: Subscriber,
                                                DownloadPublisher.Failure == S.Failure,
                                                DownloadPublisher.Output == S.Input
    {
        let subscription = DownloadSubscription(subscriber: subscriber, download: download, coordinator: coordinator)
        subscriber.receive(subscription: subscription)
    }

    init(download: Download, coordinator: URLSessionCoordinator) {
        self.download = download
        self.coordinator = coordinator
    }

    private unowned let coordinator: URLSessionCoordinator
}


@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
final class DownloadSubscription<SubscriberType: Subscriber>: Subscription
                                                        where SubscriberType.Input == DownloadResult,
                                                              SubscriberType.Failure == DownloadError
{
    private var subscriber: SubscriberType?

    private let download: Download
    private unowned let coordinator: URLSessionCoordinator

    init(subscriber: SubscriberType, download: Download, coordinator: URLSessionCoordinator) {
        self.subscriber = subscriber
        self.download = download
        self.coordinator = coordinator
    }

    func request(_ demand: Subscribers.Demand) {
        guard demand > 0 else { return }

        coordinator.startDownload(download,
            receiveData: { _, _ in
            },
            completion: { [weak self] _, result in
                guard let self = self else {
                    return
                }
                
                switch result {
                    case .success(let data):
                        let _ = self.subscriber?.receive(data)
                        self.subscriber?.receive(completion: .finished)
                    case .failure(let error):
                        self.subscriber?.receive(completion: .failure(error))
                }
            })
    }

    func cancel() {
        coordinator.cancelDownload(download)
    }
}
