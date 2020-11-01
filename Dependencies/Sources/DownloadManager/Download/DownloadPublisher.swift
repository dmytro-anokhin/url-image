//
//  DownloadPublisher.swift
//  
//
//  Created by Dmytro Anokhin on 28/07/2020.
//

import Combine

#if canImport(Log)
import Log
#endif


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

        log_debug(self, #function, "download.id = \(download.id), download.url = \(self.download.url)", detail: log_detailed)

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
                                log_debug(self, #function, "download.id = \(self.download.id), download.url = \(self.download.url), downloaded \(data.count) bytes", detail: log_detailed)
                            case .file(let path):
                                log_debug(self, #function, "download.id = \(self.download.id), download.url = \(self.download.url), downloaded file to \(path)", detail: log_detailed)
                        }

                        let _ = self.subscriber?.receive(.completion(downloadResult))
                        self.subscriber?.receive(completion: .finished)

                    case .failure(let error):
                        log_debug(self, #function, "download.id = \(self.download.id), download.url = \(self.download.url), downloaded failed \(error)", detail: log_detailed)
                        self.subscriber?.receive(completion: .failure(error))
                }

                self.manager.reset(download: self.download)
            })
    }

    func cancel() {
        log_debug(self, #function, "download.id = \(download.id), download.url = \(self.download.url)", detail: log_detailed)
        manager.coordinator.cancelDownload(download)
        manager.reset(download: download)
    }
}
