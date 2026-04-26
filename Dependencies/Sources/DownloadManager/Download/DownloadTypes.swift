//
//  DownloadTypes.swift
//  
//
//  Created by Dmytro Anokhin on 19/07/2020.
//

import Foundation


public enum DownloadResult: Sendable {

    case data(_ data: Data)

    case file(_ path: String)
}


public enum DownloadInfo: Sendable {

    case progress(_ progress: Float?)

    case completion(_ result: DownloadResult)
}


extension DownloadResult : Hashable {}

public typealias DownloadError = Error

public typealias DownloadReceiveResponse = @Sendable (_ download: Download) -> Void
public typealias DownloadReceiveData = @Sendable (_ download: Download, _ data: Data) -> Void
public typealias DownloadReportProgress = @Sendable (_ download: Download, _ progress: Float?) -> Void
public typealias DownloadCompletion = @Sendable (_ download: Download, _ result: Result<DownloadResult, DownloadError>) -> Void

public enum DownloadStatus: Sendable {
    case receiveResponse(download: Download)
    case receiveData(download: Download, _ data: Data)
    case reportProgress(download: Download, _ progress: Float?)
    case completion(download: Download, _ result: Result<DownloadResult, DownloadError>)
}
