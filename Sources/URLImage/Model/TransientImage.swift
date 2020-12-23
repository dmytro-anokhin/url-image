//
//  TransientImage.swift
//  
//
//  Created by Dmytro Anokhin on 30/09/2020.
//

import ImageIO
import SwiftUI

#if canImport(ImageDecoder)
import ImageDecoder
#endif


/// Temporary representation used after decoding an image from data or file on disk and before creating an `Image` object.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public protocol TransientImageType {

    var image: Image { get }

    var info: ImageInfo { get }
}


@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
struct TransientImage: TransientImageType {

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
        guard decoder.uti != nil else {
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

        self.decoder = decoder
        self.cgImage = cgImage
    }

    var image: Image {
        if let cgOrientation = self.cgOrientation {
            let orientation = Image.Orientation(cgOrientation)
            return Image(decorative: self.cgImage, scale: 1.0, orientation: orientation)
        }
        else {
            return Image(decorative: self.cgImage, scale: 1.0)
        }
    }

    var info: ImageInfo {
        ImageInfo(cgImage: cgImage, size: decoder.frameSize(at: 0) ?? .zero)
    }

    /// The uniform type identifier (UTI) of the source image.
    ///
    /// See [Uniform Type Identifier Concepts](https://developer.apple.com/library/archive/documentation/FileManagement/Conceptual/understanding_utis/understand_utis_conc/understand_utis_conc.html#//apple_ref/doc/uid/TP40001319-CH202) for a list of system-declared and third-party UTIs.
    var uti: String {
        decoder.uti!
    }

    private let decoder: ImageDecoder

    private let cgImage: CGImage

    private var cgOrientation: CGImagePropertyOrientation? {
        decoder.frameOrientation(at: 0)
    }
}
