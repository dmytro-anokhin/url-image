//
//  ImageStoreGroup.swift
//  URLImage
//
//  Created by Dmytro Anokhin on 07/06/2019.
//  Copyright © 2019 Dmytro Anokhin. All rights reserved.
//

import Foundation


fileprivate struct ConcreteImageStore<ImageType> : ImageStoreType {

    init<I>(_ imageStore: I) where I : ImageStoreType, I.ImageType == ImageType {
        loadImageClosure = { url, completion in
            imageStore.loadImage(for: url) { completion($0) }
        }

        saveImageClosure = { image, url in
            imageStore.saveImage(image, for: url)
        }
    }

    func loadImage(for url: URL, completion: @escaping (Result<ImageType, Error>) -> Void) {
        loadImageClosure(url, completion)
    }

    func saveImage(_ image: ImageType, for url: URL) {
        saveImageClosure(image, url)
    }

    private let loadImageClosure: (_ url: URL, _ completion: @escaping (Result<ImageType, Error>) -> Void) -> Void

    private let saveImageClosure: (_ image: ImageType, _ url: URL) -> Void
}


struct ImageStoreGroup<ImageType> : ImageStoreType {

    enum GroupError : Error {

        case notFound
    }

    mutating func addStore<I>(_ store: I) where I : ImageStoreType, I.ImageType == ImageType {
        stores.append(ConcreteImageStore(store))
    }

    func loadImage(for url: URL, completion: @escaping (Result<ImageType, Error>) -> Void) {
        loadImage(for: url, stores: stores, completion: completion)
    }

    func saveImage(_ image: ImageType, for url: URL) {
        for store in stores {
            store.saveImage(image, for: url)
        }
    }

    private var stores: [ConcreteImageStore<ImageType>] = []

    private func loadImage(for url: URL, stores: [ConcreteImageStore<ImageType>], completion: @escaping (Result<ImageType, Error>) -> Void) {
        guard let first = stores.first else {
            completion(.failure(GroupError.notFound))
            return
        }

        first.loadImage(for: url) { result in
            switch result {
                case .success(let image):
                    completion(.success(image))

                case .failure(_):
                    self.loadImage(for: url, stores: Array<ConcreteImageStore<ImageType>>(stores.dropFirst()), completion: completion)
            }
        }
    }
}
