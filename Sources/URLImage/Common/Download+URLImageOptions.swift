//
//  Download+URLImageOptions.swift
//  
//
//  Created by Dmytro Anokhin on 20/11/2020.
//

import Foundation

#if canImport(DownloadManager)
import DownloadManager
#endif


@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Download {

    init(url: URL, options: URLImageOptions) {
        if options.loadOptions.contains(.inMemory) {
            self.init(url: url, urlRequestConfiguration: options.urlRequestConfiguration)
        }
        else {
            let path = FileManager.default.tmpFilePathInCachesDirectory()
            self.init(url: url, destination: .onDisk(path), urlRequestConfiguration: options.urlRequestConfiguration)
        }
    }
}
