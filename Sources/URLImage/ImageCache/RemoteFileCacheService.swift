//
//  RemoteFileCacheService.swift
//  URLImage
//
//
//  Created by Dmytro Anokhin on 04/08/2019.
//  Copyright © 2019 Dmytro Anokhin. All rights reserved.
//

import Foundation
import CoreData


protocol RemoteFileCacheService: AnyObject {

    func addFile(withRemoteURL remoteURL: URL, sourceURL: URL, expiryDate: Date?, preferredFileExtension: @autoclosure () -> String?) throws -> URL

    func createFile(withRemoteURL remoteURL: URL, data: Data, expiryDate: Date?, preferredFileExtension: @autoclosure () -> String?) throws -> URL

    func getFile(withRemoteURL remoteURL: URL, completion: @escaping (_ localFileURL: URL?) -> Void)

    func delete(fileName: String) throws

    func reset()

    func clean()
}


// MARK: - RemoteFileCacheServiceImpl

@available(iOS 10.0, *)
final class RemoteFileCacheServiceImpl: RemoteFileCacheService {

    static let shared = RemoteFileCacheServiceImpl(name: "URLImage", baseURL: FileManager.appCachesDirectoryURL)

    /// The name of the directory managed by the `RemoteFileCacheService` instance.
    ///
    /// Example: "URLImage"
    let name: String

    /// URL of the base directory.
    ///
    /// Example: ".../Library/Caches/"
    let baseURL: URL

    init(name: String, baseURL: URL) {
        self.name = name
        self.baseURL = baseURL

        directoryURL = baseURL.appendingPathComponent(name, isDirectory: true)
        filesDirectoryURL = directoryURL.appendingPathComponent("files", isDirectory: true)

        // Check previous version and clean if necessary
        let versionFileURL = directoryURL.appendingPathComponent("filesCacheVersion", isDirectory: false)
        var cleanFilesCache = true

        if let data = try? Data(contentsOf: versionFileURL), let version = try? JSONDecoder().decode(Version.self, from: data) {
            cleanFilesCache = version < RemoteFileCacheServiceImpl.minimumCompatibleVersion
        }

        if cleanFilesCache {
            // Remove old files cache
            try? FileManager.default.removeItem(at: directoryURL)
        }

        // Create directory if necessary. Directory must be created before initializing index or adding files.
        try? FileManager.default.createDirectory(at: filesDirectoryURL, withIntermediateDirectories: true, attributes: nil)

        let encoder = JSONEncoder()

        if let data = try? encoder.encode(RemoteFileCacheServiceImpl.version) {
            try? data.write(to: versionFileURL)
        }

        index = FileIndex(directoryURL: directoryURL, fileName: "files", pathExtension: "db")
    }

    /// Copy a file downloaded from `remoteURL` and located at `sourceURL` to the directory managed by the `RemoteFileCacheService` instance.
    /// Returns URL of the copy. This function generates unique name for the copied file.
    ///
    /// Example: ".../Library/Caches/URLImage/files/01234567-89AB-CDEF-0123-456789ABCDEF.file"
    func addFile(withRemoteURL remoteURL: URL, sourceURL: URL, expiryDate: Date?, preferredFileExtension: @autoclosure () -> String?) throws -> URL {
        return try queue.sync {
            let fileName = self.fileName(forRemoteURL: remoteURL, preferredFileExtension: preferredFileExtension())

            let destinationURL = fileURL(forFileName: fileName)

            try copy(from: sourceURL, to: destinationURL)
            index.insertOrUpdate(remoteURL: remoteURL, fileName: fileName, dateCreated: Date(), expiryDate: expiryDate)

            return destinationURL
        }
    }

    func createFile(withRemoteURL remoteURL: URL, data: Data, expiryDate: Date?, preferredFileExtension: @autoclosure () -> String?) throws -> URL {
        return try queue.sync {
            let fileName = self.fileName(forRemoteURL: remoteURL, preferredFileExtension: preferredFileExtension())
            let destinationURL = fileURL(forFileName: fileName)

            try data.write(to: destinationURL)
            index.insertOrUpdate(remoteURL: remoteURL, fileName: fileName, dateCreated: Date(), expiryDate: expiryDate)

            return destinationURL
        }
    }

    func getFile(withRemoteURL remoteURL: URL, completion: @escaping (_ localFileURL: URL?) -> Void) {
        queue.async {
            self.index.fileInfo(forRemoteURL: remoteURL) { fileInfo in
                guard let fileInfo = fileInfo else {
                    completion(nil)
                    return
                }

                // Check if expired
                if let expiryDate = fileInfo.expiryDate {
                    guard expiryDate > Date() else {
                        try? self.delete(fileName: fileInfo.fileName)
                        completion(nil)
                        return
                    }
                }

                let localFileURL = self.fileURL(forFileName: fileInfo.fileName)
                completion(localFileURL)
            }
        }
    }

    /// Removes the file from the directory managed by the `RemoteFileCacheService` instance.
    func delete(fileName: String) throws {
        try queue.sync {
            defer {
                index.removeFileInfo(forFileName: fileName)
            }

            let localFileURL = fileURL(forFileName: fileName)
            try FileManager.default.removeItem(at: localFileURL)
        }
    }

    func reset() {
        queue.async(flags: .barrier) {
            self.index.shutDown()

            let fileManager = FileManager.default
            try? fileManager.removeItem(at: self.directoryURL)
            try? fileManager.createDirectory(at: self.filesDirectoryURL, withIntermediateDirectories: true, attributes: nil)

            self.index = FileIndex(directoryURL: self.directoryURL, fileName: "files", pathExtension: "db")
        }
    }

    func clean() {
        queue.async(flags: .barrier) {
            self.index.removeExpired()
        }
    }

    // MARK: - Private

    /// The current version of the files cache.
    private static let version = Version(major: 1, minor: 0, patch: 0)

    /// The minimum compatible version of the files cache.
    private static let minimumCompatibleVersion = Version(major: 1, minor: 0, patch: 0)

    /// URL of the directory managed by the `RemoteFileCacheService`. This is the concatenation of the `name` and `baseURL`
    ///
    /// Example: ".../Library/Caches/URLImage/"
    private let directoryURL: URL

    /// URL of the directory inside the `directoryURL` where the `RemoteFileCacheService` keeps copied files.
    ///
    /// Example: ".../Library/Caches/URLImage/files"
    private let filesDirectoryURL: URL

    private let queue = DispatchQueue(label: "URLImage.RemoteFileCacheServiceImpl.queue", attributes: .concurrent)

    /// The database used to keep track of copied and deleted files
    private var index: FileIndex

    /// File name including path extension
    /// If the remote url does not contain path extension the default one is used (.file)
    ///
    /// 01234567-89AB-CDEF-0123-456789ABCDEF.file
    private func fileName(forRemoteURL remoteURL: URL, preferredFileExtension: @autoclosure () -> String?) -> String {
        let uuid = UUID().uuidString

        if !remoteURL.pathExtension.isEmpty {
            return uuid + "." + remoteURL.pathExtension
        }

        if let preferredFileExtension = preferredFileExtension() {
            return uuid + "." + preferredFileExtension
        }

        return uuid + ".file"
    }
}

// MARK: - File Operations

@available(iOS 10.0, *)
fileprivate extension RemoteFileCacheServiceImpl {

    /// Returns the URL of a file in the directory managed by the `RemoteFileCacheService` instance.
    ///
    /// Example: ".../Library/Caches/URLImage/files/01234567-89AB-CDEF-0123-456789ABCDEF.png"
    func fileURL(forFileName fileName: String) -> URL {
        return filesDirectoryURL.appendingPathComponent(fileName, isDirectory: false)
    }

    /// Copy a file from `sourceURL` to the directory managed by the `RemoteFileCacheService` instance.
    /// `fileName` must be provided.
    func copy(from sourceURL: URL, to destinationURL: URL) throws {
        try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
    }
}
