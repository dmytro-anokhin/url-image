//
//  URLImageService.swift
//  
//
//  Created by Dmytro Anokhin on 25/08/2020.
//

import DownloadManager
import FileIndex


public final class URLImageService {

    public static let shared = URLImageService()

    public let downloadManager = DownloadManager()

    public let fileIndex = FileIndex(configuration: .init(name: "URLImage",
                                                          filesDirectoryName: "images",
                                                          baseDirectoryName: "URLImage"))
}
