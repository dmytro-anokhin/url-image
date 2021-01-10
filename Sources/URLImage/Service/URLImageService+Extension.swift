//
//  URLImageService+Extension.swift
//  
//
//  Created by Dmytro Anokhin on 30/11/2020.
//

import CoreGraphics


@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension URLImageService {

    static var suggestedMaxPixelSize: CGSize? {
        #if os(watchOS)
            return CGSize(width: 300.0, height: 300.0)
        #else
            return CGSize(width: 1000.0, height: 1000.0)
        #endif
    }
}
