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

    public var cgImage: CGImage {
        proxy.cgImage
    }

    public let info: ImageInfo

    /// The uniform type identifier (UTI) of the source image.
    ///
    /// See [Uniform Type Identifier Concepts](https://developer.apple.com/library/archive/documentation/FileManagement/Conceptual/understanding_utis/understand_utis_conc/understand_utis_conc.html#//apple_ref/doc/uid/TP40001319-CH202) for a list of system-declared and third-party UTIs.
    public let uti: String

    public let cgOrientation: CGImagePropertyOrientation

    init(proxy: CGImageProxy, info: ImageInfo, uti: String, cgOrientation: CGImagePropertyOrientation) {
        self.proxy = proxy
        self.info = info
        self.uti = uti
        self.cgOrientation = cgOrientation
    }

    private let proxy: CGImageProxy
}


/// Proxy used to decode image lazily
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
final class CGImageProxy {

    let decoder: ImageDecoder

    let maxPixelSize: CGSize?

    init(decoder: ImageDecoder, maxPixelSize: CGSize?) {
        self.decoder = decoder
        self.maxPixelSize = maxPixelSize
    }

    var cgImage: CGImage {
        if decodedCGImage == nil {
            decodeImage()
        }

        return decodedCGImage!
    }

    private var decodedCGImage: CGImage?

    private func decodeImage() {
        if let sizeForDrawing = maxPixelSize {
            let decodingOptions = ImageDecoder.DecodingOptions(mode: .asynchronous, sizeForDrawing: sizeForDrawing)
            decodedCGImage = decoder.createFrameImage(at: 0, decodingOptions: decodingOptions)!
        } else {
            decodedCGImage = decoder.createFrameImage(at: 0)!
        }
    }
}
