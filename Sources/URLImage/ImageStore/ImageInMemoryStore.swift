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

    func loadImage(for remoteURL: URL, completion: @escaping (Result<(UIImage, URL?), Swift.Error>) -> Void) {
        if let image = cache.object(forKey: remoteURL as NSURL) {
            completion(.success((image, nil)))
        }
        else {
            completion(.failure(Error.generic))
        }
    }

    func saveImage(_ image: UIImage, remoteURL: URL, localURL: URL) {
        cache.setObject(image, forKey: remoteURL as NSURL)
    }

    private let cache = NSCache<NSURL, UIImage>()
}
