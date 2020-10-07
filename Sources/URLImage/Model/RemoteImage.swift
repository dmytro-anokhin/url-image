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

    let options: URLImageOptions

    public init(downloadManager: DownloadManager, download: Download, options: URLImageOptions) {
        self.downloadManager = downloadManager
        self.download = download
        self.options = options

        if options.cachePolicy.isReturnCache,
           let transientImage = URLImageService.shared.inMemoryCache.getImage(withIdentifier: options.identifier, orURL: download.url) {
            // Set image retrieved from cache
            self.loadingState = .success(transientImage)
        }
    }

    public typealias LoadingState = RemoteContentLoadingState<Image, Float?>

    @Published public private(set) var loadingState: LoadingState = .initial

    private var cancellables = Set<AnyCancellable>()
    private var delayedDownload: DispatchWorkItem?

    public func load() {
        guard !isLoading else {
            return
        }

        switch options.cachePolicy {
            case .returnCacheElseLoad:
                if !isLoadedSuccessfully {
                    returnCached { [weak self] success in
                        guard let self = self else { return }

                        if !success {
                            if let delay = self.options.downloadDelay {
                                self.startDownload(afterDelay: delay)
                            }
                            else {
                                self.startDownload()
                            }
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

                    if let delay = self.options.downloadDelay {
                        self.startDownload(afterDelay: delay)
                    }
                    else {
                        self.startDownload()
                    }
                }

            case .ignoreCache:
                if let delay = self.options.downloadDelay {
                    self.startDownload(afterDelay: delay)
                }
                else {
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

        // Cancel
        for cancellable in cancellables {
            cancellable.cancel()
        }

        cancellables.removeAll()

        delayedDownload?.cancel()
        delayedDownload = nil
    }

    private var isLoading: Bool {
        !cancellables.isEmpty
    }

    private var isLoadedSuccessfully: Bool {
        switch loadingState {
            case .success:
                return true
            default:
                return false
        }
    }

    private func startDownload(afterDelay delay: TimeInterval) {
        delayedDownload = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.startDownload()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: delayedDownload!)
    }

    private func startDownload() {
        loadingState = .inProgress(nil)

        downloadManager.transientImagePublisher(for: download, options: options)
            .receive(on: RunLoop.main)
            .map {
                .success($0.image)
            }
            .catch {
                Just(.failure($0))
            }
            .assign(to: \.loadingState, on: self)
            .store(in: &cancellables)
    }

    private func returnCached(_ completion: @escaping (_ success: Bool) -> Void) {
        loadingState = .inProgress(nil)

        URLImageService.shared.diskCache
            .getImagePublisher(withIdentifier: options.identifier, orURL: download.url)
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
            .store(in: &cancellables)
    }
}


fileprivate extension RemoteContentLoadingState where Value == Image {

    static func success(_ transientImage: TransientImage) -> RemoteContentLoadingState<Value, Progress> {
        .success(transientImage.image)
    }
}
