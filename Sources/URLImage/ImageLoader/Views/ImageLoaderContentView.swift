//
//  ImageLoaderContentView.swift
//  
//
//  Created by Dmytro Anokhin on 05/10/2019.
//

import SwiftUI


/// Displays the placeholder or the content view for incremental loading
@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
struct ImageLoaderContentView<Content, Placeholder> : View where Content : View, Placeholder : View {

    class Model: ObservableObject {

        /// Image for incremental loading
        @Published var imageProxy: ImageProxy?

        let downloadProgressWrapper: DownloadProgressWrapper

        init() {
            imageProxy = nil
            downloadProgressWrapper = DownloadProgressWrapper()
        }
    }

    let placeholder: (_ downloadProgressWrapper: DownloadProgressWrapper) -> Placeholder

    let content: (_ imageProxy: ImageProxy) -> Content

    init(model: Model, placeholder: @escaping (_ downloadProgressWrapper: DownloadProgressWrapper) -> Placeholder, content: @escaping (_ imageProxy: ImageProxy) -> Content) {
        self.model = model
        self.placeholder = placeholder
        self.content = content
    }

    var body: some View {
        ZStack {
            if model.imageProxy == nil {
                placeholder(model.downloadProgressWrapper)
            }
            else {
                content(model.imageProxy!)
            }
        }
    }

    /// Image for incremental loading
    @ObservedObject var model: Model
}
