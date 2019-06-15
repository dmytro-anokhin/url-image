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
        loadImageClosure = { remoteURL, completion in
            imageStore.loadImage(for: remoteURL) { completion($0) }
        }

        saveImageClosure = { image, remoteURL, localURL in
            imageStore.saveImage(image, remoteURL: remoteURL, localURL: localURL)
        }
    }

    func loadImage(for url: URL, completion: @escaping (Result<(ImageType, URL?), Error>) -> Void) {
        loadImageClosure(url, completion)
    }

    func saveImage(_ image: ImageType, remoteURL: URL, localURL: URL) {
        saveImageClosure(image, remoteURL, localURL)
    }

    private let loadImageClosure: (_ remoteURL: URL, _ completion: @escaping (Result<(ImageType, URL?), Error>) -> Void) -> Void

    private let saveImageClosure: (_ image: ImageType, _ remoteURL: URL, _ localURL: URL) -> Void
}


struct ImageStoreGroup<ImageType> : ImageStoreType {

    enum GroupError : Error {

        case notFound
    }

    mutating func addStore<I>(_ store: I) where I : ImageStoreType, I.ImageType == ImageType {
        stores.append(ConcreteImageStore(store))
    }

    func loadImage(for remoteURL: URL, completion: @escaping (Result<(ImageType, URL?), Error>) -> Void) {
        loadImage(for: remoteURL, stores: stores, completion: completion)
    }

    func saveImage(_ image: ImageType, remoteURL: URL, localURL: URL) {
        for store in stores {
            store.saveImage(image, remoteURL: remoteURL, localURL: localURL)
        }
    }

    private var stores: [ConcreteImageStore<ImageType>] = []

    private func loadImage(for remoteURL: URL, stores: [ConcreteImageStore<ImageType>], completion: @escaping (Result<(ImageType, URL?), Error>) -> Void) {
        guard let first = stores.first else {
            completion(.failure(GroupError.notFound))
            return
        }

        first.loadImage(for: remoteURL) { result in
            switch result {
                case .success(let value):
                    completion(.success(value))

                case .failure(_):
                    self.loadImage(for: remoteURL, stores: Array<ConcreteImageStore<ImageType>>(stores.dropFirst()), completion: completion)
            }
        }
    }
}
