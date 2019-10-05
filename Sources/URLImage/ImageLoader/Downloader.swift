//
//  Downloader.swift
//  
//
//  Created by Dmytro Anokhin on 19/09/2019.
//

import Foundation


class Downloader {

    let url: URL

    let task: URLSessionTask

    let remoteFileCache: RemoteFileCacheService

    let inMemoryCacheService: InMemoryCacheService

    init(url: URL, task: URLSessionTask, remoteFileCache: RemoteFileCacheService, inMemoryCacheService: InMemoryCacheService) {
        self.url = url
        self.task = task
        self.remoteFileCache = remoteFileCache
        self.inMemoryCacheService = inMemoryCacheService
    }

    var completionCallback: (() -> Void)?

    func resume(after delay: Double) {
        assert(!observers.isEmpty, "Starting to load the image at \(url) but no observers subscribed")

        guard transition(to: .scheduled) else {
            return
        }

        if let imageWrapper = inMemoryCacheService.image(for: url) {
            guard self.transition(to: .finished) else {
                return
            }

            self.notifyObserversAboutCompletion(imageWrapper)
            self.completionCallback?()

            return
        }

        remoteFileCache.getFile(withRemoteURL: url) { localURL in

            if let localURL = localURL {
                if let imageWrapper = ImageWrapper(fileURL: localURL) { // Loaded from disk

                    self.inMemoryCacheService.setImage(imageWrapper, for: self.url)

                    guard self.transition(to: .finished) else {
                        return
                    }

                    self.notifyObserversAboutCompletion(imageWrapper)
                    self.completionCallback?()

                    return
                }
                else {
                    // URL is still registered in the local cache but the file was removed
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
        assert(observers.isEmpty, "Cancelling loading the image at \(url) while some observers are still subscribed")

        guard transition(to: .cancelling) else {
            return
        }

        task.cancel()
    }

    private(set) var observers = Set<ImageLoaderObserver>()

    func addObserver(_ observer: ImageLoaderObserver) {
        observers.insert(observer)
    }

    func removeObserver(_ observer: ImageLoaderObserver) {
        observers.remove(observer)
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
        guard state.canTransition(to: newState) else {
            // print("Can not transition from \(state) to \(newState)")
            return false
        }

        state = newState
        return true
    }

    fileprivate func notifyObserversAboutProgress(_ progress: Float?) {
        for observer in observers {
            observer.progress(progress)
        }
    }

    fileprivate func notifyObserversAboutPartial(_ imageProxy: ImageProxy) {
        for observer in observers {
            observer.partial(imageProxy)
        }
    }

    fileprivate func notifyObserversAboutCompletion(_ imageProxy: ImageProxy) {
        for observer in observers {
            observer.completion(imageProxy)
        }
    }
}


final class FileDownloader: Downloader {

    func finishDownloading(with tmpURL: URL) {
        guard transition(to: .finishing) else {
            return
        }

        guard let localURL = try? remoteFileCache.addFile(withRemoteURL: url, sourceURL: tmpURL) else {
            // Failed to cache the file
            transition(to: .failed)
            return
        }

        guard let imageWrapper = ImageWrapper(fileURL: localURL) else {
            // Failed to read the file
            // Remove the file from the cache
            try? remoteFileCache.delete(fileName: localURL.lastPathComponent)
            transition(to: .failed)
            return
        }

        DispatchQueue.main.async {
            self.inMemoryCacheService.setImage(imageWrapper, for: self.url)
            self.notifyObserversAboutCompletion(imageWrapper)
        }
    }

    func progress(_ progress: Float?) {
        DispatchQueue.main.async {
            self.notifyObserversAboutProgress(progress)
        }
    }
}


final class DataDownloader: Downloader {

    private var imageWrapper = IncrementalImageWrapper()

    func append(data: Data) {
        imageWrapper.append(data)
        
        DispatchQueue.main.async {
            self.notifyObserversAboutPartial(self.imageWrapper)
        }
    }

    func finishDownloading() {
        guard transition(to: .finishing) else {
            return
        }

        imageWrapper.isFinal = true

        guard !imageWrapper.isEmpty else {
            transition(to: .failed)
            return
        }

        guard let _ = try? remoteFileCache.createFile(withRemoteURL: url, data: imageWrapper.data) else {
            // Failed to cache the file
            transition(to: .failed)
            return
        }

        DispatchQueue.main.async {
            // self.inMemoryCacheService.setImage(self.imageWrapper, for: self.url)
            self.notifyObserversAboutCompletion(self.imageWrapper)
        }
    }
}
