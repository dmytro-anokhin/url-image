//
//  InMemoryCache.swift
//  
//
//  Created by Dmytro Anokhin on 02/10/2020.
//

import Foundation


final public class InMemoryCache {

    private final class TransientImageWrapper {

        let transientImage: TransientImage

        init(_ transientImage: TransientImage) {
            self.transientImage = transientImage
        }
    }

    private let nsCache = NSCache<NSURL, TransientImageWrapper>()

    init() {
    }

    public func image(with url: URL) -> TransientImage? {
        nsCache.object(forKey: url as NSURL)?.transientImage
    }

    func cacheTransientImage(_ transientImage: TransientImage, for url: URL) {
        nsCache.setObject(TransientImageWrapper(transientImage), forKey: url as NSURL)
    }
}
