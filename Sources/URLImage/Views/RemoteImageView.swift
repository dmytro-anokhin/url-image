//
//  RemoteImageView.swift
//  
//
//  Created by Dmytro Anokhin on 09/08/2020.
//

import SwiftUI
import Model


@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
struct RemoteImageView<Empty, InProgress, Failure, Content> : View where Empty : View,
                                                                         InProgress : View,
                                                                         Failure : View,
                                                                         Content : View {
    @ObservedObject var remoteImage: RemoteImage
    @Environment(\.urlImageOptions) var urlImageOptions

    let loadOptions: URLImageOptions.LoadOptions

    let empty: () -> Empty
    let inProgress: (_ progress: Float?) -> InProgress
    let failure: (_ error: Error, _ retry: @escaping () -> Void) -> Failure
    let content: (_ value: TransientImage, _ cgImage: CGImage?) -> Content
    
    @Namespace var namespace
    @State var animateState: RemoteImageLoadingCacheState = .initial

    init(remoteImage: RemoteImage,
         loadOptions: URLImageOptions.LoadOptions,
         @ViewBuilder empty: @escaping () -> Empty,
         @ViewBuilder inProgress: @escaping (_ progress: Float?) -> InProgress,
         @ViewBuilder failure: @escaping (_ error: Error, _ retry: @escaping () -> Void) -> Failure,
         @ViewBuilder content: @escaping (_ value: TransientImage, _ cgImage: CGImage?) -> Content) {

        self.remoteImage = remoteImage
        self.loadOptions = loadOptions

        self.empty = empty
        self.inProgress = inProgress
        self.failure = failure
        self.content = content

//        if loadOptions.contains(.loadImmediately), !remoteImage.loadingState.isSuccess {
//            remoteImage.load()
//        }
    }
    
    var body: some View {
        ZStack {
            switch animateState {
            case .initial:
                empty()
            case .inProgress(let progress):
                inProgress(progress)
            case .success(let value, let cgImage):
                if let cgImage {
                    content(value, cgImage)
                } else {
                    inProgress(1.0)
                }
            case .failure(let error):
                failure(error) {
                    remoteImage.load()
                }
            }
        }
        .onAppear {
            if loadOptions.contains(.loadOnAppear) || loadOptions.contains(.loadImmediately), !remoteImage.slowLoadingState.value.isSuccess {
                remoteImage.load()
            }
        }
        .onDisappear {
            if loadOptions.contains(.cancelOnDisappear) {
                remoteImage.cancel()
            }
            
            remoteImage.onDissAppear()
        }
        .onReceive(remoteImage.slowLoadingState) { newValue in
            guard urlImageOptions.loadingAnimated else {
                switch newValue {
                case .initial:
                    animateState = .initial
                case .inProgress(let value):
                    animateState = .inProgress(value)
                case .success(let transitImage):
                    Task {
                        animateState = .success(transitImage, await transitImage.cgImage)
                    }
                case .failure(let error):
                    animateState = .failure(error)
                }
                return
            }
            
            Task {
                let next = await RemoteImageLoadingCacheState.load(newValue)
                withAnimation(.spring) {
                    animateState = next
                }
            }
        }
    }
}
