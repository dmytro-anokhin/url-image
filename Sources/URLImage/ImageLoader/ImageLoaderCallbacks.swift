//
//  ImageLoaderCallbacks.swift
//  URLImage
//
//
//  Created by Dmytro Anokhin on 29/08/2019.
//  Copyright © 2019 Dmytro Anokhin. All rights reserved.
//

import SwiftUI


typealias ImageLoaderProgressCallback = (_ image: @autoclosure () -> Image) -> Void
typealias ImageLoaderCompletionCallback = (_ image: Image) -> Void
