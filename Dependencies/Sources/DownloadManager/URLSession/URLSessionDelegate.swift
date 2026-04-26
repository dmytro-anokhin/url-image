//
//  URLSessionDelegate.swift
//  
//
//  Created by Dmytro Anokhin on 13/07/2020.
//

import Foundation
import Log

//@globalActor
//public actor URLSessionActor {
//    public static let shared = URLSessionActor()
//}

final class URLSessionDelegate : NSObject {
    // 定义任务的状态枚举
    enum TaskState {
        case didCompleteWithError(task: URLSessionTask, error: Error?)
        case didReceiveResponse(task: URLSessionDataTask,  response: URLResponse, completionHandler: @Sendable (URLSession.ResponseDisposition) -> Void)
        case didReceiveData(task: URLSessionDataTask, data: Data)
        case didFinishDownloadingTo(downloadTask: URLSessionDownloadTask, location: URL)
        case downloadTaskDidWriteData(downloadTask: URLSessionDownloadTask, bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64)
    }
    
//    @URLSessionActor
//    private var continuations: [UUID: AsyncStream<TaskState>.Continuation] = [:]
    
    let onTaskStateUpdate: (@Sendable (TaskState) -> Void)?
    
    init(onTaskStateUpdate: (@Sendable (TaskState) -> Void)?) {
        self.onTaskStateUpdate = onTaskStateUpdate
    }
    
//    func taskStateStream() -> AsyncStream<TaskState> {
//        let id = UUID()
//        return AsyncStream { continuation in
//            Task { @URLSessionActor [weak self] in
//                self?.continuations[id] = continuation
//                continuation.onTermination = { _ in
//                    Task { @URLSessionActor in
//                        self?.continuations.removeValue(forKey: id)
//                    }
//                }
//            }
//        }
//    }
    
    private func broadcast(_ state: TaskState) {
//        Task { @URLSessionActor [weak self] in
//            guard let self else { return }
//            for (_, continuation) in self.continuations {
//                continuation.yield(state)
//            }
//        }
        onTaskStateUpdate?(state)
    }
    
//    deinit {
//        continuations.removeAll()
//    }
}


extension URLSessionDelegate : Foundation.URLSessionDelegate {
    
}


extension URLSessionDelegate : URLSessionTaskDelegate {
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        log_debug(self, #function, "\(String(describing: task.originalRequest))", detail: log_detailed)
        broadcast(.didCompleteWithError(task: task, error: error))
    }
}


extension URLSessionDelegate : URLSessionDataDelegate {

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @Sendable @escaping (URLSession.ResponseDisposition) -> Void) {
        log_debug(self, #function, "\(String(describing: dataTask.originalRequest))", detail: log_detailed)
        broadcast(.didReceiveResponse(task: dataTask, response: response, completionHandler: completionHandler))
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        log_debug(self, #function, "\(String(describing: dataTask.originalRequest))", detail: log_detailed)
        broadcast(.didReceiveData(task: dataTask, data: data))
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, willCacheResponse proposedResponse: CachedURLResponse, completionHandler: @escaping (CachedURLResponse?) -> Void) {
        log_debug(self, #function, "\(String(describing: dataTask.originalRequest))", detail: log_detailed)
        completionHandler(proposedResponse)
    }
}


extension URLSessionDelegate : URLSessionDownloadDelegate {

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        log_debug(self, #function, "\(String(describing: downloadTask.originalRequest))", detail: log_detailed)
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        do {
            try FileManager.default.moveItem(at: location, to: tempURL)
            broadcast(.didFinishDownloadingTo(downloadTask: downloadTask, location: tempURL))
        } catch {
            print("move file failed \(error)")
            broadcast(.didFinishDownloadingTo(downloadTask: downloadTask, location: location))
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        log_debug(self, #function, "\(String(describing: downloadTask.originalRequest))", detail: log_detailed)
        broadcast(.downloadTaskDidWriteData(downloadTask: downloadTask, bytesWritten: bytesWritten, totalBytesWritten: totalBytesWritten, totalBytesExpectedToWrite: totalBytesExpectedToWrite))
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
        log_debug(self, #function, "\(String(describing: downloadTask.originalRequest))", detail: log_detailed)
    }
}
