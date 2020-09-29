//
//  DownloadTask.swift
//  
//
//  Created by Dmytro Anokhin on 08/07/2020.
//

import Foundation


/// `DownloadTask` is a wrapper around `URLSessionTask` that accumulates received data in a memory buffer.
final class DownloadTask {

    final class Observer {

        private var receiveData: DownloadReceiveData?

        func notifyReceiveData(_ data: Data) {
            receiveData?(download, data)
        }

        private var completion: DownloadCompletion?

        func notifyCompletion(_ result: Result<DownloadResult, DownloadError>) {
            completion?(download, result)
        }

        public let download: Download

        init(download: Download, receiveData: DownloadReceiveData?, completion: DownloadCompletion?) {
            self.download = download
            self.receiveData = receiveData
            self.completion = completion
        }
    }

    let download: Download

    let urlSessionTask: URLSessionTask

    let observer: Observer

    init(download: Download, urlSessionTask: URLSessionTask, observer: Observer) {
        self.download = download
        self.urlSessionTask = urlSessionTask
        self.observer = observer
        serialQueue = DispatchQueue(label: "DownloadController.serialQueue." + download.id.uuidString)
    }

    func complete(withError error: URLError? = nil) {
        serialQueue.async {
            if let error = error {
                self.observer.notifyCompletion(.failure(error))
            }
            else if let data = self.buffer {
                self.observer.notifyCompletion(.success(.data(data)))
            }
            else {
                self.observer.notifyCompletion(.failure(URLError(.unknown)))
            }
        }
    }

    func receive(data: Data) {
        serialQueue.async {
            self.append(data)
            self.observer.notifyReceiveData(data)
        }
    }

    fileprivate let serialQueue: DispatchQueue

    private var buffer: Data?

    private func append(_ data: Data) {
        if buffer == nil {
            buffer = Data()
        }

        buffer?.append(data)
    }
}


extension DownloadTask : CustomStringConvertible {

    var description: String {
        "<DownloadTask \(Unmanaged.passUnretained(self).toOpaque()): download=\(download)>"
    }
}
