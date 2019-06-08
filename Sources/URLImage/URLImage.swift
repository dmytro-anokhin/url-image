//
//  URLImage.swift
//  URLImage
//
//  Created by Dmytro Anokhin on 06/06/2019.
//  Copyright © 2019 Dmytro Anokhin. All rights reserved.
//

import SwiftUI
import Combine


/**
    URLImage is a view that automatically loads an image from provided URL.

    The image is loaded on appearance. Loading operation is cancelled when the view disappears.
 */
@available(iOS 13.0, *)
public struct URLImage : View {

    // MARK: Public

    public init(_ url: URL, placeholder: Image = Image(systemName: "photo")) {
        self.placeholder = placeholder
        imageLoader = ImageLoader(url: url)
    }
    
    public init(_ url: URL, placeholder: Image = Image(systemName: "photo"), session: URLSession) {
        self.placeholder = placeholder
        imageLoader = ImageLoader(url: url)
    }

    public var body: some View {
        if let image = imageLoader.image {
            return image
                .onAppear {}
                .onDisappear {}
        }
        else {
            return placeholder
                .onAppear {
                    self.imageLoader.load()
                }
                .onDisappear {
                    self.imageLoader.cancel()
                }
        }
    }

    // MARK: Private

    private let placeholder: Image

    @ObjectBinding
    private var imageLoader: ImageLoader
}


@available(iOS 13.0, *)
extension URLImage {

    // MARK: - ImageLoader

    fileprivate final class ImageLoader : BindableObject {

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

        init(session: URLSession, url: URL) {
            self.session = session
            self.url = url
        }

        convenience init(url: URL) {
            self.init(session: Self.session, url: url)
        }

        deinit {
            task?.cancel()
        }

        let url: URL

        let didChange = PassthroughSubject<ImageLoader, Never>()

        private(set) var state: LoadingState = .initial {
            didSet {
                assert(Thread.isMainThread)
                
                if state.shouldNotify {
                    didChange.send(self)
                }
            }
        }

        var image: Image? {
            if let uiImage = rawImage {
                return Image(uiImage: uiImage)
            }
            else {
                return nil
            }
        }

        func load() {
            transition(to: .scheduled) {
                DispatchQueue.main.asyncAfter(deadline: .now() + self.delay) {
                    self.transition(to: .loading) {
                        // First see if image is in store
                        Self.store.loadImage(for: self.url) { result in
                            switch result {
                                case .success(let image):
                                    // Propagate image to other stores
                                    Self.store.saveImage(image, for: self.url)

                                    self.transition(to: .finished) {
                                        self.rawImage = image
                                    }

                                case .failure(_):
                                    DispatchQueue.main.async {
                                        guard self.state == .loading else {
                                            return
                                        }

                                        self.task = self.makeLoadTask()
                                        self.task?.resume()
                                    }
                            }
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

        /// Shared URLSession with default configuration that runs one connection per host
        private static let session = URLSession(configuration: {
            let configuration = URLSessionConfiguration.default.copy() as! URLSessionConfiguration
            configuration.httpMaximumConnectionsPerHost = 1

            return configuration
        }())

        private static let store: ImageStoreGroup<UIImage> = {
            var group = ImageStoreGroup<UIImage>()
            group.addStore(ImageInMemoryStore())
            group.addStore(ImageLocalStore())

            return group
        }()
        
        /// Delay before loading starts
        private let delay: Double = 0.25

        private let session: URLSession

        /// Download task
        private var task: URLSessionTask?

        /// Instance must be retained by in-memory store. Weak reference enables proper resource management on memory warnings.
        private weak var rawImage: UIImage?

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
            return session.dataTask(with: url, completionHandler: { [weak self] data, response, error in
                guard let self = self else {
                    return
                }

                if let data = data, let image = UIImage(data: data) {
                    Self.store.saveImage(image, for: self.url)

                    self.transition(to: .finished) {
                        self.rawImage = image
                        self.task = nil
                    }
                }
                else {
                    self.transition(to: .failed) {
                        self.task = nil
                    }
                }
            })
        }
    }
}
