//
//  ImageDownloadHandler.swift
//  
//
//  Created by Dmytro Anokhin on 22/11/2019.
//

import Foundation
import CoreGraphics


@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
class ImageDownloadHandler: DownloadHandler {

    typealias ProgressCallback = (_ progress: Float?) -> Void

    typealias PartialCallback = (_ image: CGImage) -> Void

    typealias CompletionCallback = (_ image: CGImage) -> Void

    let progressCallback: ProgressCallback

    let partialCallback: PartialCallback

    let completionCallback: CompletionCallback

    let incremental: Bool

    let displaySize: CGSize?

    let processor: ImageProcessing?

    unowned let imageProcessingService: ImageProcessingService

    init(incremental: Bool, displaySize: CGSize?, processor: ImageProcessing? = nil, imageProcessingService: ImageProcessingService, progressCallback: @escaping ProgressCallback, partialCallback: @escaping PartialCallback, completionCallback: @escaping CompletionCallback) {
        self.incremental = incremental
        self.displaySize = displaySize
        self.processor = processor
        self.imageProcessingService = imageProcessingService
        self.progressCallback = progressCallback
        self.partialCallback = partialCallback
        self.completionCallback = completionCallback
    }

    override func handleDownloadProgress(_ progress: Float?) {
        DispatchQueue.main.async {
            self.progressCallback(progress)
        }
    }

    override var inMemory: Bool { incremental }

    override func handleDownloadPartial(_ data: Data) {
        if decoder == nil {
            decoder = ImageDecoder()
        }

        decoder!.setData(data, allDataReceived: false)

        let decodingOptions = ImageDecoder.DecodingOptions(mode: .asynchronous, sizeForDrawing: displaySize)

        guard decoder!.frameCount > 0, let cgImage = decoder!.createFrameImage(at: 0, decodingOptions: decodingOptions) else {
            return
        }

        if let processor = processor {
            imageProcessingService.processImage(cgImage, usingProcessor: processor) { resultImage in
                DispatchQueue.main.async {
                    self.partialCallback(resultImage)
                }
            }
        }
        else {
            DispatchQueue.main.async {
                self.partialCallback(cgImage)
            }
        }
    }

    override func handleDownloadCompletion(_ data: Data?, _ fileURL: URL) {
        if decoder == nil {
            guard let dataProvider = CGDataProvider(url: fileURL as CFURL) else {
                return
            }

            decoder = ImageDecoder()
            decoder!.setDataProvider(dataProvider, allDataReceived: true)
        }
        else {
            if let data = data {
                decoder!.setData(data, allDataReceived: true)
            }
        }

        let decodingOptions = ImageDecoder.DecodingOptions(mode: .asynchronous, sizeForDrawing: displaySize)

        guard decoder!.frameCount > 0, let cgImage = decoder!.createFrameImage(at: 0, decodingOptions: decodingOptions) else {
            return
        }

        if let processor = processor {
            imageProcessingService.processImage(cgImage, usingProcessor: processor) { resultImage in
                DispatchQueue.main.async {
                    self.completionCallback(resultImage)
                }
            }
        }
        else {
            DispatchQueue.main.async {
                self.completionCallback(cgImage)
            }
        }
    }

    // The decoder is created when first partial data received.
    // If the decoder wasn't' created before the completion handler was called we must load data from the local file.
    private var decoder: ImageDecoder?
}
