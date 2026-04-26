//
//  DownloadPublisher.swift
//  
//
//  Created by Dmytro Anokhin on 28/07/2020.
//

import Log
import Foundation

@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
public struct DownloadAsyncTask: Sendable {
    let download: Download
    let coordinator: URLSessionCoordinator
    
    init(download: Download, coordinator: URLSessionCoordinator) {
        self.download = download
        self.coordinator = coordinator
    }
    
    @available(macOS 15.0, iOS 18.0, *)
    func quickStart() -> some AsyncSequence<DownloadInfo, DownloadError> {
        coordinator
            .startDownload(download)
            .compactMap { next in
                switch next {
                case .completion(download: _, .success(let value)):
                    return DownloadInfo.completion(value)
                case .completion(download: _, .failure(let error)):
                    throw error
                case .reportProgress(download: _, let progress):
                    return .progress(progress)
                default:
                    throw URLError(.badServerResponse)
                }
            }
    }
    
    func start() -> some AsyncSequence {
        coordinator
            .startDownload(download)
            .compactMap { next -> Result<DownloadInfo, DownloadError>? in
                switch next {
                case .completion(download: _, .success(let value)):
                    return .success(.completion(value))
                case .completion(download: _, .failure(let error)):
                    return .failure(error)
                case .reportProgress(download: _, let progress):
                    return .success(.progress(progress))
                default:
                    return nil
                }
            }
    }
}
