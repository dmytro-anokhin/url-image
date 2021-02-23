//
//  RemoteImageView.swift
//  
//
//  Created by Dmytro Anokhin on 09/08/2020.
//

import SwiftUI
import Combine

#if canImport(Model)
import Model
#endif


@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
struct RemoteImageView<Empty, InProgress, Failure, Content> : View where Empty : View,
                                                                         InProgress : View,
                                                                         Failure : View,
                                                                         Content : View {

    /// Controls how download starts and when it can be cancelled
    let loadOptions: URLImageOptions.LoadOptions

    let empty: () -> Empty
    let inProgress: (_ progress: Float?) -> InProgress
    let failure: (_ error: Error, _ retry: @escaping () -> Void) -> Failure
    let content: (_ value: TransientImage) -> Content

    init(remoteContent: RemoteImage,
         loadOptions: URLImageOptions.LoadOptions,
         empty: @escaping () -> Empty,
         inProgress: @escaping (_ progress: Float?) -> InProgress,
         failure: @escaping (_ error: Error, _ retry: @escaping () -> Void) -> Failure,
         content: @escaping (_ value: TransientImage) -> Content) {

        self.remoteImage = remoteContent

        self.loadOptions = loadOptions
        self.empty = empty
        self.inProgress = inProgress
        self.failure = failure
        self.content = content

        if loadOptions.contains(.loadImmediately) {
            remoteContent.load()
        }
    }

    var body: some View {
        ZStack {
            switch remoteImage.loadingState {
                case .initial:
                    empty()

                case .inProgress(let progress):
                    inProgress(progress)

                case .success(let value):
                    content(value)

                case .failure(let error):
                    failure(error) {
                        remoteImage.load()
                    }
            }
        }
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
    }

    @ObservedObject private var remoteImage: RemoteImage
}
