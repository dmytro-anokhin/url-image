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

        if wrapper.isExpired {
            nsCache.removeObject(forKey: key)
            return nil
        }
        else {
            return wrapper.transientImage
        }
    }

    func cacheTransientImage(_ transientImage: TransientImage, withURL url: URL, identifier: String?, expireAfter expiryInterval: TimeInterval? = nil) {
        let key = (identifier ?? url.absoluteString) as NSString
        let wrapper = TransientImageWrapper(transientImage: transientImage,
                                            dateCreated: Date(),
                                            expiryInterval: expiryInterval)

        nsCache.setObject(wrapper, forKey: key)
    }

    private final class TransientImageWrapper {

        let transientImage: TransientImage

        let dateCreated: Date

        let expiryInterval: TimeInterval?

        init(transientImage: TransientImage, dateCreated: Date, expiryInterval: TimeInterval?) {
            self.transientImage = transientImage
            self.dateCreated = dateCreated
            self.expiryInterval = expiryInterval
        }

        var isExpired: Bool {
            guard let expiryInterval = expiryInterval else {
                return false
            }

            return dateCreated.addingTimeInterval(expiryInterval) < Date()
        }
    }

    private let nsCache = NSCache<NSString, TransientImageWrapper>()
}
