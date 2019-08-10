//
//  FileManager+Extensions.swift
//  URLImage
//
//  Created by Dmytro Anokhin on 01/08/2019.
//  Copyright © 2019 Dmytro Anokhin. All rights reserved.
//

import Foundation


extension FileManager {

    static var appCachesDirectoryURL: URL {
        return self.default.appCachesDirectoryURL
    }

    var appCachesDirectoryURL: URL {
        return urls(for: .cachesDirectory, in: .userDomainMask).first!
    }
}
