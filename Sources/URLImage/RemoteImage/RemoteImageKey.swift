//
//  RemoteImageKey.swift
//  
//
//  Created by Dmytro Anokhin on 24/05/2021.
//

import Foundation


/// The key to identify same remote images
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
struct RemoteImageKey {

    let url: URL

    let identifier: String?

    let options: URLImageOptions
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension RemoteImageKey: Hashable {}
