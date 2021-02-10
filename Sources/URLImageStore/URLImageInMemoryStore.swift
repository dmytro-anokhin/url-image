//
//  URLImageInMemoryStore.swift
//  
//
//  Created by Dmytro Anokhin on 09/02/2021.
//

import Foundation

#if canImport(URLImage)
import URLImage
#endif


public final class URLImageInMemoryStore: URLImageInMemoryStoreType {

    public init() {
    }

    // MARK: - URLImageInMemoryStoreType

    public func getImage<T>(_ keys: [URLImageStoreKey]) -> T? {
        for key in keys.map({ KeyWrapper(key: $0) }) {
            guard let object = cache.object(forKey: key) else {
                continue
            }

            return object.image as? T
        }

        return nil
    }

    public func store<T>(_ image: T, info: URLImageStoreInfo) {
        let imageWrapper = ImageWrapper(image: image, info: info)

        let urlKey = URLImageStoreKey.url(info.url)
        let urlKeyWrapper = KeyWrapper(key: urlKey)
        cache.setObject(imageWrapper, forKey: urlKeyWrapper)

        if let identifier = info.identifier {
            let identifierKey = URLImageStoreKey.identifier(identifier)
            let identifierKeyWrapper = KeyWrapper(key: identifierKey)
            cache.setObject(imageWrapper, forKey: identifierKeyWrapper)
        }
    }

    // MARK: - Private

    private final class KeyWrapper: NSObject {

        let key: URLImageStoreKey

        init(key: URLImageStoreKey) {
            self.key = key
        }

        override func isEqual(_ object: Any?) -> Bool {
            guard let wrapper = object as? KeyWrapper else {
                return false
            }

            return key == wrapper.key
        }

        override var hash: Int {
            key.hashValue
        }
    }

    private final class ImageWrapper {

        let image: Any

        let info: URLImageStoreInfo

        init(image: Any, info: URLImageStoreInfo) {
            self.image = image
            self.info = info
        }
    }

    private let cache = NSCache<KeyWrapper, ImageWrapper>()
}
