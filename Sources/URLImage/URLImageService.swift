//
//  URLImageService.swift
//  
//
//  Created by Dmytro Anokhin on 11/10/2019.
//

import Foundation


@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
public protocol URLImageServiceType {

    var services: Services { get }

    var defaultExpiryTime: TimeInterval { get }

    func setDefaultExpiryTime(_ defaultExpiryTime: TimeInterval)

    func resetFileCache()

    func cleanFileCache()

    func removeCachedImage(with url: URL)
}


@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
public final class Services {

    init(remoteFileCacheService: RemoteFileCacheService, downloadService: DownloadService) {
        self.remoteFileCacheService = remoteFileCacheService
        self.downloadService = downloadService
    }

    let remoteFileCacheService: RemoteFileCacheService

    let downloadService: DownloadService
}


@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
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

    public func removeCachedImage(with url: URL) {
        services.remoteFileCacheService.delete(withRemoteURL: url)
    }

    private init() {
        let remoteFileCacheService = RemoteFileCacheServiceImpl(name: "URLImage", baseURL: FileManager.appCachesDirectoryURL)
        let downloadService = DownloadServiceImpl(remoteFileCache: remoteFileCacheService)

        services = Services(remoteFileCacheService: remoteFileCacheService, downloadService: downloadService)
    }
}
