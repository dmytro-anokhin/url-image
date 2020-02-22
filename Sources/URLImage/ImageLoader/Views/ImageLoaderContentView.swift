//
//  ImageLoaderContentView.swift
//  
//
//  Created by Dmytro Anokhin on 05/10/2019.
//

import SwiftUI
import Combine


/// Displays the placeholder or the content view for incremental loading
@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
struct ImageLoaderContentView<Content, Placeholder> : View where Content : View, Placeholder : View {

    let placeholder: (_ downloadProgressWrapper: DownloadProgressWrapper) -> Placeholder

    let content: (_ imageProxy: ImageProxy) -> Content

    init(model: Model, placeholder: @escaping (_ downloadProgressWrapper: DownloadProgressWrapper) -> Placeholder, content: @escaping (_ imageProxy: ImageProxy) -> Content) {
        self.model = model
        self.placeholder = placeholder
        self.content = content
    }

    var body: some View {

        log_debug(self, "Content view render for: \(model.urlRequest.url!)", detail: log_extreme)

        return ZStack {
            if model.imageProxy == nil {
                placeholder(model.downloadProgressWrapper)
            }
            else {
                content(model.imageProxy!)
            }
        }
        .onAppear {
            self.model.load()
        }
        .onDisappear {
            self.model.cancel()
        }
    }

    /// Image for incremental loading
    @ObservedObject var model: Model
}
