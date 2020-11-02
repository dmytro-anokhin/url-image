//
//  TransientImage.swift
//  
//
//  Created by Dmytro Anokhin on 30/09/2020.
//

import SwiftUI
import ImageIO

#if canImport(ImageDecoder)
import ImageDecoder
#endif


/// Temporary representation used after decoding an image from data or file on disk and before creating an `Image` object.
public protocol TransientImageType {

    var image: Image { get }
}


@available(macOS 10.15, iOS 13.0, tvOS 13.0, *)
public struct TransientImage: TransientImageType {

    public init?(data: Data, maxPixelSize: CGSize?) {
        let decoder = ImageDecoder()
        decoder.setData(data, allDataReceived: true)

        self.init(decoder: decoder, maxPixelSize: maxPixelSize)
    }

    public init?(location: URL, maxPixelSize: CGSize?) {
        guard let decoder = ImageDecoder(url: location) else {
            return nil
        }

        self.init(decoder: decoder, maxPixelSize: maxPixelSize)
    }

    public init?(decoder: ImageDecoder, maxPixelSize: CGSize?) {
        guard let uti = decoder.uti else {
            // Not an image data
            return nil
        }

        let decodedCGImage: CGImage?

        if let size = maxPixelSize {
            let decodingOptions = ImageDecoder.DecodingOptions(mode: .asynchronous, sizeForDrawing: size)
            decodedCGImage = decoder.createFrameImage(at: 0, decodingOptions: decodingOptions)
        } else {
            decodedCGImage = decoder.createFrameImage(at: 0)
        }

        guard let cgImage = decodedCGImage else {
            // Can not decode image
            return nil
        }

        self.cgImage = cgImage
        self.cgOrientation = decoder.frameOrientation(at: 0)
        self.uti = uti
        self.maxPixelSize = maxPixelSize
    }

    public var cgImage: CGImage

    public var cgOrientation: CGImagePropertyOrientation?

    public var uti: String

    public var maxPixelSize: CGSize?
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
