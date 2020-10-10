//
//  DataTaskProgress.swift
//  
//
//  Created by Dmytro Anokhin on 10/10/2020.
//

import Foundation


struct DataTaskProgress {

    let expectedContentLength: Int64

    init(response: URLResponse) {
        expectedContentLength = response.expectedContentLength
    }

    var buffer = Data()

    var progress: Float? {
        guard expectedContentLength > 0 else {
            return nil
        }

        return Float(buffer.count) / Float(expectedContentLength)
    }
}
