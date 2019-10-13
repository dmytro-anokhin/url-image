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


protocol RemoteFileCacheService {

    func addFile(withRemoteURL remoteURL: URL, sourceURL: URL, expiryDate: Date?) throws -> URL

    func createFile(withRemoteURL remoteURL: URL, data: Data, expiryDate: Date?) throws -> URL

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

        // Create directory if necessary. Directory must be created before initializing index or adding files.
        try? FileManager.default.createDirectory(at: filesDirectoryURL, withIntermediateDirectories: true, attributes: nil)

        index = FileIndex(directoryURL: directoryURL, fileName: "files", pathExtension: "db")
    }

    /// Copy a file downloaded from `remoteURL` and located at `sourceURL` to the directory managed by the `RemoteFileCacheService` instance.
    /// Returns URL of the copy. This function generates unique name for the copied file.
    ///
    /// Example: ".../Library/Caches/URLImage/files/01234567-89AB-CDEF-0123-456789ABCDEF.file"
    func addFile(withRemoteURL remoteURL: URL, sourceURL: URL, expiryDate: Date?) throws -> URL {
        return try queue.sync {
            let fileName = self.fileName(forRemoteURL: remoteURL)
            let destinationURL = fileURL(forFileName: fileName)

            try copy(from: sourceURL, to: destinationURL)
            index.insertOrUpdate(remoteURL: remoteURL, fileName: fileName, dateCreated: Date(), expiryDate: expiryDate)

            return destinationURL
        }
    }

    func createFile(withRemoteURL remoteURL: URL, data: Data, expiryDate: Date?) throws -> URL {
        return try queue.sync {
            let fileName = self.fileName(forRemoteURL: remoteURL)
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
    private func fileName(forRemoteURL remoteURL: URL) -> String {
        let pathExtension = remoteURL.pathExtension.isEmpty ? "file" : remoteURL.pathExtension
        return UUID().uuidString + "." + (pathExtension)
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

// MARK: - RemoteFileManagedObject

final class RemoteFileManagedObject: NSManagedObject {

    static let entityName = "RemoteFile"

    @NSManaged public var urlString: String?

    @NSManaged public var dateCreated: Date?

    @NSManaged public var expiryDate: Date?

    @NSManaged public var fileName: String?
}

// MARK: - FileIndex

@available(iOS 10.0, *)
fileprivate class FileIndex {

    init(directoryURL: URL, fileName: String, pathExtension: String) {

        let model = FileIndex.coreDataModelDescription.makeModel()

        let storeDescription = NSPersistentStoreDescription()
        storeDescription.url = directoryURL.appendingPathComponent(fileName, isDirectory: false).appendingPathExtension(pathExtension)

        container = NSPersistentContainer(name: "URLImage", managedObjectModel: model)
        container.persistentStoreDescriptions = [storeDescription]
        container.load()

        context = container.newBackgroundContext()
        context.undoManager = nil
    }

    func shutDown() {
        let persistentStoreDescriptions = container.persistentStoreDescriptions

        for persistentStoreDescription in persistentStoreDescriptions {
            guard let url = persistentStoreDescription.url else {
                continue
            }

            do {
                try container.persistentStoreCoordinator.destroyPersistentStore(at: url, ofType: persistentStoreDescription.type, options: nil)
            }
            catch {
                print(error)
            }
        }
    }

    func insertOrUpdate(remoteURL: URL, fileName: String, dateCreated: Date, expiryDate: Date?) {
        context.perform {
            let file = NSEntityDescription.insertNewObject(forEntityName: RemoteFileManagedObject.entityName, into: self.context) as! RemoteFileManagedObject
            file.urlString = remoteURL.absoluteString
            file.dateCreated = dateCreated
            file.expiryDate = expiryDate
            file.fileName = fileName

            do {
                try self.context.save()
            }
            catch {
                print(error)
            }
        }
    }

    typealias RemoteFileInfo = (urlString: String, dateCreated: Date, expiryDate: Date?, fileName: String)

    func fileInfo(forRemoteURL remoteURL: URL, completion: @escaping (_ fileInfo: RemoteFileInfo?) -> Void) {
        fetch(urlString: remoteURL.absoluteString) { result in
            switch result {
                case .success(let file):
                    guard let file = file else {
                        completion(nil)
                        return
                    }

                    let result = RemoteFileInfo(urlString: file.urlString!, dateCreated: file.dateCreated!, expiryDate: file.expiryDate, fileName: file.fileName!)
                    completion(result)

                case .failure(let error):
                    print(error)
                    completion(nil)
            }
        }
    }

    func removeFileInfo(forFileName fileName: String) {
        fetch(fileName: fileName) { result in
            switch result {
                case .success(let file):
                    guard let file = file else {
                        return
                    }

                    self.context.delete(file)


                case .failure(let error):
                    print(error)
                    return
            }
        }
    }

    func removeExpired() {
        context.perform {
            let request = NSFetchRequest<RemoteFileManagedObject>(entityName: RemoteFileManagedObject.entityName)
            // request.fetchBatchSize = 10
            let now = Date()

            do {
                let fetchedObjects = try self.context.fetch(request)

                for object in fetchedObjects {
                    let expired: Bool

                    if let expiryDate = object.expiryDate {
                        expired = expiryDate < now
                    }
                    else {
                        expired = true
                    }

                    if expired {
                        self.context.delete(object)
                    }
                }
            }
            catch {
                print(error)
            }
        }
    }

    private static let coreDataModelDescription = CoreDataModelDescription(
        entities: [
            .entity(
                name: RemoteFileManagedObject.entityName,
                managedObjectClass: RemoteFileManagedObject.self,
                attributes: [
                    .attribute(
                        name: "urlString",
                        type: .stringAttributeType,
                        indexed: true
                    ),
                    .attribute(
                        name: "fileName",
                        type: .stringAttributeType
                    ),
                    .attribute(
                        name: "dateCreated",
                        type: .dateAttributeType
                    ),
                    .attribute(
                        name: "expiryDate",
                        type: .dateAttributeType
                    )
                ])
        ]
    )

    private let container: NSPersistentContainer

    private let context: NSManagedObjectContext

    private typealias FetchCompletion = (_ object: Result<RemoteFileManagedObject?, Error>) -> Void

    private func fetch(urlString: String, action: @escaping FetchCompletion) {
        context.perform {
            let request = NSFetchRequest<RemoteFileManagedObject>(entityName: RemoteFileManagedObject.entityName)
            request.predicate = NSPredicate(format: "urlString == %@", urlString)

            do {
                let fetchedObjects = try self.context.fetch(request)
                action(.success(fetchedObjects.first))
            }
            catch {
                action(.failure(error))
            }
        }
    }

    private func fetch(fileName: String, action: @escaping FetchCompletion) {
        context.perform {
            let request = NSFetchRequest<RemoteFileManagedObject>(entityName: RemoteFileManagedObject.entityName)
            request.predicate = NSPredicate(format: "fileName == %@", fileName)

            do {
                let fetchedObjects = try self.context.fetch(request)
                action(.success(fetchedObjects.first))
            }
            catch {
                action(.failure(error))
            }
        }
    }
}

fileprivate extension NSPersistentContainer {

    func load() {
        let semaphore = DispatchSemaphore(value: 1)

        loadPersistentStores { result, error in
            semaphore.signal()
        }

        semaphore.wait()
    }
}
