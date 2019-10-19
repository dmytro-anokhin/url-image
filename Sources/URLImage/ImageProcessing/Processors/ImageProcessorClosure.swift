//
//  ImageProcessorClosure.swift
//  
//
//  Created by Dmytro Anokhin on 19/10/2019.
//

import CoreGraphics


public struct ImageProcessorClosure: ImageProcessing {

    public let closure: (_ input: CGImage) -> CGImage

    public init(closure: @escaping (_ input: CGImage) -> CGImage) {
        self.closure = closure
    }

    public func process(_ input: CGImage) -> CGImage {
        return closure(input)
    }
}
