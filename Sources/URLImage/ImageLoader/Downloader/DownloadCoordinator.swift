//
//  DownloadCoordinator.swift
//  
//
//  Created by Dmytro Anokhin on 21/11/2019.
//

import Foundation


protocol RemoteFileCacheServiceProxy: AnyObject {

    func addFile(withFileIdentifier fileIdentifier: String, remoteURL: URL, sourceURL: URL, expiryDate: Date?, preferredFileExtension: @autoclosure () -> String?) throws -> URL

    func createFile(withFileIdentifier fileIdentifier: String, remoteURL: URL, data: Data, expiryDate: Date?, preferredFileExtension: @autoclosure () -> String?) throws -> URL

    func getFile(withFileIdentifier fileIdentifier: String, completion: @escaping (_ localFileURL: URL?) -> Void)

    func delete(fileName: String) throws
}


protocol DelayedDispatcher: AnyObject {

    func dispatch(after delay: TimeInterval, closure: @escaping () -> Void)
}


/// Coordinates abstract download process between URLSessionTask and a set of handler objects.
@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
class DownloadCoordinator {

    let url: URL

    let fileIdentifier: String

    let task: URLSessionTask

    let retryCount: Int

    unowned let remoteFileCache: RemoteFileCacheServiceProxy

    unowned let delayedDispatcher: DelayedDispatcher

    init(url: URL, fileIdentifier: String, task: URLSessionTask, retryCount: Int, remoteFileCache: RemoteFileCacheServiceProxy, delayedDispatcher: DelayedDispatcher) {
        self.url = url
        self.fileIdentifier = fileIdentifier
        self.task = task
        self.retryCount = retryCount
        self.remoteFileCache = remoteFileCache
        self.delayedDispatcher = delayedDispatcher
    }

    /// Called when `DownloadCoordinator` is no longer used and can be released.
    var finilizeCallback: (() -> Void)?

    var expiryDate: Date? = nil

    func resume(after delay: Double) {
        assert(!handlers.isEmpty, "Starting to load the image at \(url) but no handlers created")

        guard transition(to: .scheduled) else {
            return
        }

        remoteFileCache.getFile(withFileIdentifier: fileIdentifier) { localURL in
            if let localURL = localURL {
                // TODO: Verify that file can be open
                if FileManager.default.fileExists(atPath: localURL.path) {
                    log_debug(self, "Found local file at \"\(localURL)\" for remote url \"\(self.url)\".", detail: log_normal)

                    if self.transition(to: .finishing) {
                        self.notifyHandlersAboutCompletion(nil, fileURL: localURL)

                        if self.transition(to: .finished) {
                            self.finalize()
                        }

                        return
                    }
                }
                else {
                    log_error(self, "Local file at \"\(localURL)\" for remote url \"\(self.url)\" was removed.")
                    // This is inconsistent state: URL is still registered in the local cache but the file was removed. Remove file from the cache and redownload.
                    try? self.remoteFileCache.delete(fileName: localURL.lastPathComponent)
                }
            }

            self.delayedDispatcher.dispatch(after: delay) {
                // Load from network
                guard self.transition(to: .loading) else {
                    return
                }

                log_debug(self, "Resume task for url \"\(self.url)\".", detail: log_normal)
                self.task.resume()
            }
        }
    }

    func cancel() {
        assert(handlers.isEmpty, "Cancelling loading the image at \(url) while some handlers are still attached")

        log_debug(self, "Cancel for url \"\(url)\".", detail: log_detailed)

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
        log_debug(self, "Complete for url \"\(url)\" with error: \(String(describing: error)).", detail: log_detailed)

        defer {
            finalize()
        }

        guard let error = error else {
            transition(to: .finished)
            return
        }

        if (error as NSError).domain == NSURLErrorDomain && (error as NSError).code == NSURLErrorCancelled {
            // Request was cancelled
            transition(to: .cancelled)
        }
        else {
            // Network error
            transition(to: .failed, error: error)
            notifyHandlersAboutFailure(error)
        }
    }

    var isFailed: Bool {
        state == .failed
    }

    // MARK: Private

    private var state: LoadingState = .initial

    fileprivate func finalize() {
        if finilizeCallback == nil {
            log_debug(self, "Calling finalize more than once for url: \"\(url)\".", detail: log_detailed)
        }

        finilizeCallback?()
        finilizeCallback = nil
    }

    @discardableResult
    fileprivate func transition(to newState: LoadingState, error: Error? = nil) -> Bool {
        if newState == .failed {
            log_error(self, "Download failed for: \"\(url)\" with error: \(error). Set breakpoint in \(#function) to investigate.")
        }

        guard state.canTransition(to: newState) else {
            log_debug(self, "Can not transition from \(state) to \(newState) for \"\(url)\".", detail: log_normal)
            return false
        }

        log_debug(self, "Transition from \(state) to \(newState) for \"\(url)\".", detail: 100)

        state = newState
        return true
    }

    fileprivate func notifyHandlersAboutProgress(_ progress: Float?) {
        log_debug(self, "Notify progress for url \"\(self.url)\".", detail: 500)

        for handler in handlers {
            handler.handleDownloadProgress(progress)
        }
    }

    fileprivate func notifyHandlersAboutPartial(_ data: Data) {
        log_debug(self, "Notify partial for url \"\(self.url)\".", detail: 500)

        for handler in handlers {
            handler.handleDownloadPartial(data)
        }
    }

    fileprivate func notifyHandlersAboutCompletion(_ data: Data?, fileURL: URL) {
        log_debug(self, "Notify completion for url \"\(self.url)\".", detail: 500)

        for handler in handlers {
            handler.handleDownloadCompletion(data, fileURL)
        }
    }

    fileprivate func notifyHandlersAboutFailure(_ error: Error) {
        log_debug(self, "Notify failuer for url \"\(self.url)\" with error: \(error).", detail: 500)

        for handler in handlers {
            handler.handleDownloadFailure(error)
        }
    }
}


/// Coordinates file download between URLSessionTask and a set of handler objects.
@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
final class FileDownloadCoordinator: DownloadCoordinator {

    func finishDownloading(with tmpURL: URL) {
        log_debug(self, "Finishing downloading for url \"\(url)\".", detail:log_detailed)

        guard transition(to: .finishing) else {
            return
        }

        guard let decoder = ImageDecoder(url: tmpURL) else {
            // Failed to read the file
            log_debug(self, "Can not read data from tmp file for url \"\(url)\".", detail:log_detailed)
            transition(to: .failed)
            return
        }

        guard let uti = decoder.uti else {
            // Not an image file
            log_debug(self, "Can not determine UTI for url \"\(url)\".", detail:log_detailed)
            transition(to: .failed)
            return
        }

        log_debug(self, "UTI for url \"\(url)\" is \"\(uti)\".", detail:log_detailed)

        let fileExtension = preferredFileExtension(forTypeIdentifier: uti)

        guard let localURL = try? remoteFileCache.addFile(withFileIdentifier: fileIdentifier, remoteURL: url, sourceURL: tmpURL, expiryDate: expiryDate, preferredFileExtension: fileExtension) else {
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
        log_debug(self, "Finishing downloading for url \"\(url)\".", detail:log_detailed)

        guard transition(to: .finishing) else {
            return
        }

        let decoder = ImageDecoder()
        decoder.setData(sharedBuffer, allDataReceived: true)

        guard let uti = decoder.uti else {
            // Not an image data
            log_debug(self, "Can not determine UTI for url \"\(url)\".", detail:log_detailed)
            transition(to: .failed)
            return
        }

        log_debug(self, "UTI for url \"\(url)\" is \"\(uti)\".", detail:log_detailed)

        let fileExtension = preferredFileExtension(forTypeIdentifier: uti)

        guard let localURL = try? remoteFileCache.createFile(withFileIdentifier: fileIdentifier, remoteURL: url, data: sharedBuffer, expiryDate: expiryDate, preferredFileExtension: fileExtension) else {
            // Failed to cache the file
            transition(to: .failed)
            return
        }

        notifyHandlersAboutCompletion(sharedBuffer, fileURL: localURL)
    }
}
