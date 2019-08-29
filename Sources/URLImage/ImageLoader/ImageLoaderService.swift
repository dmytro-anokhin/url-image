//
//  ImageLoaderService.swift
//  URLImage
//
//
//  Created by Dmytro Anokhin on 28/08/2019.
//  Copyright © 2019 Dmytro Anokhin. All rights reserved.
//

import Foundation


protocol ImageLoaderService {

    func subscribe(forURL url: URL, _ observer: ImageLoaderObserver)

    func unsubscribe(_ observer: ImageLoaderObserver, fromURL url: URL)

    func load(url: URL, configuration: ImageLoaderConfiguration)
}


final class ImageLoaderServiceImpl: ImageLoaderService {

    static let shared = ImageLoaderServiceImpl()

    init() {
    }

    func subscribe(forURL url: URL, _ observer: ImageLoaderObserver) {
        var observers = urlToObserversMap[url] ?? []
        observers.insert(observer)
        urlToObserversMap[url] = observers
    }

    func unsubscribe(_ observer: ImageLoaderObserver, fromURL url: URL) {
        guard var observers = urlToObserversMap[url] else {
            return
        }

        observers.remove(observer)

        if observers.isEmpty {
            urlToObserversMap.removeValue(forKey: url)
            cancel(url: url)
        }
        else {
            urlToObserversMap[url] = observers
        }
    }

    func load(url: URL, configuration: ImageLoaderConfiguration) {
        assert(!(urlToObserversMap[url]?.isEmpty ?? false), "Loading image at \(url) when there are no observers subscribed")

        guard urlToImageLoaderMap[url] == nil else {
            return
        }

        var imageLoader: ImageLoader = ImageLoaderImpl(
            url: url,
            session: configuration.urlSession,
            delay: configuration.delay,
            remoteFileCache: RemoteFileCacheServiceImpl.shared,
            inMemoryCache: configuration.useInMemoryCache ? InMemoryCacheServiceImpl.shared : InMemoryCacheServiceDummyImpl())

        imageLoader.didLoad = { image in
            self.urlToImageLoaderMap.removeValue(forKey: url)

            guard let observers = self.urlToObserversMap[url] else {
                return
            }

            for observer in observers {
                observer.closure(image)
            }

            self.urlToObserversMap.removeValue(forKey: url)
        }

        urlToImageLoaderMap[url] = imageLoader
        imageLoader.load()
    }

    // MARK: Private

    private var urlToImageLoaderMap: [URL: ImageLoader] = [:]

    private var urlToObserversMap: [URL: Set<ImageLoaderObserver>] = [:]

    private func cancel(url: URL) {
        assert(urlToObserversMap[url]?.isEmpty ?? true, "Cancelling loading image at \(url) while some observers are still subscribed")

        guard let imageLoader = urlToImageLoaderMap[url] else {
            return
        }

        imageLoader.cancel()
        urlToImageLoaderMap.removeValue(forKey: url)
    }
}
