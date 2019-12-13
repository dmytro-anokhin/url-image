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

    typealias ReceiveResponseCallback = (_ dataTask: URLSessionDataTask, _ response: URLResponse, _ completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) -> Void

    typealias ReceiveDataCallback = (_ dataTask: URLSessionDataTask, _ data: Data) -> Void

    typealias CompleteCallback = (_ task: URLSessionTask, _ error: Error?) -> Void

    var finishDownloadingCallback: FinishDownloadingCallback?

    var writeDataCallback: WriteDataCallback?

    var receiveResponseCallback: ReceiveResponseCallback?

    var receiveDataCallback: ReceiveDataCallback?

    var completeCallback: CompleteCallback?
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        finishDownloadingCallback?(downloadTask, location)
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        writeDataCallback?(downloadTask, bytesWritten, totalBytesWritten, totalBytesExpectedToWrite)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        completeCallback?(task, error)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        if let receiveResponseCallback = receiveResponseCallback {
            receiveResponseCallback(dataTask, response, completionHandler)
        }
        else {
            completionHandler(.allow)
        }
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        receiveDataCallback?(dataTask, data)
    }
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if let customSessionCredentialsDelegate = customSessionCredentialsDelegate {
            customSessionCredentialsDelegate.urlSession?(session, didReceive: challenge, completionHandler: completionHandler)
        }
        else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
    
    func setCustomSessionCredentialsDelegate(_ customSessionCredentialsDelegate: URLSessionDelegate?) {
        self.customSessionCredentialsDelegate = customSessionCredentialsDelegate
    }
    
    private var customSessionCredentialsDelegate: URLSessionDelegate?
}
