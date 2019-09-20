//
//  ImageLoaderService.swift
//  URLImage
//
//
//  Created by Dmytro Anokhin on 28/08/2019.
//  Copyright © 2019 Dmytro Anokhin. All rights reserved.
//

import Foundation


protocol ImageLoaderService {

    func subscribe(forURL url: URL, _ observer: ImageLoaderObserver)

    func unsubscribe(_ observer: ImageLoaderObserver, fromURL url: URL)

    func load(url: URL, delay: TimeInterval)
}


final class ImageLoaderServiceImpl: ImageLoaderService {

    static let shared = ImageLoaderServiceImpl(
        remoteFileCache: RemoteFileCacheServiceImpl.shared,
        inMemoryCacheService: InMemoryCacheServiceImpl.shared
    )

    init(remoteFileCache: RemoteFileCacheService, inMemoryCacheService: InMemoryCacheService) {
        let urlSessionConfiguration = URLSessionConfiguration.default.copy() as! URLSessionConfiguration
        urlSessionConfiguration.httpMaximumConnectionsPerHost = 1

        urlSessionDelegate = URLSessionDownloadDelegateWrapper()
        urlSession = URLSession(configuration: urlSessionConfiguration, delegate: urlSessionDelegate, delegateQueue: queue)

        self.remoteFileCache = remoteFileCache
        self.inMemoryCacheService = inMemoryCacheService

        urlSessionDelegate.completionCallback = { task, tmpURL in
            guard let url = task.originalRequest?.url else {
                return
            }

            self.urlToDownloaderMap[url]?.complete(with: tmpURL)
        }

        urlSessionDelegate.progressCallback = { _, _, _, _ in
        }

        urlSessionDelegate.failureCallback = { task, error in
            guard let url = task.originalRequest?.url else {
                return
            }

            self.urlToDownloaderMap[url]?.fail(with: error)
        }
    }

    func subscribe(forURL url: URL, _ observer: ImageLoaderObserver) {
        queue.addOperation {
            self.createDownloaderIfNeeded(forURL: url)
            self.urlToDownloaderMap[url]?.addObserver(observer)
        }
    }

    func unsubscribe(_ observer: ImageLoaderObserver, fromURL url: URL) {
        queue.addOperation {
            guard let task = self.urlToDownloaderMap[url] else {
                return
            }

            task.removeObserver(observer)

            if task.observers.isEmpty {
                self.urlToDownloaderMap[url]?.cancel()
            }
        }
    }

    func load(url: URL, delay: TimeInterval) {
        queue.addOperation {
            guard self.urlToDownloaderMap[url] != nil else {
                assert(self.urlToDownloaderMap[url] != nil, "Downloader must be created before calling load")
                return
            }

            self.urlToDownloaderMap[url]?.resume(after: delay)
        }
    }

    // MARK: Private

    private let queue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "URLImage.ImageLoaderService.queue"
        queue.maxConcurrentOperationCount = 1

        return queue
    }()

    private let urlSession: URLSession
    private let urlSessionDelegate: URLSessionDownloadDelegateWrapper

    private let remoteFileCache: RemoteFileCacheService
    private let inMemoryCacheService: InMemoryCacheService

    private var urlToDownloaderMap: [URL: Downloader] = [:]

    private func createDownloaderIfNeeded(forURL url: URL) {
        guard urlToDownloaderMap[url] == nil else {
            return
        }

        let task = Downloader(url: url, task: urlSession.downloadTask(with: url), remoteFileCache: remoteFileCache, inMemoryCacheService: inMemoryCacheService)

        task.completionCallback = {
            self.urlToDownloaderMap.removeValue(forKey: url)
        }

        urlToDownloaderMap[url] = task
    }
}
