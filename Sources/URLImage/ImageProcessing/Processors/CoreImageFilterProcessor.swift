//
//  CoreImageFilterProcessor.swift
//  
//
//  Created by Dmytro Anokhin on 19/10/2019.
//

#if canImport(CoreImage)

import CoreImage


public struct CoreImageFilterProcessor: ImageProcessing {

    public let name: String

    public let parameters: [String: Any]

    public let context: CIContext

    public init(name: String, parameters: [String: Any] = [:], context: CIContext = CIContext()) {
        self.name = name
        self.parameters = parameters
        self.context = context
    }

    public func process(_ input: CGImage) -> CGImage {
        guard let filter = CIFilter(name: name, parameters: parameters) else {
            print("Can not create Core Image filter: '\(name)'")
            return input
        }

        let ciImage = CIImage(cgImage: input)
        filter.setValue(ciImage, forKey: kCIInputImageKey)

        guard let outputImage = filter.outputImage else {
            print("Failed to create output image with Core Image filter: '\(name)'")
            return input
        }

        let bounds = CGRect(x: 0, y: 0, width: input.width, height: input.height)
        guard let resultImage = self.context.createCGImage(outputImage, from: bounds, format: .RGBA8, colorSpace: input.colorSpace) else {
            print("Failed to render final image with Core Image filter: '\(name)'")
            return input
        }

        return resultImage
    }
}

#endif
