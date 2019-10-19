//
//  Resize.swift
//  
//
//  Created by Dmytro Anokhin on 17/10/2019.
//

import CoreGraphics

#if canImport(UIKit)

import UIKit

public extension Resize {

    init(size: CGSize, scale: CGFloat) {
        self.size = size
        self.scale = scale
    }
}

#elseif canImport(AppKit)

import AppKit

public extension Resize {
    init(size: CGSize, scale: CGFloat = NSScreen.main?.backingScaleFactor ?? 1.0) {
        self.size = size
        self.scale = scale
    }
}

#endif


public struct Resize: ImageProcessing {

    init() {
        self.size = .zero
        self.scale = 0.0
    }

    /// New size in points
    public let size: CGSize

    /// The scale factor of the screen.
    public let scale: CGFloat

    public func process(_ input: CGImage) -> CGImage {
        let targetSize = CGSize(width: size.width * scale, height: size.height * scale)
        return input.resized(to: targetSize) ?? input
    }
}
