//
//  TransientImage.swift
//  
//
//  Created by Dmytro Anokhin on 30/09/2020.
//

import SwiftUI
import ImageDecoder


struct TransientImage {

    static func decode(_ location: URL) throws -> TransientImage {

        guard let decoder = ImageDecoder(url: location) else {
            throw RemoteImage.Error.decode
        }

        guard let image = decoder.createFrameImage(at: 0) else {
            throw RemoteImage.Error.decode
        }

        return TransientImage(cgImage: image,
                              cgOrientation: decoder.frameOrientation(at: 0))
    }

    var cgImage: CGImage

    var cgOrientation: CGImagePropertyOrientation?
}


extension Image {

    init(transientImage: TransientImage) {
        if let cgOrientation = transientImage.cgOrientation {
            let orientation = Image.Orientation(cgOrientation)
            self.init(decorative: transientImage.cgImage, scale: 1.0, orientation: orientation)
        }
        else {
            self.init(decorative: transientImage.cgImage, scale: 1.0)
        }
    }
}
