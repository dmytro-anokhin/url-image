//
//  Image_Orientation+CGImagePropertyOrientation.swift
//  
//
//  Created by Dmytro Anokhin on 17/09/2020.
//

import ImageIO
import SwiftUI


@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
extension Image.Orientation {

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
