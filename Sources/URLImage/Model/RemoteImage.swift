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


@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public final class RemoteImage : RemoteContent {

    /// Reference to the download manager used to download the image.
    unowned let downloadManager: DownloadManager

    /// Download object describes how the image should be downloaded.
    let download: Download

    let configuration: URLImageConfiguration

    public init(downloadManager: DownloadManager, download: Download, configuration: URLImageConfiguration) {
        self.downloadManager = downloadManager
        self.download = download
        self.configuration = configuration

        if configuration.cachePolicy.isReturnCache,
           let transientImage = URLImageService.shared.inMemoryCache.image(with: download.url) {
            // Set image retrieved from cache
            self.loadingState = .success(transientImage)
        }
    }

    public typealias LoadingState = RemoteContentLoadingState<Image, Float?>

    @Published public private(set) var loadingState: LoadingState = .initial

    private var cacheCancellable: AnyCancellable?
    private var loadCancellable: AnyCancellable?

    public func load() {
        guard !isLoading else {
            return
        }

        switch configuration.cachePolicy {
            case .returnCacheElseLoad:
                if !isLoadedSuccessfully {
                    returnCached { [weak self] success in
                        guard let self = self else { return }

                        if !success {
                            self.startDownload()
                        }
                    }
                }

            case .returnCacheDontLoad:
                if !isLoadedSuccessfully {
                    returnCached {_ in
                    }
                }

            case .returnCacheReload:
                returnCached { [weak self] success in
                    guard let self = self else { return }
                    self.startDownload()
                }

            case .ignoreCache:
                startDownload()
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

    private var isLoadedSuccessfully: Bool {
        switch loadingState {
            case .success:
                return true
            default:
                return false
        }
    }

    private func startDownload() {
        loadingState = .inProgress(nil)

        loadCancellable = downloadManager.transientImagePublisher(for: download)
            .receive(on: RunLoop.main)
            .map {
                .success($0.image)
            }
            .catch {
                Just(.failure($0))
            }
            .assign(to: \.loadingState, on: self)
    }

    private func returnCached(_ completion: @escaping (_ success: Bool) -> Void) {
        loadingState = .inProgress(nil)

        cacheCancellable = URLImageService.shared.diskCache.imagePublisher(with: download.url)
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
                    completion(true)
                }
                else {
                    completion(false)
                }
            }
    }
}


fileprivate extension RemoteContentLoadingState where Value == Image {

    static func success(_ transientImage: TransientImage) -> RemoteContentLoadingState<Value, Progress> {
        .success(transientImage.image)
    }
}
