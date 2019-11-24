//
//  ImageDecoder+UIKit.swift
//  
//
//  Created by Dmytro Anokhin on 17/11/2019.
//

import UIKit


@available(iOS 9.0, macOS 10.11, *)
extension ImageDecoder {

    public var uiImage: UIImage? {
        switch frameCount {
            case 0:
                return nil
            case 1:
                return staticUIImage
            default:
                return animatedUIImage
        }
    }

    public var animatedUIImage: UIImage? {
        guard frameCount > 1 else {
            return nil
        }

        var duration: TimeInterval = 0.0
        var images: [UIImage] = []

        for i in 0..<frameCount {
            guard let image = createFrameUIImage(at: i) else {
                continue
            }

            images.append(image)
            duration += frameDuration(at: i) ?? 0.0
        }

        return UIImage.animatedImage(with: images, duration: duration)
    }

    public var staticUIImage: UIImage? {
        frameCount > 0 ? createFrameUIImage(at: 0) : nil
    }

    private func createFrameUIImage(at index: Int, subsamplingLevel: SubsamplingLevel = .default, decodingOptions: DecodingOptions = .default) -> UIImage? {
        guard let cgImage = createFrameImage(at: index, subsamplingLevel: subsamplingLevel, decodingOptions: decodingOptions) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }
}
