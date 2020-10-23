//
//  TransientImage.swift
//  
//
//  Created by Dmytro Anokhin on 30/09/2020.
//

import SwiftUI
import ImageDecoder


/// Temporary representation used after decoding an image from data or file on disk and before creating an `Image` object.
public protocol TransientImageType {

    var image: Image { get }
}


public struct TransientImage: TransientImageType {

    static func decode(_ location: URL) throws -> TransientImage {

        guard let decoder = ImageDecoder(url: location) else {
            throw URLImageError.decode
        }

        guard let uti = decoder.uti else {
            // Not an image data
            throw URLImageError.decode
        }

        guard let image = decoder.createFrameImage(at: 0) else {
            throw URLImageError.decode
        }

        return TransientImage(cgImage: image,
                              cgOrientation: decoder.frameOrientation(at: 0),
                              uti: uti)
    }

    public var cgImage: CGImage

    public var cgOrientation: CGImagePropertyOrientation?

    public var uti: String
}


public extension TransientImageType where Self == TransientImage {

    var image: Image {
        if let cgOrientation = self.cgOrientation {
            let orientation = Image.Orientation(cgOrientation)
            return Image(decorative: self.cgImage, scale: 1.0, orientation: orientation)
        }
        else {
            return Image(decorative: self.cgImage, scale: 1.0)
        }
    }
}
