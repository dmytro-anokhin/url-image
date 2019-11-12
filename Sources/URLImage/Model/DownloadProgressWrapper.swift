//
//  DownloadProgressWrapper.swift
//  URLImage
//
//
//  Created by Dmytro Anokhin on 21/09/2019.
//  Copyright © 2019 Dmytro Anokhin. All rights reserved.
//

import Combine


@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
public final class DownloadProgressWrapper: ObservableObject {

    @Published public var progress: Float?

    public init(progress: Float? = nil) {
        self.progress = progress
    }
}
