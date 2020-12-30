//
//  URLImageSessionManager.swift
//  
//
//  Created by Dmytro Anokhin on 29/12/2020.
//

import Foundation
import Combine
import URLImage


/**
    The `URLImageSessionManager` provides APIs for downloading, accessing cached images, and keeping track of ongoing downloads for `URLImage` package.

 */
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public final class URLImageSessionManager {

    unowned let service: URLImageService

    public init(service: URLImageService) {
        self.service = service
    }
}
