//
//  RemoteImageContainerView.swift
//  
//
//  Created by Dmytro Anokhin on 14/02/2021.
//

import SwiftUI

#if canImport(Model)
import Model
#endif


@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
struct RemoteImageContainerView<Empty, InProgress, Failure, Content> : View where Empty : View,
                                                                                  InProgress : View,
                                                                                  Failure : View,
                                                                                  Content : View {

    let remoteImage: RemoteImage

    let loadOptions: URLImageOptions.LoadOptions

    init(remoteImage: RemoteImage,
         loadOptions: URLImageOptions.LoadOptions,
         empty: @escaping () -> Empty,
         inProgress: @escaping (_ progress: Float?) -> InProgress,
         failure: @escaping (_ error: Error, _ retry: @escaping () -> Void) -> Failure,
         content: @escaping (_ transientImage: TransientImage) -> Content) {

        self.remoteImage = remoteImage
        self.loadOptions = loadOptions

        self.empty = empty
        self.inProgress = inProgress
        self.failure = failure
        self.content = content
    }

    private let empty: () -> Empty
    private let inProgress: (_ progress: Float?) -> InProgress
    private let failure: (_ error: Error, _ retry: @escaping () -> Void) -> Failure
    private let content: (_ image: TransientImage) -> Content

    var body: some View {
        let view = RemoteImageView(remoteImage: remoteImage,
                                   empty: empty,
                                   inProgress: inProgress,
                                   failure: failure,
                                   content: content)
            .onAppear {
                if loadOptions.contains(.loadOnAppear) {
                    remoteImage.load()
                }
            }
            .onDisappear {
                if loadOptions.contains(.cancelOnDisappear) {
                    remoteImage.cancel()
                }
            }

        if loadOptions.contains(.loadImmediately) {
            remoteImage.load()
        }

        return view
    }
}
