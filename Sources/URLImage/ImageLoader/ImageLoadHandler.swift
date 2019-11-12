//
//  ImageLoadHandler.swift
//  
//
//  Created by Dmytro Anokhin on 15/10/2019.
//

import CoreGraphics


@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
final class ImageLoadHandler {

    let processor: ImageProcessing?

    let observer: ImageLoaderObserver

    init(processor: ImageProcessing?, observer: ImageLoaderObserver) {
        self.processor = processor
        self.observer = observer
    }
}


@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
extension ImageLoadHandler: Equatable {

    static func == (lhs: ImageLoadHandler, rhs: ImageLoadHandler) -> Bool {
        return lhs === rhs
    }
}


@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
extension ImageLoadHandler: Hashable {

    func hash(into hasher: inout Hasher) {
        let pointer = Unmanaged.passUnretained(self).toOpaque()
        hasher.combine(pointer)
    }
}
