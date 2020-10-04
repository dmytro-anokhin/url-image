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

    func image(withURL url: URL, identifier: String?) -> TransientImage? {
        image(withIdentifier: identifier ?? url.absoluteString)
    }

    func cacheTransientImage(_ transientImage: TransientImage, withURL url: URL, identifier: String?) {
        cacheTransientImage(transientImage, withIdentifier: identifier ?? url.absoluteString)
    }

    private final class TransientImageWrapper {

        let transientImage: TransientImage

        init(_ transientImage: TransientImage) {
            self.transientImage = transientImage
        }
    }

    private let nsCache = NSCache<NSString, TransientImageWrapper>()

    private func image(withIdentifier identifier: String) -> TransientImage? {
        let key = identifier as NSString
        let wrapper = nsCache.object(forKey: key)

        return wrapper?.transientImage
    }

    private func cacheTransientImage(_ transientImage: TransientImage, withIdentifier identifier: String) {
        let key = identifier as NSString
        let wrapper = TransientImageWrapper(transientImage)

        nsCache.setObject(wrapper, forKey: key)
    }
}
