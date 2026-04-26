//
//  RemoteImage.swift
//  
//
//  Created by Dmytro Anokhin on 25/08/2020.
//

import SwiftUI
@preconcurrency import Combine
import Model
import DownloadManager
import ImageDecoder
import Log

fileprivate let queue = DispatchQueue(label: "com.url.image.workitem")

@available(macOS 11.0, *)
final class RemoteImageWrapper: ObservableObject {
    @Published var remote: RemoteImage?
}

@globalActor
public actor RemoteImageActor {
    public static let shared = RemoteImageActor()
}

@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
public final class RemoteImage : ObservableObject, Sendable {

    /// Reference to URLImageService used to download and store the image.
    unowned let service: URLImageService

    /// Download object describes how the image should be downloaded.
    let download: Download

    let identifier: String?

    let options: URLImageOptions
    
    let debugDate: Date
    
    @RemoteImageActor var stateCancellable: AnyCancellable?
    @RemoteImageActor var updatedTask: Task<Void, Never>?

    init(service: URLImageService, download: Download, identifier: String?, options: URLImageOptions) {
        self.service = service
        self.download = download
        self.identifier = identifier
        self.options = options
        self.debugDate = Date()
        
        stateBind()

        log_debug(nil, #function, download.url.absoluteString)
        
    }
    
    private func stateBind() {
        let cancellable = loadingStatePublisher
            .sink(receiveValue: { [weak self] state in
                self?.notifyState(state)
            })
        
        Task { @RemoteImageActor in
            stateCancellable = cancellable
        }
    }

    deinit {
        stateCancellable?.cancel()
        updatedTask?.cancel()
        log_debug(nil, #function, download.url.absoluteString, detail: log_detailed)
    }

    public typealias LoadingState = RemoteImageLoadingState

    /// External loading state used to update the view
    let loadingState = CurrentValueSubject<LoadingState, Never>(.initial)
    let slowLoadingState = CurrentValueSubject<LoadingState, Never>(.initial)
    
    private var progressStatePublisher: AnyPublisher<RemoteImageLoadingState, Never> {
        loadingState
            .filter({ $0.isInProgress })
            .collect(.byTime(queue, .milliseconds(100)))
            .compactMap(\.last)
            .eraseToAnyPublisher()
    }
    
    private var nonProgressStatePublisher: AnyPublisher<RemoteImageLoadingState, Never> {
        loadingState
            .filter({ !$0.isInProgress })
            .eraseToAnyPublisher()
    }
    
    private var loadingStatePublisher: AnyPublisher<RemoteImageLoadingState, Never> {
        nonProgressStatePublisher
            .merge(with: progressStatePublisher)
            .scan(LoadingState.initial, { current, next in
                next.isInProgress && current.isComplete ? current:next
            })
            .removeDuplicates()
            .receive(on: DispatchQueue(label: "com.image.\(download.id)"))
            .eraseToAnyPublisher()
    }
    
    public func load() {
        Task { @RemoteImageActor in
            await self.queueLoad()
        }
    }
    
    @RemoteImageActor
    private func queueLoad() async {
        guard !isLoading else {
            return
        }
        
        log_debug(self, #function, "Start load for: \(download.url)", detail: log_normal)
        
        updateIsLoading(true)
        
        switch options.fetchPolicy {
        case .returnStoreElseLoad(let downloadDelay):
            guard !isLoadedSuccessfully else {
                // Already loaded
                updateIsLoading(false)
                return
            }
            
            guard await !loadFromInMemoryStore() else {
                // Loaded from the in-memory store
                updateIsLoading(false)
                return
            }
            
            let success = await scheduleReturnStored(afterDelay: nil)
            if !success {
                self.scheduleDownload(afterDelay: downloadDelay, secondStoreLookup: true)
            }
        case .returnStoreDontLoad:
            guard !isLoadedSuccessfully else {
                // Already loaded
                updateIsLoading(false)
                return
            }
            
            guard await !loadFromInMemoryStore() else {
                // Loaded from the in-memory store
                updateIsLoading(false)
                return
            }
            
            let success = await scheduleReturnStored(afterDelay: nil)
            if !success {
                updateLoadingState(.initial)
                updateIsLoading(false)
            }
        }
    }

    public func cancel() {
        Task { @RemoteImageActor in
            self.queueCancel()
        }
    }
    
    public func onDissAppear() {
        Task { @RemoteImageActor [weak self] in
            self?.updatedTask?.cancel()
            self?.isLoading = false
        }
    }
    
    @RemoteImageActor
    private func queueCancel() {
        guard isLoading else {
            return
        }

        log_debug(self, #function, "Cancel load for: \(download.url)", detail: log_normal)

        isLoading = false
    }
    
    private func notifyState(_ state: LoadingState) {
        let slowLoadingState = self.slowLoadingState
        Task { @MainActor in
            slowLoadingState.send(state)
        }
    }

    /// Internal loading state
    @RemoteImageActor private var isLoading: Bool = false
}


@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
extension RemoteImage {

    private var isLoadedSuccessfully: Bool {
        switch loadingState.value {
            case .success:
                return true
            default:
                return false
        }
    }

    /// Rerturn an image from the in memory store.
    ///
    /// Sets `loadingState` to `.success` if an image is in the in-memory store and returns `true`. Otherwise returns `false` without changing the state.
    private func loadFromInMemoryStore() async -> Bool {
        guard let store = service.inMemoryStore else {
            log_debug(self, #function, "Not using in memory store for \(download.url)", detail: log_normal)
            return false
        }

        guard let transientImage: TransientImage = await store.getImage(memoryKeys) else {
            log_debug(self, #function, "Image for \(download.url) not in the in memory store", detail: log_normal)
            return false
        }

        // Complete
        self.updateLoadingState(.success(transientImage))
        log_debug(self, #function, "Image for \(download.url) is in the in memory store", detail: log_normal)

        return true
    }
    
    private func scheduleReturnStored(afterDelay delay: TimeInterval?) async -> Bool {
        guard let delay = delay else {
            // Read from store immediately if no delay needed
            return await returnStored()
        }
        
        if #available(iOS 16.0, macOS 13, *) {
            try? await Task.sleep(for: .seconds(delay))
        } else {
            // Fallback on earlier versions
            try? await Task.sleep(nanoseconds: UInt64(1_000_000_000 * delay))
        }
        
        return await returnStored()
    }

    // Second store lookup is necessary for a case if the same image was downloaded by another instance of RemoteImage
    private func scheduleDownload(afterDelay delay: TimeInterval? = nil, secondStoreLookup: Bool = false) {
        guard let _ = delay else {
            // Start download immediately if no delay needed
            startAndUpdateDownload()
            return
        }
        
        if secondStoreLookup {
            Task { [weak self] in
                let success = await self?.returnStored() ?? false
                if !success, let self {
                    await self.updateUpdatedTask()
                }
            }
        } else {
            startAndUpdateDownload()
        }
    }
    
    private func startAndUpdateDownload() {
        Task { [weak self] in
            await self?.updateUpdatedTask()
        }
    }
    
    private func startDownload() async {
        updateLoadingState(.inProgress(nil))
        
        let infos = service.downloadManager.download(for: download)
        let download = download
        let identifier = identifier
        let options = options
        let service = service
        for await info in infos {
            switch info {
            case .success(let success):
                switch success {
                case .progress(let progress):
                    updateLoadingState(.inProgress(progress))
                case .completion(let result):
                    do {
                        let transientImage = try await Task {
                            try await service.decode(
                                result: result,
                                download: download,
                                identifier: identifier,
                                options: options
                            )
                        }.value
                        updateLoadingState(.success(transientImage))
                    } catch {
                        // This route happens when download succeeds, but decoding fails
                        updateLoadingState(.failure(error))
                    }
                }
            case .failure(let error):
                print("bad update")
                updateLoadingState(.failure(error))
            }
        }
    }
    
    private func returnStored() async -> Bool {
        loadingState.send(.inProgress(nil))

        guard let store = service.fileStore else {
            return false
        }

        let transientImage = try? await store.getImage(keys, maxPixelSize: options.maxPixelSize)
        guard let transientImage else {
            log_debug(self, #function, "Image for \(download.url) not in the disk store", detail: log_normal)
            return false
        }
        
        log_debug(self, #function, "Image for \(self.download.url) is in the disk store", detail: log_normal)
        // Store in memory
        let info = URLImageStoreInfo(url: download.url, identifier: identifier, uti: transientImage.uti)

        if URLImageService.shouldStoreInMemory(uti: transientImage.uti) {
            await service.inMemoryStore?.store(transientImage, info: info)
        }

        // Complete
        loadingState.send(.success(transientImage))
        return true
    }
    
    private func updateLoadingState(_ loadingState: LoadingState) {
        self.loadingState.send(loadingState)
    }
    
    @RemoteImageActor
    private func updateIsLoading(_ loading: Bool) {
        self.isLoading = loading
    }
    
    @RemoteImageActor
    private func updateUpdatedTask() {
        self.updatedTask?.cancel()
        self.updatedTask = Task { [weak self] in
            await self?.startDownload()
        }
    }

    /// Helper to return `URLImageStoreKey` objects based on `URLImageOptions` and `Download` properties
    private var keys: [URLImageKey] {
        var keys: [URLImageKey] = []

        // Identifier must precede URL
        if let identifier = identifier {
            keys.append(.identifier(identifier))
        }

        keys.append(.url(download.url))

        return keys
    }

    private var memoryKeys: [URLImageKey] {
        Self.memoryLookupKeys(identifier: identifier, url: download.url)
    }

    nonisolated static func memoryLookupKeys(identifier: String?, url: URL) -> [URLImageKey] {
        if let identifier {
            return [.identifier(identifier)]
        }

        return [.url(url)]
    }
}
