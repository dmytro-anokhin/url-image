//
//  DownloadPublisher.swift
//  
//
//  Created by Dmytro Anokhin on 28/07/2020.
//

import Combine


@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public struct DownloadPublisher: Publisher {

    public typealias Output = DownloadInfo
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
                                                        where SubscriberType.Input == DownloadInfo,
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

        print("Start download")

        coordinator.startDownload(download,
            receiveResponse: { _ in
            },
            receiveData: { [weak self] _, data, progress in
                guard let self = self else {
                    return
                }

                print("Download receive data: \(data.count)")
                let _ = self.subscriber?.receive(.progress(progress))
            },
            completion: { [weak self] _, result in
                guard let self = self else {
                    return
                }
                
                switch result {
                    case .success(let downloadResult):
                        switch downloadResult {
                            case .data(let data):
                                print("Downloaded: \(data.count)")
                            case .file(let path):
                                print("Downloaded file at \(path)")
                        }

                        let _ = self.subscriber?.receive(.completion(downloadResult))
                        self.subscriber?.receive(completion: .finished)

                    case .failure(let error):
                        print("Download failed \(error)")
                        self.subscriber?.receive(completion: .failure(error))
                }
            })
    }

    func cancel() {
        coordinator.cancelDownload(download)
    }
}
