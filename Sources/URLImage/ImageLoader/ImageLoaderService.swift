//
//  ImageLoaderService.swift
//  URLImage
//
//
//  Created by Dmytro Anokhin on 28/08/2019.
//  Copyright © 2019 Dmytro Anokhin. All rights reserved.
//

import Foundation
import CoreGraphics


@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
protocol ImageLoaderService: AnyObject {

    func subscribe(forURLRequest urlRequest: URLRequest, incremental: Bool, processor: ImageProcessing?, _ observer: ImageLoaderObserver)

    func unsubscribe(_ observer: ImageLoaderObserver, fromURLRequest urlRequest: URLRequest)

    func load(urlRequest: URLRequest, after delay: TimeInterval, expiryDate: Date?)
}


@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
final class ImageLoaderServiceImpl: ImageLoaderService {

    init(remoteFileCache: RemoteFileCacheService, imageProcessingService: ImageProcessingService) {
        let urlSessionConfiguration = URLSessionConfiguration.default.copy() as! URLSessionConfiguration
        urlSessionConfiguration.httpMaximumConnectionsPerHost = 1

        urlSessionDelegate = URLSessionDelegateWrapper()
        urlSession = URLSession(configuration: urlSessionConfiguration, delegate: urlSessionDelegate, delegateQueue: queue)

        self.remoteFileCache = remoteFileCache
        self.imageProcessingService = imageProcessingService

        func downloaderForTask(_ task: URLSessionTask) -> Downloader? {
            guard let urlRequest = task.originalRequest else {
                return nil
            }

            return urlRequestToDownloaderMap[urlRequest]
        }

        urlSessionDelegate.finishDownloadingCallback = { task, tmpURL in
            guard let downloader = downloaderForTask(task) as? FileDownloader else {
                return
            }

            downloader.finishDownloading(with: tmpURL)
        }

        urlSessionDelegate.writeDataCallback = { task, bytesWritten, totalBytesWritten, totalBytesExpectedToWrite in
            guard let downloader = downloaderForTask(task) as? FileDownloader else {
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
            guard let downloader = downloaderForTask(task) as? DataDownloader else {
                return
            }

            downloader.append(data: data)
        }

        urlSessionDelegate.completeCallback = { task, error in
            guard let downloader = downloaderForTask(task) else {
                return
            }

            (downloader as? DataDownloader)?.finishDownloading()
            downloader.complete(with: error)
        }
    }

    func subscribe(forURLRequest urlRequest: URLRequest, incremental: Bool, processor: ImageProcessing?, _ observer: ImageLoaderObserver) {
        queue.addOperation {
            self.createDownloaderIfNeeded(forURLRequest: urlRequest, incremental: incremental)
            let handler = ImageLoadHandler(processor: processor, observer: observer)
            self.urlRequestToDownloaderMap[urlRequest]?.addHandler(handler)
        }
    }

    func unsubscribe(_ observer: ImageLoaderObserver, fromURLRequest urlRequest: URLRequest) {
        queue.addOperation {
            guard let task = self.urlRequestToDownloaderMap[urlRequest] else {
                return
            }

            let handlersToRemove = task.handlers.filter { $0.observer === observer }

            for handler in handlersToRemove {
                task.removeHandler(handler)
            }

            if task.handlers.isEmpty {
                self.urlRequestToDownloaderMap[urlRequest]?.cancel()
            }
        }
    }

    func load(urlRequest: URLRequest, after delay: TimeInterval, expiryDate: Date?) {
        queue.addOperation {
            guard let downloader = self.urlRequestToDownloaderMap[urlRequest] else {
                assertionFailure("Downloader must be created before calling load")
                return
            }

            if let expiryDate = expiryDate {
                if let currentExpiryDate = downloader.expiryDate {
                    // If there is expiry date make sure to use the latest of two
                    downloader.expiryDate = currentExpiryDate < expiryDate ? expiryDate : currentExpiryDate
                }
                else {
                    downloader.expiryDate = expiryDate
                }
            }

            downloader.resume(after: delay)
        }
    }

    // MARK: Private

    private let queue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "URLImage.ImageLoaderServiceImpl.queue"
        queue.maxConcurrentOperationCount = 1

        return queue
    }()

    private let urlSession: URLSession
    private let urlSessionDelegate: URLSessionDelegateWrapper

    private unowned let remoteFileCache: RemoteFileCacheService
    private unowned let imageProcessingService: ImageProcessingService

    private var _urlRequestToDownloaderMap: [URLRequest: Downloader] = [:]

    private var urlRequestToDownloaderMap: [URLRequest: Downloader] {
        get {
            assert(OperationQueue.current === queue, "Must only be accessed on the designated queue: '\(queue.name!)'")
            return _urlRequestToDownloaderMap
        }

        set {
            assert(OperationQueue.current === queue, "Must only be accessed on the designated queue: '\(queue.name!)'")
            _urlRequestToDownloaderMap = newValue
        }
    }

    private func createDownloaderIfNeeded(forURLRequest urlRequest: URLRequest, incremental: Bool) {
        guard urlRequestToDownloaderMap[urlRequest] == nil else {
            return
        }

        let downloader: Downloader

        if incremental {
            let task = urlSession.dataTask(with: urlRequest)
            downloader = DataDownloader(url: urlRequest.url!, task: task, remoteFileCache: remoteFileCache, imageProcessingService: imageProcessingService)
        }
        else {
            let task = urlSession.downloadTask(with: urlRequest)
            downloader = FileDownloader(url: urlRequest.url!, task: task, remoteFileCache: remoteFileCache, imageProcessingService: imageProcessingService)
        }

        downloader.completionCallback = {
            self.queue.addOperation {
                self.urlRequestToDownloaderMap.removeValue(forKey: urlRequest)
            }
        }

        urlRequestToDownloaderMap[urlRequest] = downloader
    }
}
