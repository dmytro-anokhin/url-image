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

    /// Reference to URLImageService used to download and cache the image.
    unowned let service: URLImageService

    /// Download object describes how the image should be downloaded.
    let download: Download

    let options: URLImageOptions

    public init(service: URLImageService, download: Download, options: URLImageOptions) {
        self.service = service
        self.download = download
        self.options = options
    }

    public typealias LoadingState = RemoteContentLoadingState<Image, Float?>

    @Published public private(set) var loadingState: LoadingState = .initial

    public func preload() {
        if options.cachePolicy.isReturnCache,
           let transientImage = service.inMemoryCache.getImage(withIdentifier: options.identifier, orURL: download.url) {
            // Set image retrieved from cache
            self.loadingState = .success(transientImage)
//            print("Image for \(download.url) is in the in memory cache")
        }
        else {
//            print("Image for \(download.url) not in the in memory cache")
        }
    }

    public func load() {
        guard !isLoading else {
            return
        }

        guard !(options.cachePolicy.isReturnCache && loadingState.isSuccess) else {
            return
        }

        isLoading = true

        switch options.cachePolicy {
            case .returnCacheElseLoad(let cacheDelay, let downloadDelay):
                if !isLoadedSuccessfully {
                    scheduleReturnCached(afterDelay: cacheDelay) { [weak self] success in
                        guard let self = self else { return }

                        if !success {
                            self.scheduleDownload(afterDelay: downloadDelay, secondCacheLookup: true)
                        }
                    }
                }

            case .returnCacheDontLoad(let delay):
                if !isLoadedSuccessfully {
                    scheduleReturnCached(afterDelay: delay) { [weak self] success in
                        guard let self = self else { return }

                        if !success {
                            self.loadingState = .initial
                            self.isLoading = false
                        }
                    }
                }

            case .returnCacheReload(let cacheDelay, let downloadDelay):
                scheduleReturnCached(afterDelay: cacheDelay) { [weak self] success in
                    guard let self = self else { return }
                    self.scheduleDownload(afterDelay: downloadDelay)
                }

            case .ignoreCache(let delay):
                scheduleDownload(afterDelay: delay)
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

    private func scheduleReturnCached(afterDelay delay: TimeInterval?, completion: @escaping (_ success: Bool) -> Void) {
        guard let delay = delay else {
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
    private func scheduleDownload(afterDelay delay: TimeInterval?, secondCacheLookup: Bool = false) {
        guard let delay = delay else {
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

        service.downloadManager.publisher(for: download)
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

        service.diskCache
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
//                    print("Image for \(self.download.url) is in the disk cache")
                    // Move to in memory cache
                    self.service.inMemoryCache.cacheTransientImage(transientImage,
                                                                   withURL: self.download.url,
                                                                   identifier: self.options.identifier,
                                                                   expireAfter: self.options.expiryInterval)
                    // Set image retrieved from cache
                    self.loadingState = .success(transientImage)
                    completion(true)
                }
                else {
//                    print("Image for \(self.download.url) not in the disk cache")
                    completion(false)
                }
            }
            .store(in: &cancellables)
    }

    private func decode(result: DownloadResult) throws -> TransientImageType {
        switch result {
            case .data(let data):

                guard let transientImage = TransientImage(data: data) else {
                    throw URLImageError.decode
                }

                let fileName = UUID().uuidString
                let fileExtension = ImageDecoder.preferredFileExtension(forTypeIdentifier: transientImage.uti)

                service.diskCache.cacheImageData(data,
                                                 url: download.url,
                                                 identifier: options.identifier,
                                                 fileName: fileName,
                                                 fileExtension: fileExtension,
                                                 expireAfter: options.expiryInterval)

                service.inMemoryCache.cacheTransientImage(transientImage,
                                                          withURL: download.url,
                                                          identifier: options.identifier,
                                                          expireAfter: options.expiryInterval)

                return transientImage

            case .file(let path):

                let location = URL(fileURLWithPath: path)

                guard let transientImage = TransientImage(location: location) else {
                    throw URLImageError.decode
                }

                let fileName = UUID().uuidString
                let fileExtension: String?

                if !location.pathExtension.isEmpty {
                    fileExtension = location.pathExtension
                }
                else {
                    fileExtension = ImageDecoder.preferredFileExtension(forTypeIdentifier: transientImage.uti)
                }

                service.diskCache.cacheImageFile(at: location,
                                                 url: download.url,
                                                 identifier: options.identifier,
                                                 fileName: fileName,
                                                 fileExtension: fileExtension,
                                                 expireAfter: options.expiryInterval)

                service.inMemoryCache.cacheTransientImage(transientImage,
                                                          withURL: download.url,
                                                          identifier: options.identifier,
                                                          expireAfter: options.expiryInterval)

                return transientImage
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

    static func success(_ transientImage: TransientImageType) -> RemoteContentLoadingState<Value, Progress> {
        .success(transientImage.image)
    }
}


private extension URLImageOptions.CachePolicy {

    var isReturnCache: Bool {
        switch self {
            case .returnCacheElseLoad, .returnCacheDontLoad, .returnCacheReload:
                return true
            default:
                return false
        }
    }
}
