//
//  URLImageFileStoreType+Combine.swift
//  
//
//  Created by Dmytro Anokhin on 09/02/2021.
//

import Foundation
import CoreGraphics
import Combine
import Model


@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 6.0, *)
extension URLImageFileStoreType {

    func getImagePublisher(_ keys: [URLImageKey], maxPixelSize: CGSize?) -> AnyPublisher<TransientImage?, Swift.Error> {
        Future<TransientImage?, Swift.Error> { promise in
            self.getImage(keys) { location -> TransientImage in
                guard let transientImage = TransientImage(location: location, maxPixelSize: maxPixelSize) else {
                    throw URLImageError.decode
                }

                return transientImage
            }
            completion: { result in
                promise(result)
            }
        }.eraseToAnyPublisher()
    }
}
