//
//  URLImage.swift
//  URLImage
//
//  Created by Dmytro Anokhin on 06/06/2019.
//  Copyright © 2019 Dmytro Anokhin. All rights reserved.
//

import SwiftUI
import Combine


public struct Configuration {

    /// Shared URLSession with default configuration that runs one connection per host
    public static let sharedURLSession = URLSession(configuration: {
        let configuration = URLSessionConfiguration.default.copy() as! URLSessionConfiguration
        configuration.httpMaximumConnectionsPerHost = 1

        return configuration
    }())

    /// `URLSession` used to download an image
    public var urlSession: URLSession

    /// Delay before the `URLImage` instance fetches an image from local store or starts download operation
    public var delay: Double

    /// Enables/disables in-memory caching of downloaded images
    public var useInMemoryCache: Bool

    public init(urlSession: URLSession = Configuration.sharedURLSession, delay: Double = 0.0, useInMemoryCache: Bool = false) {
        self.urlSession = urlSession
        self.delay = delay
        self.useInMemoryCache = useInMemoryCache
    }
}


/**
    URLImage is a view that automatically loads an image from provided URL.

    The image is loaded on appearance. Loading operation is cancelled when the view disappears.
 */
@available(iOS 13.0, tvOS 13.0, *)
public struct URLImage<Placeholder> : View where Placeholder : View {

    // MARK: Public

    let url: URL

    let placeholder: Placeholder

    let configuration: Configuration

    public init(_ url: URL, placeholder: () -> Placeholder, configuration: Configuration = Configuration()) {
        self.url = url
        self.placeholder = placeholder()
        self.configuration = configuration
        self.style = nil
    }

    fileprivate init(_ url: URL, placeholder: () -> Placeholder, configuration: Configuration, style: ImageStyle?) {
        self.url = url
        self.placeholder = placeholder()
        self.configuration = configuration
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

        if let renderingMode = style?.renderingMode {
            image = image?.renderingMode(renderingMode)
        }

        return ZStack {
            if image == nil {
                URLImageLoaderView(url, placeholder: AnyView(placeholder), configuration: configuration, onLoaded: { image in
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

        var renderingMode: Image.TemplateRenderingMode?
    }

    private let style: ImageStyle?

    @State private var image: Image? = nil

    @State private var previousURL: URL? = nil
}


@available(iOS 13.0, tvOS 13.0, *)
public extension URLImage where Placeholder == Image {

    init(_ url: URL, placeholder: Image = Image(systemName: "photo"), configuration: Configuration = Configuration()) {
        self.url = url
        self.placeholder = placeholder
        self.configuration = configuration
        self.style = nil
    }
}


@available(iOS 13.0, tvOS 13.0, *)
extension URLImage {

    public func resizable(capInsets: EdgeInsets = EdgeInsets(), resizingMode: Image.ResizingMode = .stretch) -> URLImage {
        let newStyle = ImageStyle(resizable: (capInsets: capInsets, resizingMode: resizingMode), renderingMode: style?.renderingMode)
        return URLImage(url, placeholder: { placeholder }, configuration: configuration, style: newStyle)
    }

    public func renderingMode(_ renderingMode: Image.TemplateRenderingMode?) -> URLImage {
        let newStyle = ImageStyle(resizable: style?.resizable, renderingMode: renderingMode)
        return URLImage(url, placeholder: { placeholder }, configuration: configuration, style: newStyle)
    }
}


@available(iOS 13.0, tvOS 13.0, *)
struct URLImageLoaderView : View {

    let url: URL

    let placeholder: AnyView

    let configuration: Configuration

    let onLoaded: (_ image: Image) -> Void

    init(_ url: URL, placeholder: AnyView, configuration: Configuration, onLoaded: @escaping (_ image: Image) -> Void) {
        self.url = url
        self.placeholder = placeholder
        self.configuration = configuration
        self.onLoaded = onLoaded
    }

    var body: some View {
        placeholder
            .onAppear {
                self.imageLoader.didLoad = { image in
                    self.removeImageLoaderFromPool()
                    self.onLoaded(image)
                }

                self.imageLoader.load()
            }
            .onDisappear {
                self.removeImageLoaderFromPool()
            }
    }

    private static var imageLoaderPool: [URL: URLImageLoaderView.ImageLoader] = [:]

    private var imageLoader: ImageLoader {
        if let imageLoader = URLImageLoaderView.imageLoaderPool[url] {
            return imageLoader
        }

        let imageLoader = ImageLoader(url: url, session: configuration.urlSession, delay: configuration.delay, inMemoryCache: configuration.useInMemoryCache ? InMemoryCacheServiceImpl.shared : InMemoryCacheServiceDummyImpl())
        URLImageLoaderView.imageLoaderPool[url] = imageLoader

        return imageLoader
    }

    private func removeImageLoaderFromPool() {
        guard let imageLoader = URLImageLoaderView.imageLoaderPool[url] else {
            return
        }

        imageLoader.cancel()
        URLImageLoaderView.imageLoaderPool[url] = nil
    }
}


@available(iOS 13.0, tvOS 13.0, *)
extension URLImageLoaderView {

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

        init(url: URL, session: URLSession, delay: Double, inMemoryCache: InMemoryCacheService) {
            self.url = url
            self.session = session
            self.delay = delay
            self.inMemoryCache = inMemoryCache
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

        private let inMemoryCache: InMemoryCacheService

        private let remoteFileCache: RemoteFileCacheService = RemoteFileCacheServiceImpl.shared

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
}
