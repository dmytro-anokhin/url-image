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

    var cgOrientation: CGImagePropertyOrientation? { get }
    
#if canImport(UIKit)
    var uiImage: UIImage { get }
#endif

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
    var nsImage: NSImage { get }
#endif

    var isAnimated: Bool { get }
}


#if canImport(UIKit)
@available(iOS 13.0, tvOS 13.0, watchOS 6.0, *)
@available(macOS, unavailable)
public extension ImageProxy {

    var image: Image {
        guard let cgOrientation = cgOrientation else {
            return Image(uiImage: uiImage)
        }

        return Image(decorative: cgImage, scale: 1.0, orientation: Image.Orientation(cgOrientation))
    }
}
#endif


#if canImport(AppKit) && !targetEnvironment(macCatalyst)
@available(macOS 10.15, *)
@available(iOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public extension ImageProxy {

    var image: Image {
        return Image(nsImage: nsImage)
    }
}
#endif


@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
struct ImageWrapper: ImageProxy {

    init(cgImage: CGImage, cgOrientation: CGImagePropertyOrientation?) {
        self.cgImage = cgImage
        self.cgOrientation = cgOrientation
    }

    let cgImage: CGImage

    let cgOrientation: CGImagePropertyOrientation?

    #if canImport(UIKit)

    var uiImage: UIImage {
        return UIImage(cgImage: cgImage)
    }

    #endif

    #if canImport(AppKit) && !targetEnvironment(macCatalyst)

    var nsImage: NSImage {
        return NSImage(cgImage: cgImage, size: NSZeroSize)
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

    var cgOrientation: CGImagePropertyOrientation? { nil }

    let uiImage: UIImage

    var isAnimated: Bool {
        return true
    }
}

#endif


@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
fileprivate extension Image.Orientation {

    init(_ cgOrientation: CGImagePropertyOrientation) {
        switch cgOrientation {
            case .up: self = .up
            case .upMirrored: self = .upMirrored
            case .down: self = .down
            case .downMirrored: self = .downMirrored
            case .left: self = .left
            case .leftMirrored: self = .leftMirrored
            case .right: self = .right
            case .rightMirrored: self = .rightMirrored
        }
    }
}
