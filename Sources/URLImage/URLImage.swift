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

    let url: URL

    let placeholder: Image

    let session: URLSession?

    let delay: Double

    let animated: Bool

    public init(_ url: URL, placeholder: Image = Image(systemName: "photo"), session: URLSession? = nil, delay: Double = 0.0, animated: Bool = true) {
        self.url = url
        self.placeholder = placeholder
        self.session = session
        self.delay = delay
        self.animated = animated
        self.style = nil
    }

    fileprivate init(_ url: URL, placeholder: Image = Image(systemName: "photo"), session: URLSession? = nil, delay: Double = 0.0, animated: Bool = true, style: ImageStyle?) {
        self.url = url
        self.placeholder = placeholder
        self.session = session
        self.delay = delay
        self.animated = animated
        self.style = style
    }

    public var body: some View {
        DispatchQueue.main.async {
            if self.previousURL != self.url {
                self.image = nil
            }
        }

        var image = self.image

        if let resizable = style?.resizable {
            image = image?.resizable(capInsets: resizable.capInsets, resizingMode: resizable.resizingMode)
        }

        return ZStack {
            if image == nil {
                URLImageLoader(url, placeholder: placeholder, session: session, delay: delay, onLoaded: { image in
                    self.image = image
                    self.previousURL = self.url
                })
            }

            image
        }
    }

    // MARK: Private

    fileprivate struct ImageStyle {

        var resizable: (capInsets: EdgeInsets, resizingMode: Image.ResizingMode)?
    }

    private let style: ImageStyle?

    @State private var image: Image? = nil

    @State private var previousURL: URL? = nil
}


@available(iOS 13.0, *)
extension URLImage {

    public func resizable(capInsets: EdgeInsets = EdgeInsets(), resizingMode: Image.ResizingMode = .stretch) -> URLImage {
        let style = ImageStyle(resizable: (capInsets: capInsets, resizingMode: resizingMode))
        return URLImage(url, placeholder: placeholder, session: session, delay: delay, animated: animated, style: style)
    }
}


@available(iOS 13.0, *)
struct URLImageLoader : View {

    let placeholder: Image

    let onLoaded: (_ image: Image) -> Void

    init(_ url: URL, placeholder: Image, session: URLSession?, delay: Double, onLoaded: @escaping (_ image: Image) -> Void) {
        self.placeholder = placeholder
        self.onLoaded = onLoaded

        loader = ImageLoader(url: url, session: session, delay: delay)
    }

    var body: some View {
        placeholder
            .onAppear {
                self.loader.didLoad = { image in
                    self.onLoaded(image)
                }

                self.loader.load()
            }
            .onDisappear {
                self.loader.cancel()
            }
    }

    private let loader: ImageLoader
}


@available(iOS 13.0, *)
extension URLImageLoader {

    // MARK: - ImageLoader

    fileprivate final class ImageLoader {

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

        init(url: URL, session: URLSession?, delay: Double) {
            self.url = url
            self.session = session ?? Self.session
            self.delay = delay
        }

        deinit {
            task?.cancel()
        }

        let url: URL

        private(set) var state: LoadingState = .initial {
            didSet {
                assert(Thread.isMainThread)
            }
        }

        var didLoad: ((_ image: Image) -> Void)?

        func load() {
            transition(to: .scheduled) {
                DispatchQueue.main.asyncAfter(deadline: .now() + self.delay) {
                    self.transition(to: .loading) {
                        // First see if image is in store
                        Self.store.loadImage(for: self.url) { result in
                            switch result {
                                case .success(let value):
                                    if let localURL = value.1 { // Propagate image to other stores
                                        Self.store.saveImage(value.0, remoteURL: self.url, localURL: localURL)
                                    }

                                    self.transition(to: .finished) {
                                        self.didLoad?(Image(uiImage: value.0))
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
        private let delay: Double

        private let session: URLSession

        /// Download task
        private var task: URLSessionTask?

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
            return session.downloadTask(with: url) { [weak self] location, response, error in
                guard let self = self else {
                    return
                }

                guard let location = location else {
                    // Network error
                    self.transition(to: .failed) {
                        self.task = nil
                    }

                    return
                }

                // Copy file to caches folder
                do {
                    let cachesURL = try CacheHelper.copyToCaches(from: location)

                    if let image = UIImage(contentsOfFile: cachesURL.path) {
                        Self.store.saveImage(image, remoteURL: self.url, localURL: cachesURL)

                        self.transition(to: .finished) {
                            self.didLoad?(Image(uiImage: image))
                            self.task = nil
                        }
                    }
                    else {
                        // Incorrect file format
                        try CacheHelper.delete(at: cachesURL)

                        self.transition(to: .failed) {
                            self.task = nil
                        }
                    }
                }
                catch {
                    self.transition(to: .failed) {
                        self.task = nil
                    }
                }
            }
        }
    }
}
