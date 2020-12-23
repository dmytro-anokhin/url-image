//
//  ImageInfo.swift
//  
//
//  Created by Dmytro Anokhin on 23/12/2020.
//

import CoreGraphics


public struct ImageInfo {

    /// Decoded image
    public var cgImage: CGImage

    /// Image size in pixels.
    ///
    /// This is the real size, that can be different from decoded image size.
    public var size: CGSize
}
