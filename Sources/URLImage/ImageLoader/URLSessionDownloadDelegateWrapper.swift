//
//  URLSessionDownloadDelegateWrapper.swift
//  
//
//  Created by Dmytro Anokhin on 19/09/2019.
//

import Foundation


final class URLSessionDownloadDelegateWrapper: NSObject, URLSessionDownloadDelegate {

    typealias CompletionCallback = (_ downloadTask: URLSessionDownloadTask, _ location: URL) -> Void

    typealias ProgressCallback = (_ downloadTask: URLSessionDownloadTask, _ bytesWritten: Int64, _ totalBytesWritten: Int64, _ totalBytesExpectedToWrite: Int64) -> Void

    typealias FailureCallback = (_ task: URLSessionTask, _ error: Error) -> Void

    var completionCallback: CompletionCallback?

    var progressCallback: ProgressCallback?

    var failureCallback: FailureCallback?

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        completionCallback?(downloadTask, location)
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        progressCallback?(downloadTask, bytesWritten, totalBytesWritten, totalBytesExpectedToWrite)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error = error else {
            return
        }

        failureCallback?(task, error)
    }
}
