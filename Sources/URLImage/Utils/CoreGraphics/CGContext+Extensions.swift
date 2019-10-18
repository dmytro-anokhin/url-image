//
//  CGContext+Extensions.swift
//  
//
//  Created by Dmytro Anokhin on 18/10/2019.
//

import CoreGraphics


extension CGContext {

    static func makeContext(image: CGImage, size: CGSize? = nil) -> CGContext? {
        guard let colorSpace = image.colorSpace else {
            return nil
        }

        let contextSize = size ?? CGSize(width: image.width, height: image.height)

        return CGContext(data: nil, width: Int(contextSize.width), height: Int(contextSize.height), bitsPerComponent: image.bitsPerComponent, bytesPerRow: 0, space: colorSpace, bitmapInfo: image.bitmapInfo.rawValue)
    }
}
