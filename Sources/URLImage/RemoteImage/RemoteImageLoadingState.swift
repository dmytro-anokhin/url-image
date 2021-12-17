//
//  RemoteImageLoadingState.swift
//  
//
//  Created by Dmytro Anokhin on 19/08/2020.
//

import Model


/// The state of the loading process.
///
/// The `RemoteContentLoadingState` serves dual purpose:
/// - represents the state of the loading process: initial, in progress, success or failure;
/// - keeps associated value relevant to the state of the loading process.
///
/// This dual purpose allows the view to use switch statement in its `body` and return different view in each case.
///
@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
public enum RemoteImageLoadingState {

    case initial

    case inProgress(_ progress: Float?)

    case success(_ value: TransientImage)

    case failure(_ error: Error)
}


@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
public extension RemoteImageLoadingState {

    var isInProgress: Bool {
        switch self {
            case .inProgress:
                return true
            default:
                return false
        }
    }

    var isSuccess: Bool {
        switch self {
            case .success:
                return true
            default:
                return false
        }
    }

    var isComplete: Bool {
        switch self {
            case .success, .failure:
                return true
            default:
                return false
        }
    }
}
