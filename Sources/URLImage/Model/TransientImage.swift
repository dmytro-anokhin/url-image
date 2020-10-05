//
//  TransientImage.swift
//  
//
//  Created by Dmytro Anokhin on 30/09/2020.
//

import SwiftUI
import ImageDecoder


public struct TransientImage {

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


public extension TransientImage {

    var image: Image {
        if let cgOrientation = cgOrientation {
            let orientation = Image.Orientation(cgOrientation)
            return Image(decorative: cgImage, scale: 1.0, orientation: orientation)
        }
        else {
            return Image(decorative: cgImage, scale: 1.0)
        }
    }
}
