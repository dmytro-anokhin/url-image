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

    func addFile(withRemoteURL remoteURL: URL, sourceURL: URL) throws -> URL

    func getFile(withRemoteURL remoteURL: URL, completion: @escaping (_ localFileURL: URL?) -> Void)

    func delete(fileName: String) throws
}


// MARK: - RemoteFileCacheServiceImpl

@available(iOS 10.0, *)
final class RemoteFileCacheServiceImpl: RemoteFileCacheService {

    static let shared = RemoteFileCacheServiceImpl(name: "URLImage", baseURL: FileManager.appCachesDirectoryURL)

    /// The name of the directory managed by the `RemoteImageCacheService` instance.
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
        filesIndexURL = directoryURL.appendingPathComponent("files").appendingPathExtension("db")

        index = FileIndex(url: filesIndexURL)
    }

    /// Copy a file downloaded from `remoteURL` and located at `sourceURL` to the directory managed by the `RemoteImageCacheService` instance.
    /// Returns URL of the copy. This function generates unique name for the copied file.
    ///
    /// Example: ".../Library/Caches/URLImage/files/01234567-89AB-CDEF-0123-456789ABCDEF"
    func addFile(withRemoteURL remoteURL: URL, sourceURL: URL) throws -> URL {
        let pathExtension = remoteURL.pathExtension.isEmpty ? "file" : remoteURL.pathExtension
        let fileName = UUID().uuidString + "." + (pathExtension)
        let destinationURL = fileURL(forFileName: fileName)

        try copy(from: sourceURL, to: destinationURL)
        index.insertOrUpdate(remoteURL: remoteURL, fileName: fileName, dateCreated: Date())

        return destinationURL
    }

    func getFile(withRemoteURL remoteURL: URL, completion: @escaping (_ localFileURL: URL?) -> Void) {
        index.fileInfo(forRemoteURL: remoteURL) { fileInfo in
            guard let fileInfo = fileInfo else {
                completion(nil)
                return
            }

            let localFileURL = self.fileURL(forFileName: fileInfo.fileName)
            completion(localFileURL)
        }
    }

    /// Removes the file from the directory managed by the `RemoteImageCacheService` instance.
    func delete(fileName: String) throws {
        defer {
            index.removeFileInfo(forFileName: fileName)
        }

        let localFileURL = fileURL(forFileName: fileName)
        try FileManager.default.removeItem(at: localFileURL)
    }

    /// URL of the directory managed by the `RemoteImageCacheService`. This is the concatenation of the `name` and `baseURL`
    ///
    /// Example: ".../Library/Caches/URLImage/"
    private let directoryURL: URL

    /// URL of the directory inside the `directoryURL` where the `RemoteImageCacheService` keeps copied files.
    ///
    /// Example: ".../Library/Caches/URLImage/files"
    private let filesDirectoryURL: URL

    /// URL of the database file inside the `directoryURL`.
    ///
    /// Example: ".../Library/Caches/URLImage/files.db"
    private let filesIndexURL: URL

    /// The database used to keep track of copied and deleted files
    private let index: FileIndex
}

// MARK: - File Operations

@available(iOS 10.0, *)
fileprivate extension RemoteFileCacheServiceImpl {

    /// Returns the URL of a file in the directory managed by the `RemoteImageCacheService` instance.
    ///
    /// Example: ".../Library/Caches/URLImage/files/01234567-89AB-CDEF-0123-456789ABCDEF.png"
    func fileURL(forFileName fileName: String) -> URL {
        return filesDirectoryURL.appendingPathComponent(fileName, isDirectory: false)
    }

    /// Copy a file from `sourceURL` to the directory managed by the `RemoteImageCacheService` instance.
    /// `fileName` must be provided.
    func copy(from sourceURL: URL, to destinationURL: URL) throws {
        let fileManager = FileManager.default

        try? fileManager.createDirectory(at: filesDirectoryURL, withIntermediateDirectories: true, attributes: nil)
        try fileManager.copyItem(at: sourceURL, to: destinationURL)
    }
}

// MARK: - RemoteFileManagedObject

final class RemoteFileManagedObject: NSManagedObject {

    static let entityName = "RemoteFile"

    @NSManaged public var urlString: String?

    @NSManaged public var dateCreated: Date?

    @NSManaged public var fileName: String?
}

// MARK: - FileIndex

@available(iOS 10.0, *)
fileprivate class FileIndex {

    init(url: URL) {
        let model = FileIndex.coreDataModelDescription.makeModel()

        let storeDescription = NSPersistentStoreDescription()
        storeDescription.url = url

        container = NSPersistentContainer(name: "URLImage", managedObjectModel: model)
        container.persistentStoreDescriptions = [storeDescription]
    }

    func insertOrUpdate(remoteURL: URL, fileName: String, dateCreated date: Date) {
        context.perform {
            let file = NSEntityDescription.insertNewObject(forEntityName: RemoteFileManagedObject.entityName, into: self.context) as! RemoteFileManagedObject
            file.urlString = remoteURL.absoluteString
            file.dateCreated = date
            file.fileName = fileName

            do {
                try self.context.save()
            }
            catch {
                print(error)
            }
        }
    }

    typealias RemoteFileInfo = (urlString: String, dateCreated: Date, fileName: String)

    func fileInfo(forRemoteURL remoteURL: URL, completion: @escaping (_ fileInfo: RemoteFileInfo?) -> Void) {
        fetch(urlString: remoteURL.absoluteString) { result in
            switch result {
                case .success(let file):
                    guard let file = file else {
                        completion(nil)
                        return
                    }

                    // Here file must contain all the fields
                    let result = RemoteFileInfo(urlString: file.urlString!, dateCreated: file.dateCreated!, fileName: file.fileName!)
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
                    )
                ])
        ]
    )

    private let container: NSPersistentContainer

    private var _context: NSManagedObjectContext?

    private var context: NSManagedObjectContext {
        if _context == nil {
            load()
            _context = container.newBackgroundContext()
            _context?.undoManager = nil
        }

        return _context!
    }

    private func load() {
        let semaphore = DispatchSemaphore(value: 1)

        container.loadPersistentStores { result, error in
            semaphore.signal()
        }

        semaphore.wait()
    }

    private func fetch(urlString: String? = nil, fileName: String? = nil, action: @escaping (_ object: Result<RemoteFileManagedObject?, Error>) -> Void) {
        context.perform {
            let request = NSFetchRequest<RemoteFileManagedObject>(entityName: RemoteFileManagedObject.entityName)

            if let urlString = urlString {
                request.predicate = NSPredicate(format: "urlString == %@", urlString)
            }

            if let fileName = fileName {
                request.predicate = NSPredicate(format: "fileName == %@", fileName)
            }

            assert(request.predicate != nil, "urlString or fileName mustbe provided")

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
