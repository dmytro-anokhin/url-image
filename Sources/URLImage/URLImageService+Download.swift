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
    public final class DownloadScheduler {

        unowned let service: URLImageService

        init(service: URLImageService) {
            self.service = service
        }

        public typealias DownloadCompletion = (Result<TransientImageType, Error>) -> Void

        public func downloadImage(url: URL, options: URLImageOptions? = nil, completion: DownloadCompletion? = nil) {

            let options = options ?? service.defaultOptions
            let download = Download(url: url, options: options)

            service.downloadManager.publisher(for: download)
                .sink { [weak self] result in
                    guard let self = self else {
                        return
                    }

                    switch result {
                        case .finished:
                            break

                        case .failure(let error):
                            completion?(.failure(error))
                    }
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
                                let image = try self.service.decode(result: result, download: download, options: options)
                                completion?(.success(image))
                            }
                            catch {
                                completion?(.failure(error))
                            }
                    }
                }
                .store(in: &cancellables)
        }

        private var cancellables = Set<AnyCancellable>()
    }
}
