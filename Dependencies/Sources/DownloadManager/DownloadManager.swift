//
//  DownloadManager.swift
//  
//
//  Created by Dmytro Anokhin on 29/07/2020.
//

import Foundation
import Combine


@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public final class DownloadManager {

    let coordinator: URLSessionCoordinator

    public init() {
        let configuration = URLSessionConfiguration.default
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData

        coordinator = URLSessionCoordinator(urlSessionConfiguration: configuration)
    }

    public typealias DownloadTaskPublisher = Publishers.Share<DownloadPublisher>

    public func publisher(for download: Download) -> DownloadTaskPublisher {
        sync {
            let publisher = publishers[download] ?? DownloadPublisher(download: download, manager: self).share()
            publishers[download] = publisher

            return publisher
        }
    }

    public func reset(download: Download) {
        async { [weak self] in
            guard let self = self else {
                return
            }

            self.publishers[download] = nil
        }
    }

    private var publishers: [Download: DownloadTaskPublisher] = [:]

    private let serialQueue = DispatchQueue(label: "DownloadManager.serialQueue")

    private func async(_ closure: @escaping () -> Void) {
        serialQueue.async(execute: closure)
    }

    private func sync<T>(_ closure: () -> T) -> T {
        serialQueue.sync(execute: closure)
    }
}
