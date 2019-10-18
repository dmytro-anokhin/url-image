//
//  CGImage+Extensions.swift
//  
//
//  Created by Dmytro Anokhin on 18/10/2019.
//

import CoreGraphics


extension CGImage {

    /// Resize image.
    ///
    /// Resizes the image scaling it to fill the target size.
    ///
    /// - Parameters:
    ///     - targetSize: New size in pixels.
    ///
    func resized(to targetSize: CGSize) -> CGImage? {
        let context = CGContext.makeContext(image: self, size: targetSize)

        let imageSize = CGSize(width: CGFloat(width), height: CGFloat(height))

        /// Multiplier for the result image size. Largest ratio of the target to the image width or height.
        let scaleMultiplier = max(
            targetSize.width / imageSize.width,
            targetSize.height / imageSize.height
        )

        /// The new size is larger or equal to the target size.
        let newSize = CGSize(
            width: imageSize.width * scaleMultiplier,
            height: imageSize.height * scaleMultiplier
        )

        /// The new origin is offset to clip sides.
        let newOrigin = CGPoint(
            x: (targetSize.width - newSize.width) * 0.5,
            y: (targetSize.height - newSize.height) * 0.5
        )

        let newRect = CGRect(origin: newOrigin, size: newSize)

        context?.draw(self, in: newRect)

        return context?.makeImage()
    }
}
