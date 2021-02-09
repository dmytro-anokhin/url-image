//
//  URLImageStoreType+Combine.swift
//  
//
//  Created by Dmytro Anokhin on 09/02/2021.
//

import Foundation
import CoreGraphics
import Combine

#if canImport(Common)
import Common
#endif


@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension URLImageStoreType {

    func getImagePublisher(_ keys: [URLImageStoreKey], maxPixelSize: CGSize?) -> AnyPublisher<TransientImage?, Swift.Error> {
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
