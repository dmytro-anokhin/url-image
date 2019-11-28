//
//  ImageDownloadHandler.swift
//  
//
//  Created by Dmytro Anokhin on 22/11/2019.
//

import Foundation
import CoreGraphics


typealias ImageFrame = (image: CGImage, duration: TimeInterval?)


@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
class ImageDownloadHandler: DownloadHandler {

    typealias ProgressCallback = (_ progress: Float?) -> Void

    typealias PartialCallback = (_ imageFrames: [ImageFrame]) -> Void

    typealias CompletionCallback = (_ imageFrames: [ImageFrame]) -> Void

    let progressCallback: ProgressCallback

    let partialCallback: PartialCallback

    let completionCallback: CompletionCallback

    let urlRequest: URLRequest

    let incremental: Bool

    let animated: Bool

    let displaySize: CGSize?

    let processor: ImageProcessing?

    init(urlRequest: URLRequest, incremental: Bool, animated: Bool, displaySize: CGSize?, processor: ImageProcessing? = nil, progressCallback: @escaping ProgressCallback, partialCallback: @escaping PartialCallback, completionCallback: @escaping CompletionCallback) {
        self.urlRequest = urlRequest
        self.incremental = incremental
        self.animated = animated
        self.displaySize = displaySize
        self.processor = processor
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
        queue.async {
            self._handleDownloadPartial(data)
        }
    }

    private func _handleDownloadPartial(_ data: Data) {
        if decoder == nil {
            decoder = ImageDecoder()
        }

        decoder!.setData(data, allDataReceived: false)

        if animated {
            guard let imageFrames = makeImageFrames(), !imageFrames.isEmpty else {
                return
            }

            DispatchQueue.main.async {
                self.partialCallback(imageFrames)
            }
        }
        else {
            guard var cgImage = makeCGImage() else {
                return
            }

            if let processor = processor {
                cgImage = processor.process(cgImage)
            }

            DispatchQueue.main.async {
                self.partialCallback([(cgImage, nil)])
            }
        }
    }

    override func handleDownloadCompletion(_ data: Data?, _ fileURL: URL) {
        queue.async {
            self._handleDownloadCompletion(data, fileURL)
        }
    }

    private func _handleDownloadCompletion(_ data: Data?, _ fileURL: URL) {
        if let data = data {
            log_debug(self, "Handle completion for url: \"\(urlRequest.url!)\" with byte count: \(data.count), and local file: \"\(fileURL)\"", detail: log_detailed)
        }
        else {
            log_debug(self, "Handle completion for url: \"\(urlRequest.url!)\", local file: \"\(fileURL)\"", detail: log_detailed)
        }
    
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

        if animated {
            guard let imageFrames = makeImageFrames(), !imageFrames.isEmpty else {
                return
            }

            DispatchQueue.main.async {
                self.completionCallback(imageFrames)
            }
        }
        else {
            guard var cgImage = makeCGImage() else {
                return
            }

            if let processor = processor {
                cgImage = processor.process(cgImage)
            }

            DispatchQueue.main.async {
                self.completionCallback([(cgImage, nil)])
            }
        }
    }

    private let queue = DispatchQueue(label: "URLImage.ImageDownloadHandler.queue")

    // The decoder is created when first partial data received.
    // If the decoder wasn't' created before the completion handler was called we must load data from the local file.
    private var decoder: ImageDecoder?

    private var decodingOptions: ImageDecoder.DecodingOptions {
        ImageDecoder.DecodingOptions(mode: .synchronous, sizeForDrawing: displaySize)
    }

    private func makeCGImage() -> CGImage? {
        guard let decoder = decoder else {
            return nil
        }

        guard decoder.frameCount > 0 else {
            log_debug(self, "No frames to decode for \"\(urlRequest.url!)\"", detail: log_detailed)
            return nil
        }

        guard let cgImage = decoder.createFrameImage(at: 0, decodingOptions: decodingOptions) else {
            log_debug(self, "Failed to create frame for \"\(urlRequest.url!)\"", detail: log_detailed)
            return nil
        }

        log_debug(self, "Decoded frame for \"\(urlRequest.url!)\"", detail: log_detailed)

        return cgImage
    }

    private func makeImageFrames() -> [ImageFrame]? {
        guard let decoder = decoder else {
            return nil
        }

        let frameCount = decoder.frameCount

        guard frameCount > 0 else {
            log_debug(self, "No frames to decode for \"\(urlRequest.url!)\"", detail: log_detailed)
            return nil
        }

        var imageFrames: [ImageFrame] = []

        for i in 0..<frameCount {
            guard let cgImage = decoder.createFrameImage(at: i, decodingOptions: decodingOptions),
                let duration = decoder.frameDuration(at: i) else {
                log_debug(self, "Failed to create frame at \(i) for \"\(urlRequest.url!)\"", detail: log_detailed)
                continue
            }

            imageFrames.append((cgImage, duration))
        }

        return imageFrames
    }
}
