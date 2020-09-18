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

extension DownloadResult : Hashable {}

public typealias DownloadError = URLError

public typealias DownloadReceiveData = (_ download: Download, _ data: Data) -> Void
public typealias DownloadCompletion = (_ download: Download, _ result: Result<DownloadResult, DownloadError>) -> Void
