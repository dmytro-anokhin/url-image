//
//  ImageProcessing.swift
//  
//
//  Created by Dmytro Anokhin on 15/10/2019.
//

import CoreGraphics


public protocol ImageProcessing {

    func process(_ input: CGImage) -> CGImage
}


public struct ImageProcessingClosure: ImageProcessing {

    public var closure: (_ input: CGImage) -> CGImage

    public init(closure: @escaping (_ input: CGImage) -> CGImage) {
        self.closure = closure
    }

    public func process(_ input: CGImage) -> CGImage {
        return closure(input)
    }
}
