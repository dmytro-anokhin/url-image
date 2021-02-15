//
//  TransientImage+ImageDecoder.swift
//  
//
//  Created by Dmytro Anokhin on 11/01/2021.
//

import Foundation
import CoreGraphics
import ImageIO

#if canImport(Common)
import Common
#endif

#if canImport(ImageDecoder)
import ImageDecoder
#endif


@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension TransientImage {

    init?(data: Data, maxPixelSize: CGSize?) {
        let decoder = ImageDecoder()
        decoder.setData(data, allDataReceived: true)

        self.init(decoder: decoder, maxPixelSize: maxPixelSize)
    }

    init?(location: URL, maxPixelSize: CGSize?) {
        guard let decoder = ImageDecoder(url: location) else {
            return nil
        }

        self.init(decoder: decoder, maxPixelSize: maxPixelSize)
    }

    init?(decoder: ImageDecoder, maxPixelSize: CGSize?) {
        guard let uti = decoder.uti else {
            // Not an image
            return nil
        }

        let decodedCGImage: CGImage?

        if let sizeForDrawing = maxPixelSize {
            let decodingOptions = ImageDecoder.DecodingOptions(mode: .asynchronous, sizeForDrawing: sizeForDrawing)
            decodedCGImage = decoder.createFrameImage(at: 0, decodingOptions: decodingOptions)
        } else {
            decodedCGImage = decoder.createFrameImage(at: 0)
        }

        guard let cgImage = decodedCGImage else {
            // Can not decode an image
            return nil
        }

        let info = ImageInfo(cgImage: cgImage, size: decoder.frameSize(at: 0) ?? .zero)
        let cgOrientation: CGImagePropertyOrientation = decoder.frameOrientation(at: 0) ?? .up

        self.init(cgImage: cgImage, info: info, uti: uti, cgOrientation: cgOrientation)
    }
}
