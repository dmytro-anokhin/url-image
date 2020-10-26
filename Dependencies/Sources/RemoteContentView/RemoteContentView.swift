//
//  RemoteContentView.swift
//  
//
//  Created by Dmytro Anokhin on 09/08/2020.
//

import SwiftUI
import Combine


@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public struct RemoteContentView<Value, Progress, Empty, InProgress, Failure, Content> : View where Empty : View,
                                                                                                   InProgress : View,
                                                                                                   Failure : View,
                                                                                                   Content : View
{
    let empty: () -> Empty

    let inProgress: (_ progress: Progress) -> InProgress

    let failure: (_ error: Error, _ retry: @escaping () -> Void) -> Failure

    let content: (_ value: Value) -> Content

    public init<R: RemoteContent>(remoteContent: R,
                                  empty: @escaping () -> Empty,
                                  inProgress: @escaping (_ progress: Progress) -> InProgress,
                                  failure: @escaping (_ error: Error, _ retry: @escaping () -> Void) -> Failure,
                                  content: @escaping (_ value: Value) -> Content) where R.ObjectWillChangePublisher == ObservableObjectPublisher,
                                                                                        R.Value == Value,
                                                                                        R.Progress == Progress
    {
        self.remoteContent = AnyRemoteContent(remoteContent)

        self.empty = empty
        self.inProgress = inProgress
        self.failure = failure
        self.content = content

        remoteContent.load()
    }

    public var body: some View {
        ZStack {
            switch remoteContent.loadingState {
                case .initial:
                    empty()

                case .inProgress(let progress):
                    inProgress(progress)

                case .success(let value):
                    content(value)

                case .failure(let error):
                    failure(error) {
                        remoteContent.load()
                    }
            }
        }
        .onAppear {
            remoteContent.load()
        }
        .onDisappear {
            remoteContent.cancel()
        }
    }

    @ObservedObject private var remoteContent: AnyRemoteContent<Value, Progress>
}
