//
//  URLSessionCoordinator.swift
//
//
//  Created by Dmytro Anokhin on 07/07/2020.
//

import Foundation
import Combine


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

                    switch error {
                        case .none:
                            downloadTask.complete()
                        case .some(let urlError as URLError):
                            downloadTask.complete(withError: urlError)
                        case .some(let error):
                            assertionFailure("Unknown error: \(error)")
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
    }

    func startDownload(_ download: Download,
                       receiveResponse: @escaping DownloadReceiveResponse,
                       receiveData: @escaping DownloadReceiveData,
                       completion: @escaping DownloadCompletion) {
        async {
            let downloadTaskID = download.id.uuidString

            guard self.registry[downloadTaskID] == nil else {
                assertionFailure("Can not start \(download) twice")
                return
            }

            let observer = DownloadTask.Observer(download: download, receiveResponse: receiveResponse, receiveData: receiveData, completion: completion)

            let downloadTask = self.makeDownloadTask(for: download, withObserver: observer)
            self.registry[downloadTaskID] = downloadTask

            downloadTask.urlSessionTask.resume()
        }
    }

    func cancelDownload(_ download: Download) {
        async {
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

        switch download.destination {
            case .inMemory:
                urlSessionTask = urlSession.dataTask(with: download.url)
            case .onDisk:
                urlSessionTask = urlSession.downloadTask(with: download.url)
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
}
