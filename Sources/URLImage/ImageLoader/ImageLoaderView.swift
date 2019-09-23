//
//  ImageLoaderView.swift
//  
//
//  Created by Dmytro Anokhin on 20/09/2019.
//

import SwiftUI


@available(iOS 13.0, tvOS 13.0, *)
struct ImageLoaderView<Placeholder> : View where Placeholder : View {

    let url: URL

    let placeholder: (_ partialImage: PartialImage) -> Placeholder

    let delay: TimeInterval

    init(_ url: URL, delay: TimeInterval, placeholder: @escaping (_ partialImage: PartialImage) -> Placeholder) {
        self.url = url
        self.placeholder = placeholder
        self.delay = delay
        self.onLoad = nil
    }

    var body: some View {
        let partialImage = PartialImage()

        let observer = ImageLoaderObserver(
            progress: { progress in
                partialImage.progress = progress
            },
            completion: { imageProxy in
                self.onLoad?(imageProxy)
            })

        return placeholder(partialImage)
            .onAppear {
                self.imageLoaderService.subscribe(forURL: self.url, observer)
                self.imageLoaderService.load(url: self.url, delay: self.delay)
            }
            .onDisappear {
                self.imageLoaderService.unsubscribe(observer, fromURL: self.url)
            }
    }

    func onLoad(perform action: ((_ imageProxy: ImageProxy) -> Void)? = nil) -> some View {
        return ImageLoaderView(url, delay: delay, placeholder: placeholder, onLoad: action)
    }

    private init(_ url: URL, delay: TimeInterval, placeholder: @escaping (_ partialImage: PartialImage) -> Placeholder, onLoad: ((_ imageProxy: ImageProxy) -> Void)?) {
        self.url = url
        self.placeholder = placeholder
        self.delay = delay
        self.onLoad = onLoad
    }

    private var imageLoaderService: ImageLoaderService = ImageLoaderServiceImpl.shared

    private var onLoad: ((_ imageProxy: ImageProxy) -> Void)?
}
