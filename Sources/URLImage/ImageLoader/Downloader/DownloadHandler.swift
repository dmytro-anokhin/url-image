//
//  DownloadHandler.swift
//  
//
//  Created by Dmytro Anokhin on 21/11/2019.
//

import Foundation


@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
class DownloadHandler: Hashable {

    func handleDownloadProgress(_ progress: Float?) {
    }

    func handleDownloadPartial(_ data: Data) {
    }

    func handleDownloadCompletion(_ data: Data?, _ fileURL: URL) {
    }

    func handleDownloadFailure(_ error: Error) {
    }
    
    var inMemory: Bool { false }

    static func == (lhs: DownloadHandler, rhs: DownloadHandler) -> Bool {
        return lhs === rhs
    }

    func hash(into hasher: inout Hasher) {
        let pointer = Unmanaged.passUnretained(self).toOpaque()
        hasher.combine(pointer)
    }
}
