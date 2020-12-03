//
//  URLSessionCoordinator.swift
//
//
//  Created by Dmytro Anokhin on 07/07/2020.
//

import Foundation
import Combine

#if canImport(Log)
import Log
#endif


/// `URLSessionCoordinator` manages `URLSession` instance and forwards callbacks to responding `DownloadController` instances.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
final class URLSessionCoordinator {

    init(urlSessionConfiguration: URLSessionConfiguration) {
        let delegate = URLSessionDelegate()
        urlSession = URLSession(configuration: urlSessionConfiguration, delegate: delegate, delegateQueue: nil)

        delegate
            .onTaskDidCompleteWithError { [weak self] urlSessionTask, error in
                guard let self = self else {
                    return
                }

                self.async {
                    let downloadTaskID = urlSessionTask.taskDescription!

                    guard let downloadTask = self.registry[downloadTaskID] else {
                        // This can happen when the task was cancelled
                        return
                    }

                    self.registry[downloadTaskID] = nil

                    if let error = error {
                        downloadTask.complete(withError: error)
                    }
                    else {
                        downloadTask.complete()
                    }
                }
            }
            .onDataTaskDidReceiveData { [weak self] urlSessionTask, data in
                guard let self = self else {
                    return
                }

                self.async {
                    let downloadTaskID = urlSessionTask.taskDescription!

                    guard let downloadTask = self.registry[downloadTaskID] else {
                        // This can happen when the task was cancelled
                        return
                    }

                    downloadTask.receive(data: data)
                }
            }
            .onDataTaskDidReceiveResponse { [weak self] task, response, completion in
                guard let self = self else {
                    completion(.cancel)
                    return
                }

                self.async {
                    let downloadTaskID = task.taskDescription!

                    guard let downloadTask = self.registry[downloadTaskID] else {
                        // This can happen when the task was cancelled
                        completion(.cancel)
                        return
                    }

                    downloadTask.receive(response: response)
                    completion(.allow)
                }
            }
            .onDownloadTaskDidFinishDownloadingTo { [weak self] task, location in
                guard let self = self else {
                    return
                }

                self.sync {
                    let downloadTaskID = task.taskDescription!

                    guard let downloadTask = self.registry[downloadTaskID] else {
                        // This can happen when the task was cancelled
                        return
                    }

                    guard case Download.Destination.onDisk(let path) = downloadTask.download.destination else {
                        assertionFailure("Expected file path destination for download task")
                        return
                    }

                    let destination = URL(fileURLWithPath: path)
                    try? FileManager.default.moveItem(at: location, to: destination)
                }
            }
            .onDownloadTaskDidWriteData { [weak self] task, _, totalBytesWritten, totalBytesExpectedToWrite in
                guard let self = self else {
                    return
                }

                self.async {
                    let downloadTaskID = task.taskDescription!

                    guard let downloadTask = self.registry[downloadTaskID] else {
                        // This can happen when the task was cancelled
                        return
                    }

                    downloadTask.downloadProgress(received: totalBytesWritten, expected: totalBytesExpectedToWrite)
                }
            }
    }

    func startDownload(_ download: Download,
                       receiveResponse: @escaping DownloadReceiveResponse,
                       receiveData: @escaping DownloadReceiveData,
                       reportProgress: @escaping DownloadReportProgress,
                       completion: @escaping DownloadCompletion) {
        async {
            log_debug(self, #function, "download.id = \(download.id), download.url: \(download.url)", detail: log_normal)

            let downloadTaskID = download.id.uuidString

            guard self.registry[downloadTaskID] == nil else {
                assertionFailure("Can not start \(download) twice")
                return
            }

            let observer = DownloadTask.Observer(download: download, receiveResponse: receiveResponse, receiveData: receiveData, reportProgress: reportProgress, completion: completion)

            let downloadTask = self.makeDownloadTask(for: download, withObserver: observer)
            self.registry[downloadTaskID] = downloadTask

            downloadTask.urlSessionTask.resume()
        }
    }

    func cancelDownload(_ download: Download) {
        async {
            log_debug(self, #function, "download.id = \(download.id), download.url: \(download.url)", detail: log_normal)

            let downloadTaskID = download.id.uuidString

            guard let downloadTask = self.registry[downloadTaskID] else {
                return
            }

            downloadTask.urlSessionTask.cancel()
            self.registry[downloadTaskID] = nil
        }
    }

    // MARK: - Private

    private let urlSession: URLSession

    private func makeDownloadTask(for download: Download, withObserver observer: DownloadTask.Observer) -> DownloadTask {
        let urlSessionTask: URLSessionTask

        var request = URLRequest(url: download.url)
        request.allHTTPHeaderFields = download.urlRequestConfiguration.allHTTPHeaderFields

        switch download.destination {
            case .inMemory:
                urlSessionTask = urlSession.dataTask(with: request)
            case .onDisk:
                urlSessionTask = urlSession.downloadTask(with: request)
        }

        urlSessionTask.taskDescription = download.id.uuidString

        return DownloadTask(download: download, urlSessionTask: urlSessionTask, observer: observer)
    }

    private typealias DownloadTaskID = String

    private var registry: [DownloadTaskID: DownloadTask] = [:]

    private let serialQueue = DispatchQueue(label: "URLSessionCoordinator.serialQueue")

    private func async(_ closure: @escaping () -> Void) {
        serialQueue.async(execute: closure)
    }

    private func sync(_ closure: () -> Void) {
        serialQueue.sync(execute: closure)
    }
}
