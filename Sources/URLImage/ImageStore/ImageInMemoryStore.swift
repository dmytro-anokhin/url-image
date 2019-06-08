//
//  ImageInMemoryStore.swift
//  URLImage
//
//  Created by Dmytro Anokhin on 07/06/2019.
//  Copyright © 2019 Dmytro Anokhin. All rights reserved.
//

import UIKit


struct ImageInMemoryStore : ImageStoreType {

    enum Error : Swift.Error {

        case generic
    }

    func loadImage(for url: URL, completion: @escaping (Result<UIImage, Swift.Error>) -> Void) {
        if let image = cache.object(forKey: url as NSURL) {
            completion(.success(image))
        }
        else {
            completion(.failure(Error.generic))
        }
    }

    func saveImage(_ image: UIImage, for url: URL) {
        cache.setObject(image, forKey: url as NSURL)
    }

    private let cache = NSCache<NSURL, UIImage>()
}
