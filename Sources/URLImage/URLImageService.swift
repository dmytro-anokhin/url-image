//
//  URLImageService.swift
//  
//
//  Created by Dmytro Anokhin on 25/08/2020.
//

import Foundation
import Combine

import DownloadManager
import FileIndex


public final class URLImageService {

    public static let shared = URLImageService()

    public let downloadManager = DownloadManager()

    public let fileIndex = FileIndex(configuration: .init(name: "URLImage",
                                                          filesDirectoryName: "images",
                                                          baseDirectoryName: "URLImage"))

    private var garbage: [AnyCancellable] = []

    public func prefetch(url: URL, completion: (() -> Void)? = nil) {
        guard garbage.isEmpty else {
            return
        }

        let download = Download(url: url)
        let cancellable = downloadManager.publisher(for: download)
            .tryMap { downloadResult -> Void in

                switch downloadResult {
                    case .data(let data):
                        if let file = try? URLImageService.shared.fileIndex.write(data, originalURL: url) {
                            let location = URLImageService.shared.fileIndex.location(of: file)
                            print("Cache file for: \(url) at location: \(location)")
                        }

                        return ()

                    case .file:
                        fatalError("Not implemented")
                }
            }
            .catch { _ in
                Just(())
            }
            .sink { _ in
                completion?()
            }

        garbage.append(cancellable)
    }
}
