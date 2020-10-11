//
//  InMemoryCache.swift
//  
//
//  Created by Dmytro Anokhin on 02/10/2020.
//

import Foundation


final class InMemoryCache {

    init() {
    }

    func getImage(withIdentifier identifier: String?, orURL url: URL) -> TransientImage? {
        let key = (identifier ?? url.absoluteString) as NSString

        guard let wrapper = nsCache.object(forKey: key) else {
            return nil
        }

        return wrapper.transientImage
    }

    func cacheTransientImage(_ transientImage: TransientImage, withURL url: URL, identifier: String?, expireAfter expiryInterval: TimeInterval? = nil) {
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

        let transientImage: TransientImage

        let dateCreated: Date

        let expiryInterval: TimeInterval?

        init(transientImage: TransientImage, dateCreated: Date, expiryInterval: TimeInterval?) {
            self.transientImage = transientImage
            self.dateCreated = dateCreated
            self.expiryInterval = expiryInterval
        }
    }

    private let nsCache = NSCache<NSString, TransientImageWrapper>()
}
