//
//  RemoteContent.swift
//
//
//  Created by Dmytro Anokhin on 09/08/2020.
//

import Foundation
import Combine


@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public protocol RemoteContent : ObservableObject {

    associatedtype Value

    associatedtype Progress

    var loadingState: RemoteContentLoadingState<Value, Progress> { get }

    func load()

    func cancel()
}


@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
final class AnyRemoteContent<Value, Progress> : RemoteContent {

    init<R: RemoteContent>(_ remoteContent: R) where R.ObjectWillChangePublisher == ObjectWillChangePublisher,
                                                     R.Value == Value,
                                                     R.Progress == Progress {
        objectWillChangeClosure = {
            remoteContent.objectWillChange
        }

        loadingStateClosure = {
            remoteContent.loadingState
        }

        loadClosure = {
            remoteContent.cancel()
            remoteContent.load()
        }

        cancelClosure = {
            remoteContent.cancel()
        }
    }

    private let objectWillChangeClosure: () -> ObjectWillChangePublisher

    var objectWillChange: ObservableObjectPublisher {
        objectWillChangeClosure()
    }

    private let loadingStateClosure: () -> RemoteContentLoadingState<Value, Progress>

    var loadingState: RemoteContentLoadingState<Value, Progress> {
        loadingStateClosure()
    }

    private let loadClosure: () -> Void

    func load() {
        loadClosure()
    }

    private let cancelClosure: () -> Void

    func cancel() {
        cancelClosure()
    }
}
