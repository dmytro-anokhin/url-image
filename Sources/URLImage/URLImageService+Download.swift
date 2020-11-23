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
            let remoteImage = RemoteImage(service: service, download: download, options: options)

            remoteImage.$loadingState.sink { loadingState in
                switch loadingState {
                    case .initial:
                        break
                    case .inProgress(_):
                        break
                    case .success(let transientImage):
                        completion?(.success(transientImage))
                    case .failure(let error):
                        completion?(.failure(error))
                }
            }
            .store(in: &cancellables)

            remoteImage.load()

            pool[url] = remoteImage
        }

        private var pool: [URL: RemoteImage] = [:]

        private var cancellables = Set<AnyCancellable>()
    }
}
