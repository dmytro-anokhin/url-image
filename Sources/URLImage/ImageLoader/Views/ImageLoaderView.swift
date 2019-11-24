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

    let expiryDate: Date?

    let processors: [ImageProcessing]?

    let placeholder: (_ downloadProgressWrapper: DownloadProgressWrapper) -> Placeholder

    let content: (_ imageProxy: ImageProxy) -> Content

    init(_ urlRequest: URLRequest, delay: TimeInterval, incremental: Bool, expireAfter expiryDate: Date? = nil, processors: [ImageProcessing]?, services: Services, placeholder: @escaping (_ downloadProgressWrapper: DownloadProgressWrapper) -> Placeholder, content: @escaping (_ imageProxy: ImageProxy) -> Content) {
        self.urlRequest = urlRequest
        self.delay = delay
        self.incremental = incremental
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

        let partialCallback: ImageDownloadHandler.PartialCallback = { image in
            viewModel.imageProxy = ImageWrapper(cgImage: image)
        }

        let completionCallback: ImageDownloadHandler.CompletionCallback = { image in
            self.onLoad?(ImageWrapper(cgImage: image))
        }

        let processor: ImageProcessing?

        if let processors = self.processors {
            processor = ImageProcessorGroup(processors: processors)
        }
        else {
            processor = nil
        }

        let handler = ImageDownloadHandler(incremental: incremental, processor: processor, imageProcessingService: services.imageProcessingService, progressCallback: progressCallback, partialCallback: partialCallback, completionCallback: completionCallback)

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
        return ImageLoaderView(urlRequest, delay: delay, incremental: incremental, expireAfter: expiryDate, processors: processors, services: services, placeholder: placeholder, content: content, onLoad: action)
    }

    private init(_ urlRequest: URLRequest, delay: TimeInterval, incremental: Bool, expireAfter expiryDate: Date? = nil, processors: [ImageProcessing]?, services: Services, placeholder: @escaping (_ downloadProgressWrapper: DownloadProgressWrapper) -> Placeholder, content: @escaping (_ imageProxy: ImageProxy) -> Content, onLoad: ((_ imageProxy: ImageProxy) -> Void)?) {
        self.urlRequest = urlRequest
        self.delay = delay
        self.incremental = incremental
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
