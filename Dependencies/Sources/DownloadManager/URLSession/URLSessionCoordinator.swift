//
//  URLSessionCoordinator.swift
//
//
//  Created by Dmytro Anokhin on 07/07/2020.
//

import Foundation
import Log

@globalActor
public actor URLSessionCoordinatorActor {
    public static let shared = URLSessionCoordinatorActor()
}


/// `URLSessionCoordinator` manages `URLSession` instance and forwards callbacks to responding `DownloadController` instances.
@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
final class URLSessionCoordinator: Sendable {

    init(urlSessionConfiguration: URLSessionConfiguration) {
        let coordinator = self._coordinator
        let delegate = URLSessionDelegate { [weak coordinator] state in
            Task {
                await coordinator?.notify(state)
            }
        }
        urlSession = URLSession(configuration: urlSessionConfiguration, delegate: delegate, delegateQueue: nil)
    }
    
    deinit {
        urlSession.invalidateAndCancel()
    }

    func startDownload(_ download: Download,
                       receiveResponse: @escaping DownloadReceiveResponse,
                       receiveData: @escaping DownloadReceiveData,
                       reportProgress: @escaping DownloadReportProgress,
                       completion: @escaping DownloadCompletion) {
        let coodinator = self._coordinator
        let session = self.urlSession
        Task { @URLSessionCoordinatorActor in
            await coodinator.startDownload(download, receiveResponse: receiveResponse, receiveData: receiveData, reportProgress: reportProgress, completion: completion, makeDownloadTask: { download, observer in
                makeDownloadTask(for: download, urlSession: session, withObserver: observer)
            })
        }
    }
    
    func startDownload(_ download: Download) -> AsyncStream<DownloadStatus> {
        let coodinator = self._coordinator
        let session = self.urlSession
        let (stream, continuation) = AsyncStream<DownloadStatus>.makeStream(bufferingPolicy: .bufferingNewest(1))
        let downloadTaskID = download.id.uuidString
        let task = Task { @URLSessionCoordinatorActor [weak coodinator] in
            guard let coodinator else { return }
            await coodinator.startDownload(download, continuation: continuation, downloadTaskID: downloadTaskID, makeDownloadTask: { download, observer in
                makeDownloadTask(for: download, urlSession: session, withObserver: observer)
            })
        }
        continuation.onTermination = { [weak coodinator] termination in
            task.cancel()
            guard let coodinator else { return }
            Task { @URLSessionCoordinatorActor in
                await coodinator.completed(downloadTaskID)
            }
        }
        return stream
    }

    func cancelDownload(_ download: Download) {
        let coodinator = self._coordinator
        Task { @URLSessionCoordinatorActor in
            await coodinator.cancel(download)
        }
    }
    
//    func taskStateStream() -> AsyncStream<URLSessionDelegate.TaskState> {
//        let id = UUID()
//        let coordinator = self._coordinator
//        return AsyncStream { continuation in
//            Task {
//                await coordinator.store(continuation, id: id)
//            }
//        }
//    }

    // MARK: - Private

    private let urlSession: URLSession
    private typealias DownloadTaskID = String

//    @URLSessionCoordinatorActor
//    private var registry: [DownloadTaskID: DownloadTask] = [:]
    private let _coordinator = RealURLSessionCoordinator()
}

fileprivate actor RealURLSessionCoordinator {
    typealias DownloadTaskID = String
    private var registry: [DownloadTaskID: DownloadTask] = [:]
//    private var continuations: [UUID: AsyncStream<URLSessionDelegate.TaskState>.Continuation] = [:]
    
    deinit {
        registry.removeAll()
        
//        continuations.removeAll()
    }
    
    func notify(_ state: URLSessionDelegate.TaskState) async {
        switch state {
        case .didCompleteWithError(let downloadTask, let error):
            for (id, task) in registry where task.urlSessionTask.taskIdentifier == downloadTask.taskIdentifier {
                await update(state, with: id)
            }
        case .didReceiveResponse(let downloadTask, let response, let completionHandler):
            for (id, task) in registry where task.urlSessionTask.taskIdentifier == downloadTask.taskIdentifier {
                await update(state, with: id)
            }
        case .didReceiveData(let downloadTask, let data):
            for (id, task) in registry where task.urlSessionTask.taskIdentifier == downloadTask.taskIdentifier {
                await update(state, with: id)
            }
        case .didFinishDownloadingTo(let downloadTask, let location):
            for (id, task) in registry where task.urlSessionTask.taskIdentifier == downloadTask.taskIdentifier {
                await update(state, with: id)
            }
        case .downloadTaskDidWriteData(let downloadTask, let bytesWritten, let totalBytesWritten, let totalBytesExpectedToWrite):
            for (id, task) in registry where task.urlSessionTask.taskIdentifier == downloadTask.taskIdentifier {
                await update(state, with: id)
            }
        }
    }
    
//    func store(_ continuation: AsyncStream<URLSessionDelegate.TaskState>.Continuation, id: UUID) {
//        continuations[id] = continuation
//        continuation.onTermination = { [weak self] _ in
//            Task {
//                await self?.unstore(id)
//            }
//        }
//    }
//    
//    func unstore(_ id: UUID) {
//        continuations.removeValue(forKey: id)
//    }
    
    func update(_ state: URLSessionDelegate.TaskState, with downloadTaskID: DownloadTaskID) async {
        switch state {
        case .didCompleteWithError(let urlSessionTask, let error):
            guard let downloadTask = self.registry[downloadTaskID] else {
                // This can happen when the task was cancelled
                return
            }
            
            if let error = error {
                await downloadTask.complete(withError: error)
            } else {
                await downloadTask.complete()
            }
            self.registry[downloadTaskID] = nil
        case .didReceiveResponse(let task, let response, let completion):
            guard let downloadTask = self.registry[downloadTaskID] else {
                // This can happen when the task was cancelled
                completion(.cancel)
                return
            }

            downloadTask.receive(response: response)
            completion(.allow)
        case .didReceiveData(let urlSessionTask, let data):
            guard let downloadTask = self.registry[downloadTaskID] else {
                // This can happen when the task was cancelled
                return
            }

            downloadTask.receive(data: data)
        case .didFinishDownloadingTo(let task, let location):
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
        case .downloadTaskDidWriteData(let downloadTask, _, let totalBytesWritten, let totalBytesExpectedToWrite):
            guard let downloadTask = self.registry[downloadTaskID] else {
                // This can happen when the task was cancelled
                return
            }

            downloadTask.downloadProgress(received: totalBytesWritten, expected: totalBytesExpectedToWrite)
        }
    }
    
    func startDownload(_ download: Download,
                       receiveResponse: @escaping DownloadReceiveResponse,
                       receiveData: @escaping DownloadReceiveData,
                       reportProgress: @escaping DownloadReportProgress,
                       completion: @escaping DownloadCompletion, makeDownloadTask: @escaping @Sendable (Download, DownloadTask.Observer) -> DownloadTask) {
        log_debug(self, #function, "download.id = \(download.id), download.url: \(download.url)", detail: log_normal)

        let downloadTaskID = download.id.uuidString

        guard self.registry[downloadTaskID] == nil else {
            assertionFailure("Can not start \(download) twice")
            return
        }

        let observer = DownloadTask.Observer(download: download, receiveResponse: receiveResponse, receiveData: receiveData, reportProgress: reportProgress, completion: completion)

        let downloadTask = makeDownloadTask(download, observer)
        self.registry[downloadTaskID] = downloadTask

        downloadTask.urlSessionTask.resume()
    }
    
    func completed(_ id: DownloadTaskID) {
        guard let item = self.registry[id] else { return }
        self.registry.removeValue(forKey: id)
        if item.urlSessionTask.progress.fractionCompleted < 1 {
            print("cancel url session task for \(id) - \(item.download.url)")
            item.urlSessionTask.cancel()
        }
    }
    
    func startDownload(_ download: Download, continuation: AsyncStream<DownloadStatus>.Continuation, downloadTaskID: DownloadTaskID, makeDownloadTask: @escaping @Sendable (Download, DownloadTask.Observer) -> DownloadTask) {
        log_debug(self, #function, "download.id = \(download.id), download.url: \(download.url)", detail: log_normal)

        guard self.registry[downloadTaskID] == nil else {
            assertionFailure("Can not start \(download) twice")
            return
        }

        let observer = DownloadTask.Observer(download: download) { _ in
            
        } receiveData: { _, _ in
            
        } reportProgress: { _, progress in
            continuation.yield(.reportProgress(download: download, progress))
        } completion: { download, result in
            continuation.yield(.completion(download: download, result))
            continuation.finish()
        }
        
        let downloadTask = makeDownloadTask(download, observer)
        self.registry[downloadTaskID] = downloadTask

        downloadTask.urlSessionTask.resume()
    }
    
    func cancel(_ download: Download) {
        log_debug(self, #function, "download.id = \(download.id), download.url: \(download.url)", detail: log_normal)

        let downloadTaskID = download.id.uuidString

        guard let downloadTask = self.registry[downloadTaskID] else {
            return
        }

        downloadTask.urlSessionTask.cancel()
        self.registry[downloadTaskID] = nil
    }
    
//    func observer(_ delegate: AsyncStream<URLSessionDelegate.TaskState>) async {
//        for await state in delegate {
//            switch state {
//            case .didFinishDownloadingTo(let task, let location):
//                await update(state)
//            default:
//                Task { @URLSessionCoordinatorActor in
//                    await update(state)
//                }
//            }
//        }
//    }
}


func makeDownloadTask(for download: Download, urlSession: URLSession, withObserver observer: DownloadTask.Observer) -> DownloadTask {
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
