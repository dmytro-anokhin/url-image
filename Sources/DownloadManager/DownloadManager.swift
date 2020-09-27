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

    private let coordinator: URLSessionCoordinator

    public init(urlCache: URLCache = URLCache()) {
        let configuration = URLSessionConfiguration.default

        configuration.requestCachePolicy = .returnCacheDataElseLoad
        configuration.urlCache = urlCache

        coordinator = URLSessionCoordinator(urlSessionConfiguration: configuration)
    }

    public typealias DownloadTaskPublisher = Publishers.Share<DownloadPublisher>

    public func publisher(for download: Download) -> DownloadTaskPublisher {
        sync {
            let publisher = publishers[download] ?? DownloadPublisher(download: download, coordinator: coordinator).share()
            publishers[download] = publisher

            return publisher
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
