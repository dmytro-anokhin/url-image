//
//  URLSessionDelegateWrapper.swift
//  
//
//  Created by Dmytro Anokhin on 19/09/2019.
//

import Foundation


final class URLSessionDelegateWrapper: NSObject, URLSessionDataDelegate, URLSessionDownloadDelegate {

    typealias FinishDownloadingCallback = (_ downloadTask: URLSessionDownloadTask, _ location: URL) -> Void

    typealias WriteDataCallback = (_ downloadTask: URLSessionDownloadTask, _ bytesWritten: Int64, _ totalBytesWritten: Int64, _ totalBytesExpectedToWrite: Int64) -> Void

    typealias ReceiveDataCallback = (_ dataTask: URLSessionDataTask, _ data: Data) -> Void

    typealias CompleteCallback = (_ task: URLSessionTask, _ error: Error?) -> Void

    var finishDownloadingCallback: FinishDownloadingCallback?

    var writeDataCallback: WriteDataCallback?

    var receiveDataCallback: ReceiveDataCallback?

    var completeCallback: CompleteCallback?

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        // print("didFinishDownloadingTo \(downloadTask.originalRequest?.url?.lastPathComponent)")
        finishDownloadingCallback?(downloadTask, location)
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        // print("didWriteData \(downloadTask.originalRequest?.url?.lastPathComponent)")
        writeDataCallback?(downloadTask, bytesWritten, totalBytesWritten, totalBytesExpectedToWrite)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        // print("didCompleteWithError \(task.originalRequest?.url?.lastPathComponent) error: \(error)")
        completeCallback?(task, error)
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        // print("didReceive data \(dataTask.originalRequest?.url?.lastPathComponent)")
        receiveDataCallback?(dataTask, data)
    }

//    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
//        print("didReceive response \(dataTask.originalRequest?.url?.lastPathComponent)")
//    }
}
