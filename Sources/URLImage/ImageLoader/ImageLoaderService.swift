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

    func subscribe(forURL url: URL, incremental: Bool, _ observer: ImageLoaderObserver)

    func unsubscribe(_ observer: ImageLoaderObserver, fromURL url: URL)

    func load(url: URL, delay: TimeInterval)
}


final class ImageLoaderServiceImpl: ImageLoaderService {

    static let shared = ImageLoaderServiceImpl(
        remoteFileCache: RemoteFileCacheServiceImpl.shared,
        inMemoryCacheService: InMemoryCacheServiceDummyImpl()
    )

    init(remoteFileCache: RemoteFileCacheService, inMemoryCacheService: InMemoryCacheService) {
        let urlSessionConfiguration = URLSessionConfiguration.default.copy() as! URLSessionConfiguration
        urlSessionConfiguration.httpMaximumConnectionsPerHost = 1

        urlSessionDelegate = URLSessionDelegateWrapper()
        urlSession = URLSession(configuration: urlSessionConfiguration, delegate: urlSessionDelegate, delegateQueue: queue)

        self.remoteFileCache = remoteFileCache
        self.inMemoryCacheService = inMemoryCacheService

        urlSessionDelegate.finishDownloadingCallback = { task, tmpURL in
            guard let url = task.originalRequest?.url, let downloader = self.urlToDownloaderMap[url] as? FileDownloader else {
                return
            }

            downloader.finishDownloading(with: tmpURL)
        }

        urlSessionDelegate.writeDataCallback = { task, bytesWritten, totalBytesWritten, totalBytesExpectedToWrite in
            guard let url = task.originalRequest?.url, let downloader = self.urlToDownloaderMap[url] as? FileDownloader else {
                return
            }

            if totalBytesExpectedToWrite > 0 {
                let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
                downloader.progress(Float(progress))
            }
            else {
                downloader.progress(nil)
            }
        }

        urlSessionDelegate.receiveDataCallback = { task, data in
            guard let url = task.originalRequest?.url, let downloader = self.urlToDownloaderMap[url] as? DataDownloader else {
                return
            }

            downloader.append(data: data)
        }

        urlSessionDelegate.completeCallback = { task, error in
            guard let url = task.originalRequest?.url, let downloader = self.urlToDownloaderMap[url] else {
                return
            }

            (downloader as? DataDownloader)?.finishDownloading()
            downloader.complete(with: error)
        }
    }

    func subscribe(forURL url: URL, incremental: Bool, _ observer: ImageLoaderObserver) {
        queue.addOperation {
            self.createDownloaderIfNeeded(forURL: url, incremental: incremental)
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
    private let urlSessionDelegate: URLSessionDelegateWrapper

    private let remoteFileCache: RemoteFileCacheService
    private let inMemoryCacheService: InMemoryCacheService

    private var urlToDownloaderMap: [URL: Downloader] = [:]

    private func createDownloaderIfNeeded(forURL url: URL, incremental: Bool) {
        guard urlToDownloaderMap[url] == nil else {
            return
        }

        let downloader: Downloader

        if incremental {
            let task = urlSession.dataTask(with: url)
            downloader = DataDownloader(url: url, task: task, remoteFileCache: remoteFileCache, inMemoryCacheService: inMemoryCacheService)
        }
        else {
            let task = urlSession.downloadTask(with: url)
            downloader = FileDownloader(url: url, task: task, remoteFileCache: remoteFileCache, inMemoryCacheService: inMemoryCacheService)
        }

        downloader.completionCallback = {
            self.urlToDownloaderMap.removeValue(forKey: url)
        }

        urlToDownloaderMap[url] = downloader
    }
}
