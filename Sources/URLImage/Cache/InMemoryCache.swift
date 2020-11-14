//
//  InMemoryCache.swift
//  
//
//  Created by Dmytro Anokhin on 02/10/2020.
//

import Foundation


@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
final class InMemoryCache {

    init() {
    }

    func getImage(withIdentifier identifier: String?, orURL url: URL) -> TransientImageType? {
        let key = (identifier ?? url.absoluteString) as NSString

        guard let wrapper = nsCache.object(forKey: key) else {
            return nil
        }

        return wrapper.transientImage
    }

    func cacheTransientImage(_ transientImage: TransientImageType, withURL url: URL, identifier: String?, expireAfter expiryInterval: TimeInterval? = nil) {
        let key = (identifier ?? url.absoluteString) as NSString
        let wrapper = TransientImageWrapper(transientImage: transientImage,
                                            dateCreated: Date(),
                                            expiryInterval: expiryInterval)

        nsCache.setObject(wrapper, forKey: key)
    }

    // MARK: - Cleanup

    func cleanup() {
        nsCache.removeAllObjects()
    }

    func removeAll() {
        nsCache.removeAllObjects()
    }

    func delete(withIdentifier identifier: String?, orURL url: URL?) {
        if let identifier = identifier {
            nsCache.removeObject(forKey: identifier as NSString)
        }
        else if let url = url {
            nsCache.removeObject(forKey: url.absoluteString as NSString)
        }
    }

    // MARK: - Private

    private final class TransientImageWrapper {

        let transientImage: TransientImageType

        let dateCreated: Date

        let expiryInterval: TimeInterval?

        init(transientImage: TransientImageType, dateCreated: Date, expiryInterval: TimeInterval?) {
            self.transientImage = transientImage
            self.dateCreated = dateCreated
            self.expiryInterval = expiryInterval
        }
    }

    private let nsCache = NSCache<NSString, TransientImageWrapper>()
}
