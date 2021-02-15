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


public final class URLImageInMemoryStore {

    public init() {
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

    private final class ObjectWrapper {

        let image: Any

        let info: URLImageStoreInfo

        init(image: Any, info: URLImageStoreInfo) {
            self.image = image
            self.info = info
        }
    }

    private let cache = NSCache<KeyWrapper, ObjectWrapper>()
}


extension URLImageInMemoryStore: URLImageInMemoryStoreType {

    public func removeAllImages() {
        cache.removeAllObjects()
    }

    public func removeImageWithURL(_ url: URL) {
        let key = URLImageStoreKey.url(url)
        let keyWrapper = KeyWrapper(key: key)
        cache.removeObject(forKey: keyWrapper)
    }

    public func removeImageWithIdentifier(_ identifier: String) {
        let key = URLImageStoreKey.identifier(identifier)
        let keyWrapper = KeyWrapper(key: key)
        cache.removeObject(forKey: keyWrapper)
    }

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
        let imageWrapper = ObjectWrapper(image: image, info: info)

        let urlKey = URLImageStoreKey.url(info.url)
        let urlKeyWrapper = KeyWrapper(key: urlKey)
        cache.setObject(imageWrapper, forKey: urlKeyWrapper)

        if let identifier = info.identifier {
            let identifierKey = URLImageStoreKey.identifier(identifier)
            let identifierKeyWrapper = KeyWrapper(key: identifierKey)
            cache.setObject(imageWrapper, forKey: identifierKeyWrapper)
        }
    }
}
