//
//  ImageLoader.swift
//  URLImage
//
//
//  Created by Dmytro Anokhin on 29/08/2019.
//  Copyright © 2019 Dmytro Anokhin. All rights reserved.
//

import SwiftUI


protocol ImageLoader {

    var url: URL { get }

    var didLoad: ImageLoaderCompletion? { get set }

    func load()

    func cancel()
}


@available(iOS 13.0, tvOS 13.0, *)
final class ImageLoaderImpl: ImageLoader {

    // MARK: State

    /// State of the `ImageLoader`
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
            .scheduled  : [ .loading, .cancelled ],
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

        /** Defines if `ImageLoader` should notify about transtion change to this state.

            Some transitions (like to `scheduled` state) may not be important for UI. Transition to `finished` must be reflected.
        */
        var shouldNotify: Bool {
            return self == .finished
        }
    }

    // MARK: Public

    init(url: URL, session: URLSession, delay: Double, remoteFileCache: RemoteFileCacheService, inMemoryCache: InMemoryCacheService) {
        self.url = url
        self.session = session
        self.delay = delay
        self.remoteFileCache = remoteFileCache
        self.inMemoryCache = inMemoryCache
    }

    deinit {
        task?.cancel()
    }

    let url: URL

    var didLoad: ImageLoaderCompletion?

    func load() {
        transition(to: .scheduled) {
            DispatchQueue.main.asyncAfter(deadline: .now() + self.delay) {
                self.transition(to: .loading) {

                    // Check in-memory cache
                    if let image = self.inMemoryCache.image(for: self.url) {
                        self.transition(to: .finished) {
                            self.didLoad?(Image(uiImage: image))
                        }

                        return
                    }

                    // Load from network
                    self.task = self.makeLoadTask()
                    self.task?.resume()

                    // Load from disk
                    self.remoteFileCache.getFile(withRemoteURL: self.url) { localURL in

                        if let localURL = localURL {
                            if let image = UIImage(contentsOfFile: localURL.path) {
                                // Loaded from disk
                                self.inMemoryCache.setImage(image, for: self.url)

                                self.transition(to: .finished) {
                                    self.didLoad?(Image(uiImage: image))
                                }

                                return
                            }
                            else {
                                // File was removed
                                try? self.remoteFileCache.delete(fileName: localURL.lastPathComponent)
                            }
                        }

                        // Load from network
                        self.task = self.makeLoadTask()
                        self.task?.resume()
                    }
                }
            }
        }
    }

    func cancel() {
        transition(to: .cancelled) {
            self.task?.cancel()
            self.task = nil
        }
    }

    // MARK: Private

    private let remoteFileCache: RemoteFileCacheService

    private let inMemoryCache: InMemoryCacheService

    /// Delay before loading starts
    private let delay: Double

    private let session: URLSession

    /// Download task
    private var task: URLSessionTask?

    private var state: LoadingState = .initial {
        didSet {
            assert(Thread.isMainThread)
        }
    }

    /** Transitions from current state to the new state if such transition is valid. Executes given closure on successful transition. Transition and closure are executed asynchronously on the main queue.
    */
    private func transition(to newState: LoadingState, closure: (() -> Void)? = nil) {
        DispatchQueue.main.async {
            guard self.state.canTransition(to: newState) else {
                return
            }

            closure?()
            self.state = newState
        }
    }

    private func makeLoadTask() -> URLSessionTask {
        return session.downloadTask(with: url) { [weak self] tmpURL, response, error in
            guard let self = self else {
                return
            }

            guard let tmpURL = tmpURL else {
                // Network error
                self.transition(to: .failed) {
                    self.task = nil
                }

                return
            }

            do {
                let localURL = try self.remoteFileCache.addFile(withRemoteURL: self.url, sourceURL: tmpURL)

                if let image = UIImage(contentsOfFile: localURL.path) {
                    // Cache in memory
                    self.inMemoryCache.setImage(image, for: self.url)

                    self.transition(to: .finished) {
                        self.didLoad?(Image(uiImage: image))
                        self.task = nil
                    }
                }
                else {
                    // Incorrect file format
                    try? self.remoteFileCache.delete(fileName: localURL.lastPathComponent)

                    self.transition(to: .failed) {
                        self.task = nil
                    }
                }
            }
            catch {
                // Write to disk error
                self.transition(to: .failed) {
                    self.task = nil
                }
            }
        }
    }
}
