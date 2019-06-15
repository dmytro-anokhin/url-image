//
//  ImageStoreType.swift
//  URLImage
//
//  Created by Dmytro Anokhin on 07/06/2019.
//  Copyright © 2019 Dmytro Anokhin. All rights reserved.
//

import Foundation


protocol ImageStoreType {

    associatedtype ImageType

    /// Load image from the store. Completion result contains image and optional local file URL.
    func loadImage(for remoteURL: URL, completion: @escaping (Result<(ImageType, URL?), Error>) -> Void)

    /// Save image to the store.
    func saveImage(_ image: ImageType, remoteURL: URL, localURL: URL)
}
