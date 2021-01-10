//
//  URLImageCacheType.swift
//  
//
//  Created by Dmytro Anokhin on 10/01/2021.
//

import Foundation
import Combine
import CoreGraphics

#if canImport(Common)
import Common
#endif

#if canImport(DownloadManager)
import DownloadManager
#endif


@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public protocol URLImageCacheType {

    func getImage(withIdentifier identifier: String?,
                  orURL url: URL, maxPixelSize: CGSize?,
                  _ completion: @escaping (_ result: Result<TransientImage?, Swift.Error>) -> Void)
}


@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension URLImageCacheType {

    func getImagePublisher(withIdentifier identifier: String?, orURL url: URL, maxPixelSize: CGSize?) -> AnyPublisher<TransientImage?, Swift.Error> {
        Future<TransientImage?, Swift.Error> { promise in
            self.getImage(withIdentifier: identifier, orURL: url, maxPixelSize: maxPixelSize) {
                promise($0)
            }
        }.eraseToAnyPublisher()
    }
}
