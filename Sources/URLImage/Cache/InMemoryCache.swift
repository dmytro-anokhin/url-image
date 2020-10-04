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
        let wrapper = nsCache.object(forKey: key)

        return wrapper?.transientImage
    }

    func cacheTransientImage(_ transientImage: TransientImage, withURL url: URL, identifier: String?) {
        let key = (identifier ?? url.absoluteString) as NSString
        let wrapper = TransientImageWrapper(transientImage)

        nsCache.setObject(wrapper, forKey: key)
    }

    private final class TransientImageWrapper {

        let transientImage: TransientImage

        init(_ transientImage: TransientImage) {
            self.transientImage = transientImage
        }
    }

    private let nsCache = NSCache<NSString, TransientImageWrapper>()
}
