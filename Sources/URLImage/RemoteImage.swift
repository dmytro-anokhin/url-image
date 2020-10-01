//
//  RemoteImage.swift
//  
//
//  Created by Dmytro Anokhin on 25/08/2020.
//

import Combine
import SwiftUI
import DownloadManager
import RemoteContentView
import ImageDecoder


@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public final class RemoteImage : RemoteContent {

    public enum Error : Swift.Error {

        case decode
    }

    /// Reference to the download manager used to download the image.
    unowned let downloadManager: DownloadManager

    /// Download object describes how the image should be downloaded.
    let download: Download

    /// Read value synchronously from cache.
    ///
    /// When this flag is `true` remote image performs cache lookup synchronously. This allows to return cached image immediately, skipping loading step.
    /// Otherwise cache lookup performed asynchronosly as a part of loading step.
    let isImmediate: Bool

    public init(downloadManager: DownloadManager, download: Download, isImmediate: Bool = false) {
        self.downloadManager = downloadManager
        self.download = download
        self.isImmediate = isImmediate
    }

    public typealias LoadingState = RemoteContentLoadingState<Image, Float?>

    @Published public private(set) var loadingState: LoadingState = .initial {
        didSet {
            print("Loading state did change from: \(oldValue), to: \(loadingState)")
        }
    }

    private var cacheCancellable: AnyCancellable?
    private var loadCancellable: AnyCancellable?

    public func load() {
        guard !isLoading else {
            return
        }

        if !isImmediate {
            loadingState = .inProgress(nil)
        }

        cacheCancellable = getFromCachePublisher()
            .receive(on: RunLoop.main)
            .catch { _ in
                Just(nil)
            }
            .sink { [weak self] in
                guard let self = self else {
                    return
                }

                if let transientImage = $0 {
                    // Set image retrieved from cache
                    self.loadingState = .success(transientImage)
                }
                else {
                    // Download image
                    self.loadingState = .inProgress(nil)
                    self.startDownload()
                }
            }
    }

    public func cancel() {
        guard isLoading else {
            return
        }

        // Reset loading state
        loadingState = .initial

        // Stop loading
        cacheCancellable?.cancel()
        cacheCancellable = nil

        loadCancellable?.cancel()
        loadCancellable = nil
    }

    private var isLoading: Bool {
        loadCancellable != nil || cacheCancellable != nil
    }

    private func startDownload() {
        loadCancellable = downloadPublisher()
            .receive(on: RunLoop.main)
            .map {
                .success(Image(transientImage: $0))
            }
            .catch {
                Just(.failure($0))
            }
            .assign(to: \.loadingState, on: self)
    }

    private func downloadPublisher() -> AnyPublisher<TransientImage, Swift.Error> {
        let url = download.url

        return downloadManager.publisher(for: download)
            .tryMap { downloadResult -> TransientImage in

                switch downloadResult {
                    case .data(let data):

                        _ = try? URLImageService.shared.fileIndex.write(data, originalURL: url)

                        let decoder = ImageDecoder()
                        decoder.setData(data, allDataReceived: true)

                        guard let image = decoder.createFrameImage(at: 0) else {
                            throw RemoteImage.Error.decode
                        }

                        return TransientImage(cgImage: image,
                                            cgOrientation: decoder.frameOrientation(at: 0))

                    case .file:
                        fatalError("Not implemented")
                }
            }.eraseToAnyPublisher()
    }

    private func getFromCachePublisher() -> AnyPublisher<TransientImage?, Swift.Error> {
        let url = download.url
        let isSync = isImmediate

        return Future<TransientImage?, Swift.Error> { promise in
            let work: () -> Void = {
                guard let file = URLImageService.shared.fileIndex.get(url).first else {
                    promise(.success(nil))
                    return
                }

                do {
                    let location = URLImageService.shared.fileIndex.location(of: file)
                    let transientImage = try TransientImage.decode(location)
                    promise(.success(transientImage))
                }
                catch {
                    promise(.failure(error))
                }
            }

            if isSync {
                work()
            }
            else {
                DispatchQueue.global().async(execute: work)
            }
        }.eraseToAnyPublisher()
    }

    private func getFromCacheSync() throws -> TransientImage? {
        guard let file = URLImageService.shared.fileIndex.get(download.url).first else {
            return nil
        }

        let location = URLImageService.shared.fileIndex.location(of: file)
        print("Get cached file for: \(download.url) at location: \(location)")

        return try TransientImage.decode(location)
    }

    private func getFromCacheAsync(_ completion: @escaping (_ result: Result<TransientImage?, Swift.Error>) -> Void) {
        DispatchQueue.global().async { [weak self] in
            guard let self = self else {
                return
            }

            do {
                let transientImage = try self.getFromCacheSync()
                completion(.success(transientImage))
            }
            catch {
                completion(.failure(error))
            }
        }
    }
}


fileprivate extension RemoteContentLoadingState where Value == Image {

    static func success(_ transientImage: TransientImage) -> RemoteContentLoadingState<Value, Progress> {
        .success(Image(transientImage: transientImage))
    }
}
