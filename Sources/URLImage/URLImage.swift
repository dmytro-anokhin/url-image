//
//  URLImage.swift
//  URLImage
//
//  Created by Dmytro Anokhin on 06/06/2019.
//  Copyright © 2019 Dmytro Anokhin. All rights reserved.
//

import SwiftUI
import Combine


/**
    URLImage is a view that automatically loads an image from provided URL.

    The image is loaded on appearance. Loading operation is cancelled when the view disappears.
 */
@available(iOS 13.0, tvOS 13.0, *)
public struct URLImage<Placeholder> : View where Placeholder : View {

    // MARK: Public

    let url: URL

    let placeholder: Placeholder

    let configuration: ImageLoaderConfiguration
    
    let completion: ((UIImage?) -> Void)?

    public init(_ url: URL, placeholder: () -> Placeholder, configuration: ImageLoaderConfiguration = ImageLoaderConfiguration(), completion: ((UIImage?) -> Void)? = nil) {
        self.url = url
        self.placeholder = placeholder()
        self.configuration = configuration
        self.style = nil
        self.completion = completion
    }

    public var body: some View {
        DispatchQueue.main.async {
            if self.previousURL != self.url {
                self.image = nil
            }
        }

        var image = self.image

        if let resizable = style?.resizable {
            image = image?.resizable(capInsets: resizable.capInsets, resizingMode: resizable.resizingMode)
        }

        if let renderingMode = style?.renderingMode {
            image = image?.renderingMode(renderingMode)
        }

        if let interpolation = style?.interpolation {
            image = image?.interpolation(interpolation)
        }

        if let isAntialiased = style?.isAntialiased {
            image = image?.antialiased(isAntialiased)
        }

        return ZStack {
            if image == nil {
                URLImageLoaderView(url, placeholder: AnyView(placeholder), configuration: configuration, onLoaded: { image in
                    self.image = Image(uiImage: image)
                    self.previousURL = self.url
                    self.completion?(image)
                })
            }

            image
        }
    }

    // MARK: Private

    fileprivate struct ImageStyle {

        var resizable: (capInsets: EdgeInsets, resizingMode: Image.ResizingMode)?

        var renderingMode: Image.TemplateRenderingMode?

        var interpolation: Image.Interpolation?

        var isAntialiased: Bool?
    }

    private let style: ImageStyle?

    @State private var image: Image? = nil

    @State private var previousURL: URL? = nil
}


public extension URLImage {

    fileprivate init(_ url: URL, placeholder: () -> Placeholder, configuration: ImageLoaderConfiguration, style: ImageStyle?, completion: ((UIImage?) -> Void)? = nil) {
        self.url = url
        self.placeholder = placeholder()
        self.configuration = configuration
        self.style = style
        self.completion = completion
    }
}


@available(iOS 13.0, tvOS 13.0, *)
public extension URLImage where Placeholder == Image {

    init(_ url: URL, placeholder: Image = Image(systemName: "photo"), configuration: ImageLoaderConfiguration = ImageLoaderConfiguration(), completion: ((UIImage?) -> Void)? = nil) {
        self.url = url
        self.placeholder = placeholder
        self.configuration = configuration
        self.style = nil
        self.completion = completion
    }
}


@available(iOS 13.0, tvOS 13.0, *)
extension URLImage {

    public func resizable(capInsets: EdgeInsets = EdgeInsets(), resizingMode: Image.ResizingMode = .stretch) -> URLImage {
        let newStyle = ImageStyle(
            resizable: (
                capInsets: capInsets,
                resizingMode: resizingMode
            ),
            renderingMode: style?.renderingMode,
            interpolation: style?.interpolation,
            isAntialiased: style?.isAntialiased
        )

        return URLImage(url, placeholder: { placeholder }, configuration: configuration, style: newStyle, completion: completion)
    }

    public func renderingMode(_ renderingMode: Image.TemplateRenderingMode?) -> URLImage {
        let newStyle = ImageStyle(
            resizable: style?.resizable,
            renderingMode: renderingMode,
            interpolation: style?.interpolation,
            isAntialiased: style?.isAntialiased
        )

        return URLImage(url, placeholder: { placeholder }, configuration: configuration, style: newStyle, completion: completion)
    }

    public func interpolation(_ interpolation: Image.Interpolation) -> URLImage {
        let newStyle = ImageStyle(
            resizable: style?.resizable,
            renderingMode: style?.renderingMode,
            interpolation: interpolation,
            isAntialiased: style?.isAntialiased
        )

        return URLImage(url, placeholder: { placeholder }, configuration: configuration, style: newStyle, completion: completion)
    }

    public func antialiased(_ isAntialiased: Bool) -> URLImage {
        let newStyle = ImageStyle(
            resizable: style?.resizable,
            renderingMode: style?.renderingMode,
            interpolation: style?.interpolation,
            isAntialiased: isAntialiased
        )

        return URLImage(url, placeholder: { placeholder }, configuration: configuration, style: newStyle, completion: completion)
    }
}


@available(iOS 13.0, tvOS 13.0, *)
struct URLImageLoaderView : View {

    let url: URL

    let placeholder: AnyView

    let configuration: ImageLoaderConfiguration

    let onLoaded: (_ image: UIImage) -> Void

    init(_ url: URL, placeholder: AnyView, configuration: ImageLoaderConfiguration, onLoaded: @escaping (_ image: UIImage) -> Void) {
        self.url = url
        self.placeholder = placeholder
        self.configuration = configuration
        self.onLoaded = onLoaded
    }

    var body: some View {
        let observer = ImageLoaderObserver { image in
            self.onLoaded(image)
        }

        return placeholder
            .onAppear {
                self.imageLoaderService.subscribe(forURL: self.url, observer)
                self.imageLoaderService.load(url: self.url, configuration: self.configuration)
            }
            .onDisappear {
                self.imageLoaderService.unsubscribe(observer, fromURL: self.url)
            }
    }

    private var imageLoaderService: ImageLoaderService = ImageLoaderServiceImpl.shared
}
