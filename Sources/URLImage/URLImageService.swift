//
//  URLImageService.swift
//  
//
//  Created by Dmytro Anokhin on 11/10/2019.
//

import Foundation


public protocol URLImageServiceType {

    static var httpAdditionalHeaders: [AnyHashable : Any]? { get }

    static func setHttpAdditionalHeaders(_ httpAdditionalHeaders: [AnyHashable : Any]?)
    
    var services: Services { get }

    var defaultExpiryTime: TimeInterval { get }

    func setDefaultExpiryTime(_ defaultExpiryTime: TimeInterval)

    func resetFileCache()

    func cleanFileCache()
}


public final class Services {

    init(remoteFileCacheService: RemoteFileCacheService, imageLoaderService: ImageLoaderService, imageProcessingService: ImageProcessingService) {
        self.remoteFileCacheService = remoteFileCacheService
        self.imageLoaderService = imageLoaderService
        self.imageProcessingService = imageProcessingService
    }

    let remoteFileCacheService: RemoteFileCacheService

    let imageLoaderService: ImageLoaderService

    let imageProcessingService: ImageProcessingService
}


public final class URLImageService: URLImageServiceType {

    public static let shared: URLImageServiceType = URLImageService()

    public let services: Services

    public static private(set) var httpAdditionalHeaders: [AnyHashable : Any]?

    public static func setHttpAdditionalHeaders(_ httpAdditionalHeaders: [AnyHashable : Any]?) {
        self.httpAdditionalHeaders = httpAdditionalHeaders
    }

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
        let imageProcessingService = ImageProcessingServiceImpl()

        let imageLoaderService = ImageLoaderServiceImpl(remoteFileCache: remoteFileCacheService, imageProcessingService: imageProcessingService)

        services = Services(remoteFileCacheService: remoteFileCacheService, imageLoaderService: imageLoaderService, imageProcessingService: imageProcessingService)
    }
}
