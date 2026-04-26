//
//  URLImageService+RemoteImage.swift
//  
//
//  Created by Dmytro Anokhin on 15/01/2021.
//

import Foundation
import Model
import DownloadManager

@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
extension URLImageService {
    public func makeRemoteImage(url: URL, identifier: String?, options: URLImageOptions) -> RemoteImage {
        let inMemory = fileStore == nil

        let destination = makeDownloadDestination(inMemory: inMemory)
        let urlRequestConfiguration = options.urlRequestConfiguration ?? makeURLRequestConfiguration(inMemory: inMemory)

        let download = Download(url: url, destination: destination, urlRequestConfiguration: urlRequestConfiguration)

        return RemoteImage(service: self, download: download, identifier: identifier, options: options)
    }
    
    public func remoteImagePublisher(_ url: URL, identifier: String?, options: URLImageOptions = URLImageOptions()) -> AsyncThrowingStream<ImageInfo, Error> {
        let remoteImage = makeRemoteImage(url: url, identifier: identifier, options: options)
        let operation: @Sendable (AsyncThrowingStream<ImageInfo, Error>.Continuation) async -> Void = { continuation in
            if #available(macOS 12.0, iOS 15, *) {
                let state = remoteImage.loadingState
                for await loadingState in state.values {
                    switch loadingState {
                    case .initial:
                        break
                        
                    case .inProgress:
                        break
                        
                    case .success(let transientImage):
                        continuation.yield(transientImage.info)
                        continuation.finish()
                        return
                        
                    case .failure(let error):
                        continuation.finish(throwing: error)
                        return
                    }
                }
            } else {
                // Fallback on earlier versions
                assert(false)
            }
        }
        let (stream, continuation) = AsyncThrowingStream<ImageInfo, Error>.makeStream(bufferingPolicy: .bufferingNewest(1))
        let task = Task {
            await operation(continuation)
        }
        continuation.onTermination = { _ in
            task.cancel()
        }
        return stream
    }

    /// Creates download destination depending if download must happen in memory or on disk
    private func makeDownloadDestination(inMemory: Bool) -> Download.Destination {
        if inMemory {
            return .inMemory
        }
        else {
            let path = FileManager.default.tmpFilePathInCachesDirectory()
            return .onDisk(path)
        }
    }

    private func makeURLRequestConfiguration(inMemory: Bool) -> Download.URLRequestConfiguration {
        if inMemory {
            return Download.URLRequestConfiguration()
        }
        else {
            return Download.URLRequestConfiguration(allHTTPHeaderFields: nil,
                                                    cachePolicy: .reloadIgnoringLocalCacheData)
        }
    }
}
