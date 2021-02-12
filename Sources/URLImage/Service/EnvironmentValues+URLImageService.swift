//
//  EnvironmentValues+URLImageService.swift
//  
//
//  Created by Dmytro Anokhin on 12/02/2021.
//

import SwiftUI


@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
private struct URLImageEnvironmentKey: EnvironmentKey {

    static let defaultValue: URLImageService = URLImageService.shared
}


@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension EnvironmentValues {

    var urlImageService: URLImageService {
        get {
            self[URLImageEnvironmentKey.self]
        }

        set {
            self[URLImageEnvironmentKey.self] = newValue
        }
    }
}
