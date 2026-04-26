//
//  EnvironmentValues+URLImage.swift
//  
//
//  Created by Dmytro Anokhin on 12/02/2021.
//

import SwiftUI

@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
public extension EnvironmentValues {

    /// Service used by instances of the `URLImage` view
    @Entry var urlImageService: URLImageService = URLImageService()

    /// Options object used by instances of the `URLImage` view
    @Entry var urlImageOptions: URLImageOptions = URLImageOptions()
}
