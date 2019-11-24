//
//  DownloadCoordinator.swift
//  
//
//  Created by Dmytro Anokhin on 21/11/2019.
//

import Foundation


/// Coordinates abstract download process between URLSessionTask and a set of handler objects.
@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
class DownloadCoordinator {

    let url: URL

    let task: URLSessionTask

    let remoteFileCache: RemoteFileCacheService

    init(url: URL, task: URLSessionTask, remoteFileCache: RemoteFileCacheService) {
        self.url = url
        self.task = task
        self.remoteFileCache = remoteFileCache
    }

    var completionCallback: (() -> Void)?

    var expiryDate: Date? = nil

    func resume(after delay: Double) {
        assert(!handlers.isEmpty, "Starting to load the image at \(url) but no handlers created")

        guard transition(to: .scheduled) else {
            return
        }

        remoteFileCache.getFile(withRemoteURL: url) { localURL in
            if let localURL = localURL {
                // TODO: Verify that file can be open
                if FileManager.default.fileExists(atPath: localURL.path) {
                    if self.transition(to: .finishing) {
                        self.notifyHandlersAboutCompletion(nil, fileURL: localURL)

                        if self.transition(to: .finished) {
                            self.completionCallback?()
                        }

                        return
                    }
                }
                else {
                    // This is inconsistent state: URL is still registered in the local cache but the file was removed. Remove file from the cache and redownload.
                    try? self.remoteFileCache.delete(fileName: localURL.lastPathComponent)
                }
            }

            DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                // Load from network
                guard self.transition(to: .loading) else {
                    return
                }

                self.task.resume()
            }
        }
    }

    func cancel() {
        assert(handlers.isEmpty, "Cancelling loading the image at \(url) while some handlers are still attached")

        guard transition(to: .cancelling) else {
            return
        }

        task.cancel()
    }

    private(set) var handlers = Set<DownloadHandler>()

    func addHandler(_ handler: DownloadHandler) {
        handlers.insert(handler)
    }

    func removeHandler(_ handler: DownloadHandler) {
        handlers.remove(handler)
    }

    func complete(with error: Error?) {
        switch error {
            case .none:
                transition(to: .finished)
                completionCallback?()

            case .some(let nsError as NSError):
                if nsError.domain == NSURLErrorDomain, nsError.code == NSURLErrorCancelled {
                    if transition(to: .cancelled) {
                        completionCallback?()
                    }
                }
                else {
                    if transition(to: .failed) {
                        completionCallback?()
                    }
                }
        }
    }

    // MARK: Private

    private var state: LoadingState = .initial

    @discardableResult
    fileprivate func transition(to newState: LoadingState) -> Bool {
        if newState == .failed {
            log_error(self, "Download failed for: \"\(url)\". Set breakpoint in \(#function) to investigate.")
        }

        guard state.canTransition(to: newState) else {
            // print("Can not transition from \(state) to \(newState)")
            return false
        }

        state = newState
        return true
    }

    fileprivate func notifyHandlersAboutProgress(_ progress: Float?) {
        for handler in handlers {
            handler.handleDownloadProgress(progress)
        }
    }

    fileprivate func notifyHandlersAboutPartial(_ data: Data) {
        for handler in handlers {
            handler.handleDownloadPartial(data)
        }
    }

    fileprivate func notifyHandlersAboutCompletion(_ data: Data?, fileURL: URL) {
        for handler in handlers {
            handler.handleDownloadCompletion(data, fileURL)
        }
    }
}


/// Coordinates file download between URLSessionTask and a set of handler objects.
@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
final class FileDownloadCoordinator: DownloadCoordinator {

    func finishDownloading(with tmpURL: URL) {
        guard transition(to: .finishing) else {
            return
        }

        guard let decoder = ImageDecoder(url: tmpURL) else {
            // Failed to read the file
            transition(to: .failed)
            return
        }

        let fileExtension: String?

        if let uti = decoder.uti {
            fileExtension = preferredFileExtension(forTypeIdentifier: uti)
        }
        else {
            fileExtension = nil
        }

        guard let localURL = try? remoteFileCache.addFile(withRemoteURL: url, sourceURL: tmpURL, expiryDate: expiryDate, preferredFileExtension: fileExtension) else {
            // Failed to cache the file
            transition(to: .failed)
            return
        }

        notifyHandlersAboutCompletion(nil, fileURL: localURL)
    }

    func progress(_ progress: Float?) {
        notifyHandlersAboutProgress(progress)
    }
}


/// Coordinates in memory download between URLSessionTask and a set of handler objects.
@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
final class DataDownloadCoordinator: DownloadCoordinator {

    private var sharedBuffer = Data()

    func append(data: Data) {
        sharedBuffer.append(data)
        notifyHandlersAboutPartial(sharedBuffer)
    }

    func finishDownloading() {
        guard transition(to: .finishing) else {
            return
        }

        // TODO: Verify that file can be open

        let decoder = ImageDecoder()
        decoder.setData(sharedBuffer, allDataReceived: true)

        let fileExtension: String?

        if let uti = decoder.uti {
            fileExtension = preferredFileExtension(forTypeIdentifier: uti)
        }
        else {
            fileExtension = nil
        }

        guard let localURL = try? remoteFileCache.createFile(withRemoteURL: url, data: sharedBuffer, expiryDate: expiryDate, preferredFileExtension: fileExtension) else {
            // Failed to cache the file
            transition(to: .failed)
            return
        }

        notifyHandlersAboutCompletion(sharedBuffer, fileURL: localURL)
    }
}
