//
//  ImageProcessorGroup.swift
//  
//
//  Created by Dmytro Anokhin on 19/10/2019.
//

import CoreGraphics


public struct ImageProcessorGroup: ImageProcessing {

    public let processors: [ImageProcessing]

    public init(processors: [ImageProcessing]) {
        self.processors = processors
    }

    public func process(_ input: CGImage) -> CGImage {
        var resultImage = input

        for processor in processors {
            resultImage = processor.process(resultImage)
        }

        return resultImage
    }
}
