//
//  RemoteImage.swift
//  
//
//  Created by Dmytro Anokhin on 25/08/2020.
//

import SwiftUI
import Combine

#if canImport(Model)
import Model
#endif

#if canImport(DownloadManager)
import DownloadManager
#endif

#if canImport(ImageDecoder)
import ImageDecoder
#endif

#if canImport(Log)
import Log
#endif


@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public final class RemoteImage : ObservableObject {

    /// Reference to URLImageService used to download and store the image.
    unowned let service: URLImageService

    /// Download object describes how the image should be downloaded.
    let download: Download

    let options: URLImageOptions

    init(service: URLImageService, download: Download, options: URLImageOptions) {
        self.service = service
        self.download = download
        self.options = options

        log_debug(nil, #function, download.url.absoluteString)
    }

    deinit {
        log_debug(nil, #function, download.url.absoluteString, detail: log_detailed)
    }

    public typealias LoadingState = RemoteImageLoadingState<TransientImage, Float?>

    /// External loading state used to update the view
    @Published public private(set) var loadingState: LoadingState = .initial {
        willSet {
            log_debug(self, #function, "\(download.url) will transition from \(loadingState) to \(newValue)", detail: log_detailed)
        }
    }

    public func load() {
        guard !isLoading else {
            return
        }

        log_debug(self, #function, "Start load for: \(download.url)", detail: log_normal)

        isLoading = true

        switch options.fetchPolicy {
            case .returnStoreElseLoad(let downloadDelay):
                guard !isLoadedSuccessfully else {
                    // Already loaded
                    isLoading = false
                    return
                }

                guard !loadFromInMemoryStore() else {
                    // Loaded from the in-memory store
                    isLoading = false
                    return
                }

                // Disk lookup
                scheduleReturnStored(afterDelay: nil) { [weak self] success in
                    guard let self = self else { return }

                    if !success {
                        self.scheduleDownload(afterDelay: downloadDelay, secondStoreLookup: true)
                    }
                }

            case .returnStoreDontLoad:
                guard !isLoadedSuccessfully else {
                    // Already loaded
                    isLoading = false
                    return
                }

                guard !loadFromInMemoryStore() else {
                    // Loaded from the in-memory store
                    isLoading = false
                    return
                }

                // Disk lookup
                scheduleReturnStored(afterDelay: nil) { [weak self] success in
                    guard let self = self else { return }

                    if !success {
                        // Complete
                        self.loadingState = .initial
                        self.isLoading = false
                    }
                }
        }
    }

    public func cancel() {
        guard isLoading else {
            return
        }

        log_debug(self, #function, "Cancel load for: \(download.url)", detail: log_normal)

        isLoading = false

        // Cancel publishers
        for cancellable in cancellables {
            cancellable.cancel()
        }

        cancellables.removeAll()

        delayedReturnStored?.cancel()
        delayedReturnStored = nil

        delayedDownload?.cancel()
        delayedDownload = nil
    }

    /// Internal loading state
    private var isLoading: Bool = false

    private var cancellables = Set<AnyCancellable>()
    private var delayedReturnStored: DispatchWorkItem?
    private var delayedDownload: DispatchWorkItem?
}


@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension RemoteImage {

    private var isLoadedSuccessfully: Bool {
        switch loadingState {
            case .success:
                return true
            default:
                return false
        }
    }

    /// Rerturn an image from the in memory store.
    ///
    /// Sets `loadingState` to `.success` if an image is in the in-memory store and returns `true`. Otherwise returns `false` without changing the state.
    private func loadFromInMemoryStore() -> Bool {
        guard let store = service.inMemoryStore else {
            log_debug(self, #function, "Not using in memory store for \(download.url)", detail: log_normal)
            return false
        }

        guard let transientImage: TransientImage = store.getImage(storeKeys) else {
            log_debug(self, #function, "Image for \(download.url) not in the in memory store", detail: log_normal)
            return false
        }

        // Complete
        self.loadingState = .success(transientImage)
        log_debug(self, #function, "Image for \(download.url) is in the in memory store", detail: log_normal)

        return true
    }

    private func scheduleReturnStored(afterDelay delay: TimeInterval?, completion: @escaping (_ success: Bool) -> Void) {
        guard let delay = delay else {
            // Read from store immediately if no delay needed
            returnStored(completion)
            return
        }

        delayedReturnStored?.cancel()
        delayedReturnStored = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.returnStored(completion)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: delayedReturnStored!)
    }

    // Second store lookup is necessary, for a case if the same image was downloaded by another instance of RemoteImage
    private func scheduleDownload(afterDelay delay: TimeInterval? = nil, secondStoreLookup: Bool = false) {
        guard let delay = delay else {
            // Start download immediately if no delay needed
            startDownload()
            return
        }

        delayedDownload?.cancel()
        delayedDownload = DispatchWorkItem { [weak self] in
            guard let self = self else { return }

            if secondStoreLookup {
                self.returnStored { [weak self] success in
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
                        // This route happens when download fails
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
                            let transientImage = try self.service.decode(result: result,
                                                                         download: self.download,
                                                                         options: self.options)
                            self.updateLoadingState(.success(transientImage))
                        }
                        catch {
                            // This route happens when download succeeds, but decoding fails
                            self.updateLoadingState(.failure(error))
                        }
                }
            }
            .store(in: &cancellables)
    }

    private func returnStored(_ completion: @escaping (_ success: Bool) -> Void) {
        loadingState = .inProgress(nil)

        guard let store = service.fileStore else {
            completion(false)
            return
        }

        store.getImagePublisher(storeKeys, maxPixelSize: options.maxPixelSize)
            .receive(on: RunLoop.main)
            .catch { _ in
                Just(nil)
            }
            .sink { [weak self] in
                guard let self = self else {
                    return
                }

                if let transientImage = $0 {
                    log_debug(self, #function, "Image for \(self.download.url) is in the disk store", detail: log_normal)
                    // Store in memory
                    let info = URLImageStoreInfo(url: self.download.url,
                                                 identifier: self.options.identifier,
                                                 uti: transientImage.uti)

                    self.service.inMemoryStore?.store(transientImage, info: info)

                    // Complete
                    self.loadingState = .success(transientImage)
                    completion(true)
                }
                else {
                    log_debug(self, #function, "Image for \(self.download.url) not in the disk store", detail: log_normal)
                    completion(false)
                }
            }
            .store(in: &cancellables)
    }

    private func updateLoadingState(_ loadingState: LoadingState) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }

            self.loadingState = loadingState
        }
    }

    /// Helper to return `URLImageStoreKey` objects based on `URLImageOptions` and `Download` properties
    private var storeKeys: [URLImageStoreKey] {
        var keys: [URLImageStoreKey] = []

        // Identifier must precede URL
        if let identifier = options.identifier {
            keys.append(.identifier(identifier))
        }

        keys.append(.url(download.url))

        return keys
    }
}
