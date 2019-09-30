//
//  ImageLoaderCallbacks.swift
//  URLImage
//
//
//  Created by Dmytro Anokhin on 29/08/2019.
//  Copyright © 2019 Dmytro Anokhin. All rights reserved.
//

import SwiftUI


typealias ImageLoaderProgressCallback = (_ progress: Float?) -> Void
typealias ImageLoaderPartialCallback = (_ imageProxy: ImageProxy) -> Void
typealias ImageLoaderCompletionCallback = (_ imageProxy: ImageProxy) -> Void
