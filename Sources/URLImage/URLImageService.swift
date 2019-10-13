//
//  URLImageService.swift
//  
//
//  Created by Dmytro Anokhin on 11/10/2019.
//

import Foundation


public protocol URLImageServiceType {

    var services: Services { get }

    var defaultExpiryTime: TimeInterval { get }

    func setDefaultExpiryTime(_ defaultExpiryTime: TimeInterval)

    func resetFileCache()

    func cleanFileCache()
}


public final class Services {

    init(remoteFileCacheService: RemoteFileCacheService, inMemoryCacheService: InMemoryCacheService, imageLoaderService: ImageLoaderService) {
        self.remoteFileCacheService = remoteFileCacheService
        self.inMemoryCacheService = inMemoryCacheService
        self.imageLoaderService = imageLoaderService
    }

    let remoteFileCacheService: RemoteFileCacheService

    let inMemoryCacheService: InMemoryCacheService

    let imageLoaderService: ImageLoaderService
}


public final class URLImageService: URLImageServiceType {

    public static let shared: URLImageServiceType = URLImageService()

    public let services: Services

    public private(set) var defaultExpiryTime: TimeInterval = 60.0 * 60.0 * 24.0 * 7.0 // 1 week

    public func setDefaultExpiryTime(_ defaultExpiryTime: TimeInterval) {
        self.defaultExpiryTime = defaultExpiryTime
    }

    public func resetFileCache() {
        services.remoteFileCacheService.reset()
    }

    public func cleanFileCache() {
        services.remoteFileCacheService.clean()
    }

    private init() {
        let remoteFileCacheService = RemoteFileCacheServiceImpl(name: "URLImage", baseURL: FileManager.appCachesDirectoryURL)
        let inMemoryCacheService = InMemoryCacheServiceDummyImpl()
        let imageLoaderService = ImageLoaderServiceImpl(remoteFileCache: remoteFileCacheService, inMemoryCacheService: inMemoryCacheService)

        services = Services(remoteFileCacheService: remoteFileCacheService, inMemoryCacheService: inMemoryCacheService, imageLoaderService: imageLoaderService)
    }
}
