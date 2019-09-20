//
//  Downloader.swift
//  
//
//  Created by Dmytro Anokhin on 19/09/2019.
//

import Foundation


final class Downloader {

    let url: URL

    let task: URLSessionDownloadTask

    let queue: OperationQueue

    let remoteFileCache: RemoteFileCacheService

    init(url: URL, task: URLSessionDownloadTask, queue: OperationQueue, remoteFileCache: RemoteFileCacheService) {
        self.url = url
        self.task = task
        self.queue = queue
        self.remoteFileCache = remoteFileCache
    }

    var completionCallback: (() -> Void)?

    func resume(after delay: TimeInterval) {
        assert(!observers.isEmpty, "Starting to load the image at \(url) but no observers subscribed")

        guard transition(to: .scheduled) else {
            return
        }

        remoteFileCache.getFile(withRemoteURL: url) { localURL in
            if let localURL = localURL {
                if let imageWrapper = ImageWrapper(fileURL: localURL) {
                    // Loaded from disk
                    // TODO: Cache in memory

                    guard self.transition(to: .finished) else {
                        return
                    }

                    self.notifyObservers(imageWrapper)
                    self.completionCallback?()

                    return
                }
                else {
                    // File was removed
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

        guard transition(to: .cancelled) else {
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

    func complete(with tmpURL: URL) {
        do {
            let localURL = try self.remoteFileCache.addFile(withRemoteURL: url, sourceURL: tmpURL)

            DispatchQueue.main.async {
                if let imageWrapper = ImageWrapper(fileURL: localURL) {
                    // TODO: Cache in memory
                    self.notifyObservers(imageWrapper)
                }
                else {
                    // Can not read the file
                    try? self.remoteFileCache.delete(fileName: localURL.lastPathComponent)
                }
            }
        }
        catch {
            // Failed to copy the file to the cache
        }

        completionCallback?()
    }

    func progress() {
    }

    func fail(with error: Error) {
        guard transition(to: .failed) else {
            return
        }

        completionCallback?()
    }

    // MARK: Private

    enum LoadingState : Hashable {

        /// Initial state after the object was created
        case initial

        /// Loading is scheduled and about to start shortly after delay
        case scheduled

        /// Loading is in progress
        case loading

        /// Successfully loaded and decoded data
        case finished

        /// Failed to load or decode data
        case failed

        /// Cancelled
        case cancelled

        /** Map of valid transitions.

            Each transition has "from" and "to" states.  Key in the map is "from" state. Value is a set of possible "to" states. Together this indicates all possible transitions for a state.

            Allowing transition from `finished`, `failed`, and  `cancelled` states back to `scheduled` state enables reloading data.
        */
        private static let transitions: [LoadingState: Set<LoadingState>] = [
            .initial   : [ .scheduled ],
            .scheduled  : [ .loading, .finished, .cancelled ],
            .loading   : [ .finished, .failed, .cancelled ],
            .finished  : [ .scheduled ],
            .failed    : [ .scheduled ],
            .cancelled : [ .scheduled ]
        ]

        /** Verifies if transition from `self` to `state` is possible.
        */
        func canTransition(to state: LoadingState) -> Bool {
            return Self.transitions[self]!.contains(state)
        }
    }

    private var state: LoadingState = .initial

    private func transition(to newState: LoadingState) -> Bool {
        guard state.canTransition(to: newState) else {
            return false
        }

        state = newState
        return true
    }

    private func notifyObservers(_ imageWrapper: ImageWrapper) {
        for observer in observers {
            observer.completion(imageWrapper.image)
        }
    }
}
