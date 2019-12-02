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
    
    var cgImage: CGImage { get }
    
#if canImport(UIKit)
    var uiImage: UIImage { get }
#endif

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
    var nsImage: NSImage { get }
#endif

    var image: Image { get }

    var isAnimated: Bool { get }
}


@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
struct ImageWrapper: ImageProxy {

    init(cgImage: CGImage) {
        self.cgImage = cgImage
    }

    let cgImage: CGImage

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

    var isAnimated: Bool {
        return false
    }
}


#if canImport(UIKit)

@available(iOS 13.0, tvOS 13.0, watchOS 6.0, *)
struct AnimatedImageWrapper: ImageProxy {

    init(uiImage: UIImage) {
        self.uiImage = uiImage
    }

    var cgImage: CGImage {
        uiImage.cgImage!
    }

    let uiImage: UIImage

    var image: Image {
        return Image(uiImage: uiImage)
    }

    var isAnimated: Bool {
        return true
    }
}

#endif
