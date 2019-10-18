//
//  ImageProcessingService.swift
//  
//
//  Created by Dmytro Anokhin on 15/10/2019.
//

import Foundation
import CoreGraphics


protocol ImageProcessingService: AnyObject {

    func processImage(_ image: CGImage, usingProcessor processor: ImageProcessing, completion: @escaping (_ resultImage: CGImage) -> Void)
}


final class ImageProcessingServiceImpl: ImageProcessingService {

    func processImage(_ image: CGImage, usingProcessor processor: ImageProcessing, completion: @escaping (_ resultImage: CGImage) -> Void) {
        queue.addOperation {
            let resultImage = processor.process(image)
            completion(resultImage)
        }
    }

    init() {
    }

    private let queue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "URLImage.ImageProcessingServiceImpl.queue"
        queue.maxConcurrentOperationCount = 4

        return queue
    }()
}
