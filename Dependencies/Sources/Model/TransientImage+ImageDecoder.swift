//
//  TransientImage+ImageDecoder.swift
//  
//
//  Created by Dmytro Anokhin on 11/01/2021.
//

import Foundation
import CoreGraphics
import ImageIO
import ImageDecoder
import DownloadManager


@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
public extension TransientImage {
    
    static func create(data: Data, maxPixelSize: CGSize?) async -> Self? {
        Self.init(data: data, maxPixelSize: maxPixelSize)
    }

    init?(data: Data, maxPixelSize: CGSize?) {
        let decoder = ImageDecoder()
        decoder.setData(data, allDataReceived: true)

        self.init(decoder: decoder, presentation: .data(data), maxPixelSize: maxPixelSize)
    }

    init?(location: URL, maxPixelSize: CGSize?) {
        guard let decoder = ImageDecoder(url: location) else {
            return nil
        }

        self.init(decoder: decoder, presentation: .file(location.path), maxPixelSize: maxPixelSize)
    }

    init?(decoder: ImageDecoder, presentation: DownloadResult, maxPixelSize: CGSize?) {
        guard let uti = decoder.uti else {
            // Not an image
            return nil
        }

        guard let size = decoder.frameSize(at: 0) else {
            // Can not decode an image
            return nil
        }

        let proxy = CGImageProxy(decoder: decoder, maxPixelSize: maxPixelSize)

        let info = ImageInfo(proxy: proxy, size: size)
        let cgOrientation: CGImagePropertyOrientation = decoder.frameOrientation(at: 0) ?? .up

        self.init(proxy: proxy, info: info, uti: uti, presentation: presentation, cgOrientation: cgOrientation)
    }
}
