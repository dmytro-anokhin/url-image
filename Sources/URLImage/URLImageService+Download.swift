//
//  URLImageService+Download.swift
//  
//
//  Created by Dmytro Anokhin on 18/11/2020.
//

import Foundation
import Combine

#if canImport(DownloadManager)
import DownloadManager
#endif

#if canImport(ImageDecoder)
import ImageDecoder
#endif


@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension URLImageService {

    /// Keeps track of running downloads
    final class DownloadScheduler {

        unowned let service: URLImageService

        init(service: URLImageService) {
            self.service = service
        }

        func downloadImage(url: URL, options: URLImageOptions) {

            let download: Download

            if options.loadOptions.contains(.inMemory) {
                download = Download(url: url)
            }
            else {
                let path = FileManager.default.tmpFilePathInCachesDirectory()
                download = Download(destination: .onDisk(path), url: url)
            }

            service.downloadManager.publisher(for: download)
                .sink { [weak self] result in
                }
                receiveValue: { [weak self] info in
                    guard let self = self else {
                        return
                    }

                    switch info {
                        case .progress(let progress):
                            break
                        case .completion(let result):
                            do {
                                _ = try self.service.decode(result: result, download: download, options: options)
                            }
                            catch {

                            }
                    }
                }
                .store(in: &cancellables)
        }

        private var cancellables = Set<AnyCancellable>()
    }

    public func downloadImage(url: URL, options: URLImageOptions? = nil) {
        downloadScheduler.downloadImage(url: url, options: options ?? defaultOptions)
    }
}
