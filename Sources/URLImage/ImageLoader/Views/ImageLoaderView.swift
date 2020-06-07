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

    struct Properties {

        let urlRequest: URLRequest

        let fileIdentifier: String

        let delay: TimeInterval

        let incremental: Bool

        let animated: Bool

        let expiryDate: Date?

        let processors: [ImageProcessing]?

        var imageDownloadHandlerProperties: ImageDownloadHandler.Properties {
            let processor: ImageProcessing?

            if let processors = processors {
                processor = ImageProcessorGroup(processors: processors)
            }
            else {
                processor = nil
            }

            return ImageDownloadHandler.Properties(urlRequest: urlRequest, incremental: incremental, animated: animated, displaySize: nil, processor: processor)
        }
    }

    let properties: Properties

    let placeholder: (_ downloadProgressWrapper: DownloadProgressWrapper) -> Placeholder

    let content: (_ imageProxy: ImageProxy) -> Content

    init(properties: Properties, services: Services, placeholder: @escaping (_ downloadProgressWrapper: DownloadProgressWrapper) -> Placeholder, content: @escaping (_ imageProxy: ImageProxy) -> Content) {
        self.properties = properties
        self.placeholder = placeholder
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
                viewModel.imageProxy = ImageWrapper(cgImage: imageFrames.first!.image, cgOrientation: imageFrames.first!.orientation)
            }
            else {
                let animatedImage = UIImage.animatedImage(
                    with: imageFrames.map { UIImage(cgImage: $0.image) },
                    duration: imageFrames.reduce(TimeInterval(0.0), { $0 + ($1.duration ?? 0.0) })
                )!

                viewModel.imageProxy = AnimatedImageWrapper(uiImage: animatedImage)
            }
#else
            viewModel.imageProxy = ImageWrapper(cgImage: imageFrames.first!.image, cgOrientation: imageFrames.first!.orientation)
#endif
        }

        let completionCallback: ImageDownloadHandler.CompletionCallback = { result in
            switch result {
                case .success(let imageFrames):
                    assert(!imageFrames.isEmpty)

                    #if canImport(UIKit)
                        if imageFrames.count == 1 {
                            let wrapper = ImageWrapper(cgImage: imageFrames.first!.image, cgOrientation: imageFrames.first!.orientation)
                            self.onLoad?(.success(wrapper))
                        }
                        else {
                            let animatedImage = UIImage.animatedImage(
                                with: imageFrames.map { UIImage(cgImage: $0.image) },
                                duration: imageFrames.reduce(TimeInterval(0.0), { $0 + ($1.duration ?? 0.0) })
                            )!

                            viewModel.imageProxy = AnimatedImageWrapper(uiImage: animatedImage)
                        }
                    #else
                        let wrapper = ImageWrapper(cgImage: imageFrames.first!.image, cgOrientation: imageFrames.first!.orientation)
                        self.onLoad?(.success(wrapper))
                    #endif

                case .failure(let error):
                    self.onLoad?(.failure(error))

            }
        }

        let handler = ImageDownloadHandler(properties: properties.imageDownloadHandlerProperties, progressCallback: progressCallback, partialCallback: partialCallback, completionCallback: completionCallback)

        return ImageLoaderContentView(model: viewModel, placeholder: placeholder, content: content)
            .onAppear {
                self.services.downloadService.add(handler, forURLRequest: self.properties.urlRequest, withFileIdentifier: self.properties.fileIdentifier)
                self.services.downloadService.load(urlRequest: self.properties.urlRequest, withFileIdentifier: self.properties.fileIdentifier, after: self.properties.delay, expiryDate: self.properties.expiryDate)
            }
            .onDisappear {
                self.services.downloadService.remove(handler, fromURLRequest: self.properties.urlRequest, withFileIdentifier: self.properties.fileIdentifier)
            }
    }

    func onLoad(perform action: OnLoadClosure? = nil) -> ImageLoaderView<Content, Placeholder> {
        return ImageLoaderView(properties: properties, services: services, placeholder: placeholder, content: content, onLoad: action)
    }

    private init(properties: Properties, services: Services, placeholder: @escaping (_ downloadProgressWrapper: DownloadProgressWrapper) -> Placeholder, content: @escaping (_ imageProxy: ImageProxy) -> Content, onLoad: OnLoadClosure?) {
        self.properties = properties
        self.placeholder = placeholder
        self.content = content
        self.services = services
        self.onLoad = onLoad
    }

    private let services: Services

    typealias OnLoadClosure = (_ result: Result<ImageProxy, Error>) -> Void

    private let onLoad: OnLoadClosure?
}
