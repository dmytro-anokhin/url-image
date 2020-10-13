//
//  DownloadProgress.swift
//  
//
//  Created by Dmytro Anokhin on 13/10/2020.
//

import Foundation


struct DownloadProgress {

    var totalBytesExpected: Int64

    var totalBytesReceived: Int64

    init(response: URLResponse) {
        totalBytesExpected = response.expectedContentLength
        totalBytesReceived = 0
    }

    init() {
        totalBytesExpected = 0
        totalBytesReceived = 0
    }

    var percentage: Float? {
        guard totalBytesExpected > 0 else {
            return nil
        }

        return Float(totalBytesReceived) / Float(totalBytesExpected)
    }
}
