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

    let closure: ImageLoaderCompletion

    init(closure: @escaping ImageLoaderCompletion) {
        self.closure = closure
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
