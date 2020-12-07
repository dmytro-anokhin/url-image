//
//  RemoteContentView.swift
//  
//
//  Created by Dmytro Anokhin on 09/08/2020.
//

import SwiftUI
import Combine


/// Controls how download starts and when it can be cancelled
public struct RemoteContentViewLoadOptions: OptionSet {

    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    /// Start load when the view is created
    public static let loadImmediately: RemoteContentViewLoadOptions = .init(rawValue: 1 << 0)

    /// Start load when the view appears
    public static let loadOnAppear: RemoteContentViewLoadOptions = .init(rawValue: 1 << 1)

    /// Cancel load when the view disappears
    public static let cancelOnDisappear: RemoteContentViewLoadOptions = .init(rawValue: 1 << 2)
}


@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public struct RemoteContentView<Value, Progress, Empty, InProgress, Failure, Content> : View where Empty : View,
                                                                                                   InProgress : View,
                                                                                                   Failure : View,
                                                                                                   Content : View
{
    let loadOptions: RemoteContentViewLoadOptions

    let empty: () -> Empty

    let inProgress: (_ progress: Progress) -> InProgress

    let failure: (_ error: Error, _ retry: @escaping () -> Void) -> Failure

    let content: (_ value: Value) -> Content

    public init<R: RemoteContent>(remoteContent: R,
                                  loadOptions: RemoteContentViewLoadOptions,
                                  empty: @escaping () -> Empty,
                                  inProgress: @escaping (_ progress: Progress) -> InProgress,
                                  failure: @escaping (_ error: Error, _ retry: @escaping () -> Void) -> Failure,
                                  content: @escaping (_ value: Value) -> Content) where R.ObjectWillChangePublisher == ObservableObjectPublisher,
                                                                                        R.Value == Value,
                                                                                        R.Progress == Progress
    {
        self.remoteContent = AnyRemoteContent(remoteContent)

        self.loadOptions = loadOptions
        self.empty = empty
        self.inProgress = inProgress
        self.failure = failure
        self.content = content

        if loadOptions.contains(.loadImmediately) {
            remoteContent.load()
        }
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
            if loadOptions.contains(.loadOnAppear) {
                remoteContent.load()
            }
        }
        .onDisappear {
            if loadOptions.contains(.cancelOnDisappear) {
                remoteContent.cancel()
            }
        }
    }

    @ObservedObject private var remoteContent: AnyRemoteContent<Value, Progress>
}
