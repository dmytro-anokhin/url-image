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

    let placeholder: (_ partialImage: PartialImage) -> Placeholder

    let content: (_ imageProxy: ImageProxy) -> Content

    init(_ url: URL, delay: TimeInterval, incremental: Bool, imageLoaderService: ImageLoaderService, placeholder: @escaping (_ partialImage: PartialImage) -> Placeholder, content: @escaping (_ imageProxy: ImageProxy) -> Content) {
        self.url = url
        self.delay = delay
        self.incremental = incremental
        self.placeholder = placeholder
        self.content = content
        self.imageLoaderService = imageLoaderService
        self.onLoad = nil
    }

    var body: some View {

        let viewModel = ImageLoaderContentView<Content, Placeholder>.Model()

        let observer = ImageLoaderObserver(
            progress: { progress in
                viewModel.partialImage.progress = progress
            },
            partial: { imageProxy in
                viewModel.imageProxy = imageProxy
            },
            completion: { imageProxy in
                self.onLoad?(imageProxy)
            })

        return ImageLoaderContentView(model: viewModel, placeholder: placeholder, content: content)
            .onAppear {
                self.imageLoaderService.subscribe(forURL: self.url, incremental: self.incremental, observer)
                self.imageLoaderService.load(url: self.url, delay: self.delay)
            }
            .onDisappear {
                self.imageLoaderService.unsubscribe(observer, fromURL: self.url)
            }
    }

    func onLoad(perform action: ((_ imageProxy: ImageProxy) -> Void)? = nil) -> ImageLoaderView<Content, Placeholder> {
        return ImageLoaderView(url, delay: delay, incremental: incremental, imageLoaderService: imageLoaderService, placeholder: placeholder, content: content, onLoad: action)
    }

    private init(_ url: URL, delay: TimeInterval, incremental: Bool, imageLoaderService: ImageLoaderService, placeholder: @escaping (_ partialImage: PartialImage) -> Placeholder, content: @escaping (_ imageProxy: ImageProxy) -> Content, onLoad: ((_ imageProxy: ImageProxy) -> Void)?) {
        self.url = url
        self.delay = delay
        self.incremental = incremental
        self.placeholder = placeholder
        self.content = content
        self.imageLoaderService = imageLoaderService
        self.onLoad = onLoad
    }

    private let imageLoaderService: ImageLoaderService

    private let onLoad: ((_ imageProxy: ImageProxy) -> Void)?
}
