//
//  URLImageLoaderView.swift
//  
//
//  Created by Dmytro Anokhin on 20/09/2019.
//

import SwiftUI


@available(iOS 13.0, tvOS 13.0, *)
struct URLImageLoaderView<Placeholder> : View where Placeholder : View {

    let url: URL

    let placeholder: () -> Placeholder

    let delay: TimeInterval

    init(_ url: URL, delay: TimeInterval, placeholder: @escaping () -> Placeholder) {
        self.url = url
        self.placeholder = placeholder
        self.delay = delay
        self.onLoad = nil
    }

    var body: some View {
        let observer = ImageLoaderObserver { imageProxy in
            self.onLoad?(imageProxy)
        }

        return placeholder()
            .onAppear {
                self.imageLoaderService.subscribe(forURL: self.url, observer)
                self.imageLoaderService.load(url: self.url, delay: self.delay)
            }
            .onDisappear {
                self.imageLoaderService.unsubscribe(observer, fromURL: self.url)
            }
    }

    func onLoad(perform action: ((_ imageProxy: ImageProxy) -> Void)? = nil) -> some View {
        return URLImageLoaderView(url, delay: delay, placeholder: placeholder, onLoad: action)
    }

    private init(_ url: URL, delay: TimeInterval, placeholder: @escaping () -> Placeholder, onLoad: ((_ imageProxy: ImageProxy) -> Void)?) {
        self.url = url
        self.placeholder = placeholder
        self.delay = delay
        self.onLoad = onLoad
    }

    private var imageLoaderService: ImageLoaderService = ImageLoaderServiceImpl.shared

    private var onLoad: ((_ imageProxy: ImageProxy) -> Void)?
}
