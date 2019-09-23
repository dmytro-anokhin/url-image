//
//  ImageLoaderObserver.swift
//  URLImage
//
//
//  Created by Dmytro Anokhin on 29/08/2019.
//  Copyright © 2019 Dmytro Anokhin. All rights reserved.
//

import SwiftUI


final class ImageLoaderObserver {

    let progress: ImageLoaderProgressCallback

    let completion: ImageLoaderCompletionCallback

    init(progress: @escaping ImageLoaderProgressCallback, completion: @escaping ImageLoaderCompletionCallback) {
        self.progress = progress
        self.completion = completion
    }
}


extension ImageLoaderObserver: Equatable {

    static func == (lhs: ImageLoaderObserver, rhs: ImageLoaderObserver) -> Bool {
        return lhs === rhs
    }
}


extension ImageLoaderObserver: Hashable {

    func hash(into hasher: inout Hasher) {
        let pointer = Unmanaged.passUnretained(self).toOpaque()
        hasher.combine(pointer)
    }
}
