//
//  URLSessionDownloadCoordinator.swift
//  
//
//  Created by Dmytro Anokhin on 16/01/2020.
//

import Foundation
import Combine



protocol FileService {

    func file(forRemoteURL remoteURL: URL) -> URL?

    func moveFile(withRemoteURL remoteURL: URL, sourceURL: URL) throws -> URL
}


protocol RequestBuilder {

    func buildRequestForURL(_ url: URL) -> URLRequest
}


struct DefaultRequestBuilder: RequestBuilder {

    func buildRequestForURL(_ url: URL) -> URLRequest {
        URLRequest(url: url, cachePolicy: .reloadIgnoringCacheData, timeoutInterval: 60.0)
    }
}


@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
final class URLSessionDownloadCoordinator : NSObject {

    let fileService: FileService

    let requestBuilder: RequestBuilder

    private var urlSession: URLSession!

    init(fileService: FileService, requestBuilder: RequestBuilder, configuration: URLSessionConfiguration = .default) {
        self.fileService = fileService
        self.requestBuilder = requestBuilder
        super.init()
        urlSession = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }

    typealias DownloadCompletion = (Result<URL, Error>) -> Void

    func downloadFile(with url: URL, completion: @escaping DownloadCompletion) {
        let request = requestBuilder.buildRequestForURL(url)
        downloadFile(with: request, completion: completion)
    }

    func downloadFile(with request: URLRequest, completion: @escaping DownloadCompletion) {
        withTaskWrapperAsync(for: request) { wrapper in
            precondition(request.url != nil)

            if let localURL = self.fileService.file(forRemoteURL: request.url!) {
                log_debug(self, "Local URL found: \(localURL), for remote: \(request.url!)", detail: log_detailed)
                self.complete(url: request.url!, with: .success(localURL))
            }
            else {
                log_debug(self, "Start download for: \(request.url!)", detail: log_detailed)
                wrapper.run()
            }
        }
    }

    func downloadFilePublisher(with url: URL) -> AnyPublisher<Result<URL, Error>, Never> {
        let request = requestBuilder.buildRequestForURL(url)
        return downloadFilePublisher(with: request)
    }

    func downloadFilePublisher(with request: URLRequest) -> AnyPublisher<Result<URL, Error>, Never> {
        let notificationPublisher = withTaskWrapperSync(for: request) { wrapper in
            NotificationCenter.default.publisher(for: DownloadTaskWrapper.Notification.didComplete, object: wrapper)//.receive(on: DispatchQueue.global())
        }

        return notificationPublisher
            .map { notification -> Result<URL, Error> in
                notification.userInfo![DownloadTaskWrapper.Notification.result] as! Result<URL, Error>
            }
            //.receive(on: RunLoop.main)
            .eraseToAnyPublisher()

            //as NotificationCenter.Publisher
    }

    private let synchronizationQueue = DispatchQueue(label: "org.danokhin.URLSessionDownloadCoordinator.synchronizationQueue")

    private var currentTasks: [URL: DownloadTaskWrapper] = [:]

    private func taskWrapper(with url: URL) -> DownloadTaskWrapper? {
        currentTasks[url]
    }

    private func addTaskWrapper(with request: URLRequest) -> DownloadTaskWrapper {
        precondition(request.url != nil)

        let wrapper = DownloadTaskWrapper.make(with: request, urlSession: urlSession)
        currentTasks[request.url!] = wrapper

        return wrapper
    }

    private func discardTaskWrapper(with url: URL) {
        currentTasks[url] = nil
    }

    fileprivate func withTaskWrapperAsync(for url: URL, closure: @escaping (_ taskWrapper: DownloadTaskWrapper) -> Void) {
        synchronizationQueue.async {
            guard let taskWrapper = self.taskWrapper(with: url) else {
                return
            }

            closure(taskWrapper)
        }
    }

    fileprivate func withTaskWrapperAsync(for request: URLRequest, closure: @escaping (_ taskWrapper: DownloadTaskWrapper) -> Void) {
        synchronizationQueue.async {
            precondition(request.url != nil)
            let taskWrapper = self.taskWrapper(with: request.url!) ?? self.addTaskWrapper(with: request)
            closure(taskWrapper)
        }
    }

    fileprivate func withTaskWrapperSync<T>(for request: URLRequest, closure: (_ taskWrapper: DownloadTaskWrapper) -> T) -> T {
        synchronizationQueue.sync {
            precondition(request.url != nil)
            let taskWrapper = self.taskWrapper(with: request.url!) ?? self.addTaskWrapper(with: request)
            return closure(taskWrapper)
        }
    }

    fileprivate func complete(url: URL, with result: Result<URL, Error>) {
        withTaskWrapperAsync(for: url) { wrapper in
            wrapper.complete(with: result)
            self.discardTaskWrapper(with: url)
        }
    }
}


@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
extension URLSessionDownloadCoordinator : URLSessionDelegate {

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            log_debug(self, "Task for: \(task.originalRequest!.url!) did complete with error: \(error)", detail: log_detailed)
        }
        else {
            log_debug(self, "Task for: \(task.originalRequest!.url!) did complete without errors", detail: log_detailed)
        }
    }
}


@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
extension URLSessionDownloadCoordinator : URLSessionDownloadDelegate {

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let url = downloadTask.originalRequest?.url else {
            assertionFailure("Original URL can not be retreived")
            return
        }

        do {
            let persistentURL = try fileService.moveFile(withRemoteURL: url, sourceURL: location)

            log_debug(self, "Download complete for: \(url), to: \(persistentURL)", detail: log_detailed)

            complete(url: url, with: .success(persistentURL))
        }
        catch {
            log_debug(self, "Download complete for: \(url), but the file wasn't moved", detail: log_detailed)
            complete(url: url, with: .failure(error))
        }
    }
}
