//
//  RemoteObject.swift
//  
//
//  Created by Dmytro Anokhin on 16/08/2020.
//

import Combine
import Foundation


@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
final class RemoteObject<T> : ObservableObject {

    let download: Download

    unowned let downloadManager: DownloadManager

    let decode: (_ data: Data) throws -> T

    init(download: Download, downloadManager: DownloadManager, decode: @escaping (_ data: Data) throws -> T) {
        self.download = download
        self.downloadManager = downloadManager
        self.decode = decode
    }

    /// The state of the loading process.
    ///
    /// The `LoadingState` serves dual purpose:
    /// - represents the state of the loading process: none, in progress, success or failure;
    /// - keeps associated value relevant to the state of the loading process.
    ///
    /// This dual purpose allows `View` to switch over the state in its `body` and return different view in each case.
    ///
    enum LoadingState<T> {

        case none

        case inProgress

        case success(_ value: T)

        case failure(_ error: Error)
    }

    @Published private(set) var loadingState: LoadingState<T> = .none

    func load() {
        guard cancellable == nil else {
            return
        }

        // Set state to in progress
        loadingState = .inProgress

        // Start loading
        cancellable = downloadManager
            .publisher(for: download)
            // .decode(type: Decodable.Protocol, decoder: TopLevelDecoder)
            .tryMap { result in
                // Decode
                switch result {
                    case .data(let data):
                        let object = try self.decode(data)
                        return .success(object)

                    case .file(let path):
                        fatalError("Not implemented")
                }
            }
            .catch {
                // Process error
                Just(.failure($0))
            }
            .receive(on: RunLoop.main)
            .assign(to: \.loadingState, on: self)
    }

    func cancel() {
        guard cancellable != nil else {
            return
        }

        // Reset loading state
        loadingState = .none

        // Stop loading
        cancellable?.cancel()
        cancellable = nil
    }

    private var cancellable: AnyCancellable?
}
