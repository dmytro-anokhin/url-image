//
//  RemoteImage.swift
//  
//
//  Created by Dmytro Anokhin on 25/08/2020.
//

import Combine
import SwiftUI
import DownloadManager
import ImageDecoder
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
    }

    public typealias LoadingState = RemoteContentLoadingState<Image, Float?>

    @Published public private(set) var loadingState: LoadingState = .initial

    public func preload() {
        if options.cachePolicy.isReturnCache,
           let transientImage = URLImageService.shared.inMemoryCache.getImage(withIdentifier: options.identifier, orURL: download.url) {
            // Set image retrieved from cache
            self.loadingState = .success(transientImage)
        }
    }

    public func load() {
        guard !isLoading else {
            return
        }

        isLoading = true

        switch options.cachePolicy {
            case .returnCacheElseLoad:
                if !isLoadedSuccessfully {
                    scheduleReturnCached { [weak self] success in
                        guard let self = self else { return }

                        if !success {
                            self.scheduleDownload(secondCacheLookup: true)
                        }
                    }
                }

            case .returnCacheDontLoad:
                if !isLoadedSuccessfully {
                    scheduleReturnCached { _ in
                    }
                }

            case .returnCacheReload:
                scheduleReturnCached { [weak self] success in
                    guard let self = self else { return }
                    self.scheduleDownload()
                }

            case .ignoreCache:
                scheduleDownload()
        }
    }

    public func cancel() {
        guard isLoading else {
            return
        }

        isLoading = false

        // Reset loading state
        loadingState = .initial

        // Cancel
        for cancellable in cancellables {
            cancellable.cancel()
        }

        cancellables.removeAll()

        delayedReturnCached?.cancel()
        delayedReturnCached = nil

        delayedDownload?.cancel()
        delayedDownload = nil
    }

    private var isLoading: Bool = false

    private var cancellables = Set<AnyCancellable>()
    private var delayedReturnCached: DispatchWorkItem?
    private var delayedDownload: DispatchWorkItem?
}


extension RemoteImage {

    private var isLoadedSuccessfully: Bool {
        switch loadingState {
            case .success:
                return true
            default:
                return false
        }
    }

    private func scheduleReturnCached(completion: @escaping (_ success: Bool) -> Void) {
        guard let delay = options.diskCacheDelay else {
            // Read from cache immediately if no delay needed
            returnCached(completion)
            return
        }

        delayedReturnCached?.cancel()
        delayedReturnCached = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.returnCached(completion)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: delayedReturnCached!)
    }

    // Second cache lookup is necessary, for some caching policies, for a case if the same image was downloaded by another instance of RemoteImage.
    private func scheduleDownload(secondCacheLookup: Bool = false) {
        guard let delay = options.downloadDelay else {
            // Start download immediately if no delay needed
            startDownload()
            return
        }

        delayedDownload?.cancel()
        delayedDownload = DispatchWorkItem { [weak self] in
            guard let self = self else { return }

            if secondCacheLookup {
                self.returnCached { [weak self] success in
                    guard let self = self else { return }

                    if !success {
                        self.startDownload()
                    }
                }
            }
            else {
                self.startDownload()
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: delayedDownload!)
    }

    private func startDownload() {
        loadingState = .inProgress(nil)

        downloadManager.publisher(for: download)
            .sink { [weak self] result in
                guard let self = self else {
                    return
                }

                switch result {
                    case .finished:
                        break

                    case .failure(let error):
                        self.updateLoadingState(.failure(error))
                }
            }
            receiveValue: { [weak self] info in
                guard let self = self else {
                    return
                }

                switch info {
                    case .progress(let progress):
                        self.updateLoadingState(.inProgress(progress))
                    case .completion(let result):
                        do {
                            let transientImage = try self.decode(result: result)
                            self.updateLoadingState(.success(transientImage))
                        }
                        catch {
                            self.updateLoadingState(.failure(error))
                        }
                }
            }
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
                    self.updateLoadingState(.success(transientImage))
                    completion(true)
                }
                else {
                    completion(false)
                }
            }
            .store(in: &cancellables)
    }

    private func decode(result: DownloadResult) throws -> TransientImage {
        switch result {
            case .data(let data):

                let decoder = ImageDecoder()
                decoder.setData(data, allDataReceived: true)

                guard let uti = decoder.uti else {
                    // Not an image data
                    throw URLImageError.decode
                }

                guard let image = decoder.createFrameImage(at: 0) else {
                    // Can not decode image, corrupted data
                    throw URLImageError.decode
                }

                let transientImage = TransientImage(cgImage: image,
                                                    cgOrientation: decoder.frameOrientation(at: 0),
                                                    uti: uti)

                URLImageService.shared.diskCache.cacheImageData(data,
                                                                url: download.url,
                                                                identifier: options.identifier,
                                                                fileName: options.identifier,
                                                                fileExtension: ImageDecoder.preferredFileExtension(forTypeIdentifier: uti),
                                                                expireAfter: options.expiryInterval)

                URLImageService.shared.inMemoryCache.cacheTransientImage(transientImage,
                                                                         withURL: download.url,
                                                                         identifier: options.identifier,
                                                                         expireAfter: options.expiryInterval)

                return transientImage

            case .file:
                fatalError("Not implemented")
        }
    }

    private func updateLoadingState(_ loadingState: LoadingState) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }

            self.loadingState = loadingState
        }
    }
}


private extension RemoteContentLoadingState where Value == Image {

    static func success(_ transientImage: TransientImage) -> RemoteContentLoadingState<Value, Progress> {
        .success(transientImage.image)
    }
}
