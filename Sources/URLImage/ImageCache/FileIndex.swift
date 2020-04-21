//
//  FileIndex.swift
//  URLImage
//
//
//  Created by Dmytro Anokhin on 26/10/2019.
//  Copyright © 2019 Dmytro Anokhin. All rights reserved.
//

import Foundation
import CoreData


// MARK: - FileIndex

@available(iOS 10.0, *)
final class FileIndex {

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

    func insertOrUpdate(fileIdentifier: String?, remoteURL: URL, fileName: String, dateCreated: Date, expiryDate: Date?) {
        context.perform {
            let file = NSEntityDescription.insertNewObject(forEntityName: RemoteFileManagedObject.entityName, into: self.context) as! RemoteFileManagedObject
            file.fileIdentifier = fileIdentifier
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

    func fileInfo(withFileIdentifier fileIdentifier: String, completion: @escaping (_ fileInfo: RemoteFileInfo?) -> Void) {
        fetch(fileIdentifier: fileIdentifier) { result in
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
                        name: "fileIdentifier",
                        type: .stringAttributeType
                    ),
                    .attribute(
                        name: "urlString",
                        type: .stringAttributeType
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
                ],
                indexes: [
                    .index(name: "byFileIdentifier", elements: [ .property(name: "fileIdentifier") ]),
                    .index(name: "byURLString", elements: [ .property(name: "urlString") ]),
                    .index(name: "byFileName", elements: [ .property(name: "fileName") ])
                ])
        ]
    )

    private let container: NSPersistentContainer

    private let context: NSManagedObjectContext

    private typealias FetchCompletion = (_ object: Result<RemoteFileManagedObject?, Error>) -> Void

    private func fetch(fileIdentifier: String, action: @escaping FetchCompletion) {
        context.perform {
            let request = NSFetchRequest<RemoteFileManagedObject>(entityName: RemoteFileManagedObject.entityName)
            request.predicate = NSPredicate(format: "fileIdentifier == %@", fileIdentifier)

            do {
                let fetchedObjects = try self.context.fetch(request)
                action(.success(fetchedObjects.first))
            }
            catch {
                action(.failure(error))
            }
        }
    }

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


// MARK: - NSPersistentContainer extension

fileprivate extension NSPersistentContainer {

    func load() {
        let semaphore = DispatchSemaphore(value: 1)

        loadPersistentStores { result, error in
            semaphore.signal()
        }

        semaphore.wait()
    }
}


// MARK: - RemoteFileManagedObject

fileprivate final class RemoteFileManagedObject: NSManagedObject {

    static let entityName = "RemoteFile"

    /// Unique identifier. Typically this field is the remote URL of a file. It can be different for cases when one file has multiple URLs or URL is dynamic.
    @NSManaged public var fileIdentifier: String?

    @NSManaged public var urlString: String?

    @NSManaged public var dateCreated: Date?

    @NSManaged public var expiryDate: Date?

    @NSManaged public var fileName: String?
}
