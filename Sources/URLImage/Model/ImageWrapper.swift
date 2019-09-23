//
//  ImageWrapper.swift
//  
//
//  Created by Dmytro Anokhin on 18/09/2019.
//

import SwiftUI
import Combine


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
