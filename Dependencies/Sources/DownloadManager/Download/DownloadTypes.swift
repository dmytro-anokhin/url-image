//
//  DownloadTypes.swift
//  
//
//  Created by Dmytro Anokhin on 19/07/2020.
//

import Foundation


public enum DownloadResult {

    case data(_ data: Data)

    case file(_ path: String)
}


public enum DownloadInfo {

    case progress(_ progress: Float?)

    case completion(_ result: DownloadResult)
}


extension DownloadResult : Hashable {}

public typealias DownloadError = URLError

public typealias DownloadReceiveResponse = (_ download: Download) -> Void
public typealias DownloadReceiveData = (_ download: Download, _ data: Data, _ progress: Float?) -> Void
public typealias DownloadCompletion = (_ download: Download, _ result: Result<DownloadResult, DownloadError>) -> Void
