//
//  ImageWrapper.swift
//  
//
//  Created by Dmytro Anokhin on 18/09/2019.
//

import SwiftUI
import Combine
import ImageIO


#if canImport(UIKit)
import UIKit
#endif


public protocol ImageProxy {

#if canImport(UIKit)
    var uiImage: UIImage { get }
#endif

    var image: Image { get }
}


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

    private init(cgImage: CGImage) {
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
}


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

    /// Accumulates data
    private var data = Data()

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
}
