//
//  URLSessionDelegateWrapper.swift
//  
//
//  Created by Dmytro Anokhin on 19/09/2019.
//

import Foundation


open class URLSessionDelegateWrapper: NSObject, URLSessionDataDelegate, URLSessionDownloadDelegate {

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
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        finishDownloadingCallback?(downloadTask, location)
    }

    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        writeDataCallback?(downloadTask, bytesWritten, totalBytesWritten, totalBytesExpectedToWrite)
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        completeCallback?(task, error)
    }
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        if let receiveResponseCallback = receiveResponseCallback {
            receiveResponseCallback(dataTask, response, completionHandler)
        }
        else {
            completionHandler(.allow)
        }
    }

    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        receiveDataCallback?(dataTask, data)
    }
}

public class CustomURLSessionDelegate : URLSessionDelegateWrapper {
    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge,
                           completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if (challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust) {
            if (challenge.protectionSpace.host.isIpAddress()) {
                let credential = URLCredential(trust: challenge.protectionSpace.serverTrust!)
                completionHandler(URLSession.AuthChallengeDisposition.useCredential, credential)
                return
            }
        }
        completionHandler(.performDefaultHandling, nil)
    }
}

extension String {
    func isIPv4() -> Bool {
        var sin = sockaddr_in()
        return self.withCString({ cstring in inet_pton(AF_INET, cstring, &sin.sin_addr) }) == 1
    }

    func isIPv6() -> Bool {
        var sin6 = sockaddr_in6()
        return self.withCString({ cstring in inet_pton(AF_INET6, cstring, &sin6.sin6_addr) }) == 1
    }

    func isIpAddress() -> Bool { return self.isIPv6() || self.isIPv4() }
}

