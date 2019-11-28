//
//  ImageLoaderView.swift
//  
//
//  Created by Dmytro Anokhin on 20/09/2019.
//

import SwiftUI


/// Loads the image using provided URLRequest while displaying the placeholder view or the content view for incremental loading
@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
struct ImageLoaderView<Content, Placeholder> : View where Content : View, Placeholder : View {

    let urlRequest: URLRequest

    let delay: TimeInterval

    let incremental: Bool

    let animated: Bool

    let expiryDate: Date?

    let processors: [ImageProcessing]?

    let placeholder: (_ downloadProgressWrapper: DownloadProgressWrapper) -> Placeholder

    let content: (_ imageProxy: ImageProxy) -> Content

    init(_ urlRequest: URLRequest, delay: TimeInterval, incremental: Bool, animated: Bool, expireAfter expiryDate: Date? = nil, processors: [ImageProcessing]?, services: Services, placeholder: @escaping (_ downloadProgressWrapper: DownloadProgressWrapper) -> Placeholder, content: @escaping (_ imageProxy: ImageProxy) -> Content) {
        self.urlRequest = urlRequest
        self.delay = delay
        self.incremental = incremental
        self.animated = animated
        self.processors = processors
        self.placeholder = placeholder
        self.expiryDate = expiryDate
        self.content = content
        self.services = services
        self.onLoad = nil
    }

    var body: some View {

        let viewModel = ImageLoaderContentView<Content, Placeholder>.Model()

        let progressCallback: ImageDownloadHandler.ProgressCallback = { progress in
            viewModel.downloadProgressWrapper.progress = progress
        }

        let partialCallback: ImageDownloadHandler.PartialCallback = { imageFrames in
            assert(!imageFrames.isEmpty)

#if canImport(UIKit)
            if imageFrames.count == 1 {
                viewModel.imageProxy = ImageWrapper(cgImage: imageFrames.first!.image)
            }
            else {
                let animatedImage = UIImage.animatedImage(
                    with: imageFrames.map { UIImage(cgImage: $0.image) },
                    duration: imageFrames.reduce(TimeInterval(0.0), { $0 + ($1.duration ?? 0.0) })
                )!

                viewModel.imageProxy = AnimatedImageWrapper(uiImage: animatedImage)
            }
#else
            viewModel.imageProxy = ImageWrapper(cgImage: imageFrames.first!.image)
#endif
        }

        let completionCallback: ImageDownloadHandler.CompletionCallback = { imageFrames in
            assert(!imageFrames.isEmpty)

#if canImport(UIKit)
            if imageFrames.count == 1 {
                let wrapper = ImageWrapper(cgImage: imageFrames.first!.image)
                self.onLoad?(wrapper)
            }
            else {
                let animatedImage = UIImage.animatedImage(
                    with: imageFrames.map { UIImage(cgImage: $0.image) },
                    duration: imageFrames.reduce(TimeInterval(0.0), { $0 + ($1.duration ?? 0.0) })
                )!

                viewModel.imageProxy = AnimatedImageWrapper(uiImage: animatedImage)
            }
#else
            let wrapper = ImageWrapper(cgImage: imageFrames.first!.image)
            self.onLoad?(wrapper)
#endif
        }

        let processor: ImageProcessing?

        if let processors = self.processors {
            processor = ImageProcessorGroup(processors: processors)
        }
        else {
            processor = nil
        }

        let handler = ImageDownloadHandler(urlRequest: urlRequest, incremental: incremental, animated: animated, displaySize: nil, processor: processor, progressCallback: progressCallback, partialCallback: partialCallback, completionCallback: completionCallback)

        return ImageLoaderContentView(model: viewModel, placeholder: placeholder, content: content)
            .onAppear {
                self.services.downloadService.add(handler, forURLRequest: self.urlRequest)
                self.services.downloadService.load(urlRequest: self.urlRequest, after: self.delay, expiryDate: self.expiryDate)
            }
            .onDisappear {
                self.services.downloadService.remove(handler, fromURLRequest: self.urlRequest)
            }
    }

    func onLoad(perform action: ((_ imageProxy: ImageProxy) -> Void)? = nil) -> ImageLoaderView<Content, Placeholder> {
        return ImageLoaderView(urlRequest, delay: delay, incremental: incremental, animated: animated, expireAfter: expiryDate, processors: processors, services: services, placeholder: placeholder, content: content, onLoad: action)
    }

    private init(_ urlRequest: URLRequest, delay: TimeInterval, incremental: Bool, animated: Bool, expireAfter expiryDate: Date? = nil, processors: [ImageProcessing]?, services: Services, placeholder: @escaping (_ downloadProgressWrapper: DownloadProgressWrapper) -> Placeholder, content: @escaping (_ imageProxy: ImageProxy) -> Content, onLoad: ((_ imageProxy: ImageProxy) -> Void)?) {
        self.urlRequest = urlRequest
        self.delay = delay
        self.incremental = incremental
        self.animated = animated
        self.processors = processors
        self.placeholder = placeholder
        self.expiryDate = expiryDate
        self.content = content
        self.services = services
        self.onLoad = onLoad
    }

    private let services: Services

    private let onLoad: ((_ imageProxy: ImageProxy) -> Void)?
}
