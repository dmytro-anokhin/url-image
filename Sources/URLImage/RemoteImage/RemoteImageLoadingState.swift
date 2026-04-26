//
//  RemoteImageLoadingState.swift
//  
//
//  Created by Dmytro Anokhin on 19/08/2020.
//

import Model
import CoreGraphics


/// The state of the loading process.
///
/// The `RemoteContentLoadingState` serves dual purpose:
/// - represents the state of the loading process: initial, in progress, success or failure;
/// - keeps associated value relevant to the state of the loading process.
///
/// This dual purpose allows the view to use switch statement in its `body` and return different view in each case.
///
@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
public enum RemoteImageLoadingState: Sendable {

    case initial

    case inProgress(_ progress: Float?)

    case success(_ value: TransientImage)

    case failure(_ error: Error)
}

@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
public enum RemoteImageLoadingCacheState: Sendable {

    case initial

    case inProgress(_ progress: Float?)

    case success(_ value: TransientImage, _ cgImage: CGImage?)

    case failure(_ error: Error)
    
    public static func load(_ state: RemoteImageLoadingState) async -> Self {
        switch state {
        case .initial:
            return .initial
        case .inProgress(let value):
            return  .inProgress(value)
        case .success(let transitImage):
            return .success(transitImage, await transitImage.cgImage)
        case .failure(let error):
            return .failure(error)
        }
    }
}

@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
extension RemoteImageLoadingState: Equatable {
    public static func == (lhs: RemoteImageLoadingState, rhs: RemoteImageLoadingState) -> Bool {
        switch (lhs, rhs) {
        case (.initial, .initial):
            return true
        case (.inProgress(let lp), .inProgress(let rp)):
            return lp == rp
        case (.success(let lv), .success(let rv)):
            return lv.presentation == rv.presentation
        case (.failure(_), .failure(_)):
            return true
        default:
            return false
        }
    }
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
