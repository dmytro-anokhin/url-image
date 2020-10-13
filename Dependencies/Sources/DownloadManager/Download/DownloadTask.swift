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

        private var receiveResponse: DownloadReceiveResponse?

        func notifyReceiveResponse() {
            receiveResponse?(download)
        }

        private var receiveData: DownloadReceiveData?

        func notifyReceiveData(_ data: Data, _ progress: Float?) {
            receiveData?(download, data, progress)
        }

        private var completion: DownloadCompletion?

        func notifyCompletion(_ result: Result<DownloadResult, DownloadError>) {
            completion?(download, result)
        }

        public let download: Download

        init(download: Download, receiveResponse: DownloadReceiveResponse?, receiveData: DownloadReceiveData?, completion: DownloadCompletion?) {
            self.download = download
            self.receiveResponse = receiveResponse
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

    func complete(withError error: Error? = nil) {
        serialQueue.async {
            if let error = error {
                self.observer.notifyCompletion(.failure(error))
                return
            }

            switch self.download.destination {
                case .inMemory:
                    if let data = self.progress?.buffer {
                        let result = DownloadResult.data(data)
                        self.observer.notifyCompletion(.success(result))
                    }
                    else {
                        let error = URLError(.unknown)
                        self.observer.notifyCompletion(.failure(error))
                    }

                case .onDisk(let path):
                    let result = DownloadResult.file(path)
                    self.observer.notifyCompletion(.success(result))
            }
        }
    }

    func receive(response: URLResponse) {
        serialQueue.async {
            self.progress = DataTaskProgress(response: response)
            self.observer.notifyReceiveResponse()
        }
    }

    func receive(data: Data) {
        serialQueue.async {
            self.progress?.buffer.append(data)
            self.observer.notifyReceiveData(data, self.progress?.progress)
        }
    }

    fileprivate let serialQueue: DispatchQueue

    private var progress: DataTaskProgress?
}


extension DownloadTask : CustomStringConvertible {

    var description: String {
        "<DownloadTask \(Unmanaged.passUnretained(self).toOpaque()): download=\(download)>"
    }
}
