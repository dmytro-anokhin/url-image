//
//  ImageLoaderObserver.swift
//  URLImage
//
//
//  Created by Dmytro Anokhin on 29/08/2019.
//  Copyright © 2019 Dmytro Anokhin. All rights reserved.
//

import SwiftUI


@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
final class ImageLoaderObserver {

    let progress: ImageLoaderProgressCallback

    let partial: ImageLoaderPartialCallback

    let completion: ImageLoaderCompletionCallback

    init(progress: @escaping ImageLoaderProgressCallback, partial: @escaping ImageLoaderPartialCallback, completion: @escaping ImageLoaderCompletionCallback) {
        self.progress = progress
        self.partial = partial
        self.completion = completion
    }
}


@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
extension ImageLoaderObserver: Equatable {

    static func == (lhs: ImageLoaderObserver, rhs: ImageLoaderObserver) -> Bool {
        return lhs === rhs
    }
}


@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
extension ImageLoaderObserver: Hashable {

    func hash(into hasher: inout Hasher) {
        let pointer = Unmanaged.passUnretained(self).toOpaque()
        hasher.combine(pointer)
    }
}
