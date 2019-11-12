//
//  ImageLoaderCallbacks.swift
//  URLImage
//
//
//  Created by Dmytro Anokhin on 29/08/2019.
//  Copyright © 2019 Dmytro Anokhin. All rights reserved.
//

import SwiftUI


@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
typealias ImageLoaderProgressCallback = (_ progress: Float?) -> Void

@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
typealias ImageLoaderPartialCallback = (_ imageProxy: ImageProxy) -> Void

@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
typealias ImageLoaderCompletionCallback = (_ imageProxy: ImageProxy) -> Void
