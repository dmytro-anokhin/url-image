//
//  ImageProxy.swift
//  URLImage
//
//
//  Created by Dmytro Anokhin on 18/09/2019.
//  Copyright © 2019 Dmytro Anokhin. All rights reserved.
//

import SwiftUI
import Combine
import ImageIO


#if canImport(UIKit)
import UIKit
#endif


#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
#endif


@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
public protocol ImageProxy {

#if canImport(UIKit)
    var uiImage: UIImage { get }
#endif

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
    var nsImage: NSImage { get }
#endif

    var image: Image { get }
}


@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
final class ImageWrapper: ImageProxy {

    convenience init?(fileURL: URL) {
        guard let cgImage = createCGImage(fileURL: fileURL) else {
            return nil
        }

        self.init(cgImage: cgImage)
    }

    convenience init?(data: Data) {
        guard let cgImage = createCGImage(data: data) else {
            return nil
        }

        self.init(cgImage: cgImage)
    }

    init(cgImage: CGImage) {
        self.cgImage = cgImage
    }

    private let cgImage: CGImage

    #if canImport(UIKit)

    var uiImage: UIImage {
        return UIImage(cgImage: cgImage)
    }

    var image: Image {
        return Image(uiImage: uiImage)
    }

    #endif

    #if canImport(AppKit) && !targetEnvironment(macCatalyst)

    var nsImage: NSImage {
        return NSImage(cgImage: cgImage, size: NSZeroSize)
    }

    var image: Image {
        return Image(nsImage: nsImage)
    }

    #endif

}


@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
final class IncrementalImageWrapper: ImageProxy {

    init() {
        let options = [
            kCGImageSourceShouldCache : true,
            kCGImageSourceShouldAllowFloat: true
        ]

        imageSource = CGImageSourceCreateIncremental(options as CFDictionary)
    }

    func append(_ newData: Data) {
        data.append(newData)
        CGImageSourceUpdateData(imageSource, data as CFData, false)
    }

    var isFinal = false {
        didSet {
            if isFinal {
                CGImageSourceUpdateData(imageSource, data as CFData, true)
            }
        }
    }

    var isEmpty: Bool {
        return data.isEmpty
    }

    var imageSourceType: String? {
        return CGImageSourceGetType(imageSource) as String?
    }

    /// Accumulates data
    private(set) var data = Data()

    private var imageSource: CGImageSource

    #if canImport(UIKit)

    var uiImage: UIImage {
        guard let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            return UIImage()
        }

        return UIImage(cgImage: cgImage)
    }

    var image: Image {
        return Image(uiImage: uiImage)
    }

    #endif

    #if canImport(AppKit) && !targetEnvironment(macCatalyst)

    var nsImage: NSImage {
        guard let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            return NSImage()
        }

        return NSImage(cgImage: cgImage, size: NSZeroSize)
    }

    var image: Image {
        return Image(nsImage: nsImage)
    }

    #endif
}
