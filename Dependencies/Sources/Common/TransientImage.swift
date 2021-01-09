//
//  TransientImage.swift
//  
//
//  Created by Dmytro Anokhin on 08/01/2021.
//

import Foundation
import ImageIO

#if canImport(ImageDecoder)
import ImageDecoder
#endif


/// Temporary representation used after decoding an image from data or file on disk and before creating an image object for display.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public struct TransientImage {

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

    public var info: ImageInfo {
        ImageInfo(cgImage: cgImage, size: decoder.frameSize(at: 0) ?? .zero)
    }

    /// The uniform type identifier (UTI) of the source image.
    ///
    /// See [Uniform Type Identifier Concepts](https://developer.apple.com/library/archive/documentation/FileManagement/Conceptual/understanding_utis/understand_utis_conc/understand_utis_conc.html#//apple_ref/doc/uid/TP40001319-CH202) for a list of system-declared and third-party UTIs.
    public var uti: String {
        decoder.uti!
    }
    
    public var cgOrientation: CGImagePropertyOrientation? {
        decoder.frameOrientation(at: 0)
    }

    public let cgImage: CGImage

    private let decoder: ImageDecoder
}
