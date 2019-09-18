//
//  InMemoryCacheService.swift
//  URLImage
//
//
//  Created by Dmytro Anokhin on 10/08/2019.
//  Copyright © 2019 Dmytro Anokhin. All rights reserved.
//

import Foundation


protocol InMemoryCacheService {

    func image(for remoteURL: URL) -> ImageWrapper?

    func setImage(_ image: ImageWrapper, for remoteURL: URL)
}


@available(iOS 10.0, *)
final class InMemoryCacheServiceImpl: InMemoryCacheService {

    static let shared = InMemoryCacheServiceImpl()

    init() {
    }

    func image(for remoteURL: URL) -> ImageWrapper? {
        return cache.object(forKey: remoteURL as NSURL)
    }

    func setImage(_ image: ImageWrapper, for remoteURL: URL) {
        cache.setObject(image, forKey: remoteURL as NSURL)
    }

    private let cache = NSCache<NSURL, ImageWrapper>()
}


struct InMemoryCacheServiceDummyImpl: InMemoryCacheService {

    func image(for remoteURL: URL) -> ImageWrapper? {
        return nil
    }

    func setImage(_ image: ImageWrapper, for remoteURL: URL) {
    }
}
