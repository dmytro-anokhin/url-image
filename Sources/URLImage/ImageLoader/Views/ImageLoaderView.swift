//
//  ImageLoaderView.swift
//  
//
//  Created by Dmytro Anokhin on 20/09/2019.
//

import SwiftUI


/// Loads the image at URL while displaying the placeholder view or the content view for incremental loading
@available(iOS 13.0, tvOS 13.0, macOS 10.15, *)
struct ImageLoaderView<Content, Placeholder> : View where Content : View, Placeholder : View {

    let url: URL

    let delay: TimeInterval

    let incremental: Bool

    let expiryDate: Date?

    let processor: ImageProcessing?

    let placeholder: (_ downloadProgressWrapper: DownloadProgressWrapper) -> Placeholder

    let content: (_ imageProxy: ImageProxy) -> Content

    init(_ url: URL, delay: TimeInterval, incremental: Bool, expireAfter expiryDate: Date? = nil, processor: ImageProcessing?, services: Services, placeholder: @escaping (_ downloadProgressWrapper: DownloadProgressWrapper) -> Placeholder, content: @escaping (_ imageProxy: ImageProxy) -> Content) {
        self.url = url
        self.delay = delay
        self.incremental = incremental
        self.processor = processor
        self.placeholder = placeholder
        self.expiryDate = expiryDate
        self.content = content
        self.services = services
        self.onLoad = nil
    }

    var body: some View {

        let viewModel = ImageLoaderContentView<Content, Placeholder>.Model()

        let observer = ImageLoaderObserver(
            progress: { progress in
                viewModel.downloadProgressWrapper.progress = progress
            },
            partial: { imageProxy in
                viewModel.imageProxy = imageProxy
            },
            completion: { imageProxy in
                self.onLoad?(imageProxy)
            })

        return ImageLoaderContentView(model: viewModel, placeholder: placeholder, content: content)
            .onAppear {
                self.services.imageLoaderService.subscribe(forURL: self.url, incremental: self.incremental, processor: self.processor, observer)
                self.services.imageLoaderService.load(url: self.url, delay: self.delay, expiryDate: self.expiryDate)
            }
            .onDisappear {
                self.services.imageLoaderService.unsubscribe(observer, fromURL: self.url)
            }
    }

    func onLoad(perform action: ((_ imageProxy: ImageProxy) -> Void)? = nil) -> ImageLoaderView<Content, Placeholder> {
        return ImageLoaderView(url, delay: delay, incremental: incremental, expireAfter: expiryDate, processor: processor, services: services, placeholder: placeholder, content: content, onLoad: action)
    }

    private init(_ url: URL, delay: TimeInterval, incremental: Bool, expireAfter expiryDate: Date? = nil, processor: ImageProcessing?, services: Services, placeholder: @escaping (_ downloadProgressWrapper: DownloadProgressWrapper) -> Placeholder, content: @escaping (_ imageProxy: ImageProxy) -> Content, onLoad: ((_ imageProxy: ImageProxy) -> Void)?) {
        self.url = url
        self.delay = delay
        self.incremental = incremental
        self.processor = processor
        self.placeholder = placeholder
        self.expiryDate = expiryDate
        self.content = content
        self.services = services
        self.onLoad = onLoad
    }

    private let services: Services

    private let onLoad: ((_ imageProxy: ImageProxy) -> Void)?
}