//
//  RemoteContentView+Extensions.swift
//  
//
//  Created by Dmytro Anokhin on 10/08/2020.
//

import SwiftUI
import Combine


@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension RemoteContentView where Empty == EmptyView {

    init<R: RemoteContent>(remoteContent: R,
                           inProgress: @escaping (_ progress: Progress) -> InProgress,
                           failure: @escaping (_ error: Error, _ retry: @escaping () -> Void) -> Failure,
                           content: @escaping (_ value: Value) -> Content) where R.ObjectWillChangePublisher == ObservableObjectPublisher,
                                                                                 R.Value == Value,
                                                                                 R.Progress == Progress
    {
        self.init(remoteContent: remoteContent,
                  empty: { EmptyView() },
                  inProgress: inProgress,
                  failure: failure,
                  content: content)
    }
}


@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension RemoteContentView where Empty == EmptyView, InProgress == ActivityIndicator {

    init<R: RemoteContent>(remoteContent: R,
                           failure: @escaping (_ error: Error, _ retry: @escaping () -> Void) -> Failure,
                           content: @escaping (_ value: Value) -> Content) where R.ObjectWillChangePublisher == ObservableObjectPublisher,
                                                                                 R.Value == Value,
                                                                                 R.Progress == Progress
    {
        self.init(remoteContent: remoteContent,
                  empty: { EmptyView() },
                  inProgress: { _ in ActivityIndicator() },
                  failure: failure,
                  content: content)
    }
}


@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension RemoteContentView where Empty == EmptyView, Failure == Text {

    init<R: RemoteContent>(remoteContent: R,
                           inProgress: @escaping (_ progress: Progress) -> InProgress,
                           content: @escaping (_ value: Value) -> Content) where R.ObjectWillChangePublisher == ObservableObjectPublisher,
                                                                                 R.Value == Value,
                                                                                 R.Progress == Progress
    {
        self.init(remoteContent: remoteContent,
                  empty: { EmptyView() },
                  inProgress: inProgress,
                  failure: { error, _ in Text(error.localizedDescription) },
                  content: content)
    }
}


@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension RemoteContentView where Empty == EmptyView, InProgress == ActivityIndicator, Failure == Text {

    init<R: RemoteContent>(remoteContent: R,
                           content: @escaping (_ value: Value) -> Content) where R.ObjectWillChangePublisher == ObservableObjectPublisher,
                                                                                 R.Value == Value,
                                                                                 R.Progress == Progress
    {
        self.init(remoteContent: remoteContent,
                  empty: { EmptyView() },
                  inProgress: { _ in ActivityIndicator() },
                  failure: { error, _ in Text(error.localizedDescription) },
                  content: content)
    }
}
