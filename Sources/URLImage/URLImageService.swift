//
//  URLImageService.swift
//  
//
//  Created by Dmytro Anokhin on 11/10/2019.
//

import Foundation


public protocol URLImageServiceType {

    var services: Services { get }

    func resetFileCache()
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

    public func resetFileCache() {
        services.remoteFileCacheService.reset()
    }

    private init() {
        let remoteFileCacheService = RemoteFileCacheServiceImpl(name: "URLImage", baseURL: FileManager.appCachesDirectoryURL)
        let inMemoryCacheService = InMemoryCacheServiceDummyImpl()
        let imageLoaderService = ImageLoaderServiceImpl(remoteFileCache: remoteFileCacheService, inMemoryCacheService: inMemoryCacheService)

        services = Services(remoteFileCacheService: remoteFileCacheService, inMemoryCacheService: inMemoryCacheService, imageLoaderService: imageLoaderService)
    }
}
