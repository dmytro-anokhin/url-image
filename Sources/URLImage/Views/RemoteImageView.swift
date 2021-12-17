//
//  RemoteImageView.swift
//  
//
//  Created by Dmytro Anokhin on 09/08/2020.
//

import SwiftUI
import Combine
import Model


@available(macOS 11.0, iOS 14.0, tvOS 13.0, watchOS 6.0, *)
struct RemoteImageView<Empty, InProgress, Failure, Content> : View where Empty : View,
                                                                         InProgress : View,
                                                                         Failure : View,
                                                                         Content : View {
    @ObservedObject private(set) var remoteImage: RemoteImage

    let loadOptions: URLImageOptions.LoadOptions

    let empty: () -> Empty
    let inProgress: (_ progress: Float?) -> InProgress
    let failure: (_ error: Error, _ retry: @escaping () -> Void) -> Failure
    let content: (_ value: TransientImage) -> Content

    init(remoteImage: RemoteImage,
         loadOptions: URLImageOptions.LoadOptions,
         @ViewBuilder empty: @escaping () -> Empty,
         @ViewBuilder inProgress: @escaping (_ progress: Float?) -> InProgress,
         @ViewBuilder failure: @escaping (_ error: Error, _ retry: @escaping () -> Void) -> Failure,
         @ViewBuilder content: @escaping (_ value: TransientImage) -> Content) {

        self.remoteImage = remoteImage
        self.loadOptions = loadOptions

        self.empty = empty
        self.inProgress = inProgress
        self.failure = failure
        self.content = content

        if loadOptions.contains(.loadImmediately) {
            remoteImage.load()
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
}
