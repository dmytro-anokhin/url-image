//
//  ImageLoadHandler.swift
//  
//
//  Created by Dmytro Anokhin on 15/10/2019.
//

import CoreGraphics


final class ImageLoadHandler {

    let processor: ImageProcessing?

    let observer: ImageLoaderObserver

    init(processor: ImageProcessing?, observer: ImageLoaderObserver) {
        self.processor = processor
        self.observer = observer
    }
}


extension ImageLoadHandler: Equatable {

    static func == (lhs: ImageLoadHandler, rhs: ImageLoadHandler) -> Bool {
        return lhs === rhs
    }
}


extension ImageLoadHandler: Hashable {

    func hash(into hasher: inout Hasher) {
        let pointer = Unmanaged.passUnretained(self).toOpaque()
        hasher.combine(pointer)
    }
}
