//
//  ImageWrapper.swift
//  
//
//  Created by Dmytro Anokhin on 18/09/2019.
//

import SwiftUI


#if canImport(UIKit)

import UIKit

extension ImageWrapper {

    var image: Image {
        return Image(uiImage: UIImage(cgImage: cgImage))
    }
}

#elseif canImport(AppKit)

import AppKit

extension ImageWrapper {

    var image: Image {
        fatalError("Not implemented")
    }
}

#endif


final class ImageWrapper {

    convenience init?(fileURL: URL) {
        guard let cgImage = createCGImage(fileURL: fileURL) else {
            return nil
        }

        self.init(cgImage: cgImage)
    }

    private init(cgImage: CGImage) {
        self.cgImage = cgImage
    }

    private let cgImage: CGImage
}
