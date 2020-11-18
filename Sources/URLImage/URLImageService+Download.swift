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

        let downloadManager: DownloadManager

        let diskCache: DiskCache

        let inMemoryCache: InMemoryCache

        init(downloadManager: DownloadManager, diskCache: DiskCache, inMemoryCache: InMemoryCache) {
            self.downloadManager = downloadManager
            self.diskCache = diskCache
            self.inMemoryCache = inMemoryCache
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

            downloadManager.publisher(for: download)
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
                                _ = try self.decode(result: result, download: download, options: options)
                            }
                            catch {

                            }
                    }
                }
                .store(in: &cancellables)

            /*

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


             */
        }

        private var cancellables = Set<AnyCancellable>()

        private func decode(result: DownloadResult, download: Download, options: URLImageOptions) throws -> TransientImageType {
            switch result {
                case .data(let data):

                    guard let transientImage = TransientImage(data: data, maxPixelSize: options.maxPixelSize) else {
                        throw URLImageError.decode
                    }

                    let fileName = UUID().uuidString
                    let fileExtension = ImageDecoder.preferredFileExtension(forTypeIdentifier: transientImage.uti)

                    diskCache.cacheImageData(data,
                                             url: download.url,
                                             identifier: options.identifier,
                                             fileName: fileName,
                                             fileExtension: fileExtension,
                                             expireAfter: options.expiryInterval)

                    inMemoryCache.cacheTransientImage(transientImage,
                                                      withURL: download.url,
                                                      identifier: options.identifier,
                                                      expireAfter: options.expiryInterval)

                    return transientImage

                case .file(let path):

                    let location = URL(fileURLWithPath: path)

                    guard let transientImage = TransientImage(location: location, maxPixelSize: options.maxPixelSize) else {
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

                    diskCache.cacheImageFile(at: location,
                                             url: download.url,
                                             identifier: options.identifier,
                                             fileName: fileName,
                                             fileExtension: fileExtension,
                                             expireAfter: options.expiryInterval)

                    inMemoryCache.cacheTransientImage(transientImage,
                                                      withURL: download.url,
                                                      identifier: options.identifier,
                                                      expireAfter: options.expiryInterval)

                    return transientImage
            }
        }
    }

    public func downloadImage(url: URL, options: URLImageOptions? = nil) {
        downloadScheduler.downloadImage(url: url, options: options ?? defaultOptions)
    }
}
