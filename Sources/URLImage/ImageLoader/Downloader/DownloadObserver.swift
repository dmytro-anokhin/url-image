//
//  DownloadObserver.swift
//  
//
//  Created by Dmytro Anokhin on 21/11/2019.
//

import Foundation


@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
final class DownloadObserver: Hashable {

    typealias ProgressCallback = (_ progress: Float?) -> Void

    typealias PartialCallback = (_ data: Data) -> Void

    typealias CompletionCallback = (_ fileURL: URL) -> Void

    let progress: ProgressCallback

    let partial: PartialCallback

    let completion: CompletionCallback

    init(progress: @escaping ProgressCallback, partial: @escaping PartialCallback, completion: @escaping CompletionCallback) {
        self.progress = progress
        self.partial = partial
        self.completion = completion
    }

    static func == (lhs: DownloadObserver, rhs: DownloadObserver) -> Bool {
        return lhs === rhs
    }

    func hash(into hasher: inout Hasher) {
        let pointer = Unmanaged.passUnretained(self).toOpaque()
        hasher.combine(pointer)
    }
}
