//
//  URLImageFetchManager.swift
//  
//
//  Created by Dmytro Anokhin on 26/12/2020.
//

import Foundation
import Combine


@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
final class URLImageFetchManager {

    unowned let service: URLImageService

    init(service: URLImageService) {
        self.service = service
    }

    func fetchImage(url: URL, options: URLImageOptions? = nil, deliverOn deliveryQueue: DispatchQueue = DispatchQueue.main, completion: @escaping (_ result: Result<ImageInfo, Error>) -> Void) -> UUID {

        let remoteImage = service.makeRemoteImage(url: url, options: options)
        let cancellable = remoteImage.$loadingState.sink { loadingState in
            switch loadingState {
                case .initial:
                    break

                case .inProgress(_):
                    break

                case .success(let transientImage):
                    deliveryQueue.async {
                        completion(.success(transientImage.info))
                    }

                case .failure(let error):
                    deliveryQueue.async {
                        completion(.failure(error))
                    }
            }
        }

        let uuid = UUID()
        registry[uuid] = (remoteImage: remoteImage, cancellable: cancellable)

        remoteImage.load()

        return uuid
    }

    private typealias ImageFetchInfo = (remoteImage: RemoteImage, cancellable: AnyCancellable)

    private var registry: [UUID: ImageFetchInfo] = [:]
}
