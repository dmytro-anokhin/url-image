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

    func loadImage(for url: URL, completion: @escaping (Result<ImageType, Error>) -> Void)

    func saveImage(_ image: ImageType, for url: URL)
}
