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
        let subscription = DownloadSubscription(subscriber: subscriber, download: download, manager: manager)
        subscriber.receive(subscription: subscription)
    }

    init(download: Download, manager: DownloadManager) {
        self.download = download
        self.manager = manager
    }

    private unowned let manager: DownloadManager
}


@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
final class DownloadSubscription<SubscriberType: Subscriber>: Subscription
                                                        where SubscriberType.Input == DownloadInfo,
                                                              SubscriberType.Failure == DownloadError
{
    private var subscriber: SubscriberType?

    private let download: Download

    private unowned let manager: DownloadManager

    init(subscriber: SubscriberType, download: Download, manager: DownloadManager) {
        self.subscriber = subscriber
        self.download = download
        self.manager = manager
    }

    func request(_ demand: Subscribers.Demand) {
        guard demand > 0 else { return }

        print("Start download")

        manager.coordinator.startDownload(download,
            receiveResponse: { _ in
            },
            receiveData: {  _, _ in
            },
            reportProgress: { [weak self] _, progress in
                guard let self = self else {
                    return
                }

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

                self.manager.reset(download: self.download)
            })
    }

    func cancel() {
        manager.coordinator.cancelDownload(download)
        manager.reset(download: download)
    }
}
