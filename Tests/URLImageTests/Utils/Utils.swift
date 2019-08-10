//
//  Utils.swift
//  URLImageTests
//
//  Created by Dmytro Anokhin on 01/08/2019.
//  Copyright © 2019 Dmytro Anokhin. All rights reserved.
//

import Foundation
import CoreGraphics
import ImageIO
import MobileCoreServices


@available(iOS 13.0, tvOS 13.0, *)
fileprivate extension CGContext {

    /// Bitmap context with specific pixel `width` x `height` and sRGB color space
    static func makeSRGBContext(width: Int, height: Int) -> CGContext? {
        guard let space = CGColorSpace(name: CGColorSpace.sRGB) else {
            return nil
        }

        let bitsPerComponent = 8
        let bytesPerRow = width * 4

        return CGContext(data: nil, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
    }

    /// Flips the context coordinate system by y axis
    func flip() {
        scaleBy(x: 1.0, y: -1.0)
        translateBy(x: 0.0, y: -1.0 * CGFloat(height))
    }
}


extension CGImage {

    enum WriteError: Error {

        /// Error with the destination for an image. The directory do not exist or no write permissions granted.
        case destination

        /// Failed to write the data.
        case write
    }

    func write(to url: URL) throws {
        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, kUTTypePNG, 1, nil) else {
            throw WriteError.destination
        }

        CGImageDestinationAddImage(destination, self, nil)

        guard CGImageDestinationFinalize(destination) else {
            throw WriteError.write
        }
    }
}


/// RGBA pixel
typealias Pixel = (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat)


@available(iOS 13.0, tvOS 13.0, *)
extension CGImage {

    static func draw(pixels: [[Pixel]]) -> CGImage? {

        let width = pixels.reduce(0) { max($0, $1.count) }
        let height = pixels.count

        guard let context = CGContext.makeSRGBContext(width: width, height: height) else {
            return nil
        }

        context.flip()

        for (y, row) in pixels.enumerated() {
            for (x, pixel) in row.enumerated() {
                let frame = CGRect(x: x, y: y, width: 1, height: 1)
                let color = CGColor(srgbRed: pixel.r, green: pixel.g, blue: pixel.b, alpha: pixel.a)
                context.setFillColor(color)
                context.fill(frame)
            }
        }

        return context.makeImage()
    }
}
