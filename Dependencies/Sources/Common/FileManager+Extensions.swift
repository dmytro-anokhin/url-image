//
//  FileManager+Extensions.swift
//  
//
//  Created by Dmytro Anokhin on 09/09/2020.
//

import Foundation


public extension FileManager {

    var cachesDirectoryURL: URL {
        return urls(for: .cachesDirectory, in: .userDomainMask).first!
    }

    func tmpFilePathInCachesDirectory() -> String {
        cachesDirectoryURL.appendingPathComponent(UUID().uuidString).path
    }
}
