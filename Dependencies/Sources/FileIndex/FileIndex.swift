//
//  FileIndex.swift
//  
//
//  Created by Dmytro Anokhin on 11/09/2020.
//

import Foundation
import CoreData
import PlainDatabase


@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public class FileIndex {

    public struct Configuration {

        /// URL of the directory to keep file index, typically `~/Library/Caches/<main bundle identifier>`
        public var directoryURL: URL

        /// Name of the database file inside `directoryURL`
        public var name: String

        /// Name of the directory inside `directoryURL` to copy files to
        public var filesDirectoryName: String

        public init(name: String, filesDirectoryName: String, baseDirectoryName: String) {
            let directoryURL = FileManager.default.cachesDirectoryURL.appendingPathComponent(baseDirectoryName)
            self.init(name: name, filesDirectoryName: filesDirectoryName, directoryURL: directoryURL)
        }

        public init(name: String, filesDirectoryName: String, directoryURL: URL) {
            self.name = name
            self.filesDirectoryName = filesDirectoryName
            self.directoryURL = directoryURL
        }

        let modelDescription = CoreDataModelDescription(
            entity: .init(name: "File",
                          managedObjectClass: NSManagedObject.self,
                          attributes: [
                            .attribute(name: "identifier", type: .stringAttributeType),
                            .attribute(name: "dateCreated", type: .dateAttributeType),
                            .attribute(name: "expiryInterval", type: .doubleAttributeType, isOptional: true),
                            .attribute(name: "originalURL", type: .URIAttributeType),
                            .attribute(name: "fileName", type: .stringAttributeType),
                            .attribute(name: "fileExtension", type: .stringAttributeType, isOptional: true),
                            .attribute(name: "urlResponse", type: .binaryDataAttributeType, isOptional: true)
                          ],
                          indexes: [
                            .index(name: "byIdentifier", elements: [ .property(name: "identifier") ]),
                            .index(name: "byDateCreated", elements: [ .property(name: "dateCreated") ])
                          ])
        )

        var databaseConfiguration: Database.Configuration {
            Database.Configuration(name: name, directoryURL: directoryURL)
        }

        var filesDirectoryURL: URL {
            directoryURL.appendingPathComponent(filesDirectoryName)
        }
    }

    public let configuration: Configuration

    public init(configuration: Configuration) {
        self.configuration = configuration

        print("FileIndex directory: \(configuration.directoryURL.path)")

        // Create directories if necessary. Directory must be created before initializing index or adding files.
        try? FileManager.default.createDirectory(at: configuration.filesDirectoryURL, withIntermediateDirectories: true, attributes: nil)

        database = PlainDatabase(configuration: configuration.databaseConfiguration, modelDescription: configuration.modelDescription)
    }

    public func location(of file: File) -> URL {
        var location = configuration.filesDirectoryURL.appendingPathComponent(file.fileName)

        if let fileExtension = file.fileExtension {
            location.appendPathExtension(fileExtension)
        }

        return location
    }
    
    // MARK: - Actions

    /// Copy downloaded file to index directory and record it in the database
    @discardableResult
    public func copy(_ sourceLocation: URL, originalURL: URL, identifier: String? = nil, expireAfter expiryInterval: TimeInterval? = nil) throws -> File {
        let id = identifier ?? UUID().uuidString
        let fileName = id
        let fileExtension = originalURL.pathExtension

        let file = File(id: id, dateCreated: Date(), expiryInterval: expiryInterval, originalURL: originalURL, fileName: fileName, fileExtension: fileExtension, urlResponse: nil)

        try FileManager.default.copyItem(at: sourceLocation, to: location(of: file))
        database.create(file)

        return file
    }

    /// Write data to a file in index directory and record it in the database
    @discardableResult
    public func write(_ data: Data, originalURL: URL, identifier: String? = nil, urlResponse: URLResponse? = nil, expireAfter expiryInterval: TimeInterval? = nil) throws -> File {
        let id = identifier ?? UUID().uuidString
        let fileName = id
        let fileExtension = originalURL.pathExtension

        let file = File(id: id, dateCreated: Date(), expiryInterval: expiryInterval, originalURL: originalURL, fileName: fileName, fileExtension: fileExtension, urlResponse: urlResponse)

        try data.write(to: location(of: file))
        database.create(file)

        return file
    }

    public func get(_ originalURL: URL) -> [File] {
        let predicate = database.predicate(key: "originalURL", operator: .equalTo, value: originalURL.absoluteString, stringOptions: .caseInsensitive)
        return get(predicate)
    }

    public func get(_ identifier: String) -> [File] {
        let predicate = database.predicate(key: "identifier", operator: .equalTo, value: identifier, stringOptions: [])
        return get(predicate)
    }

    public func delete(_ file: File) {
        database.delete(where: "identifier", is: .equalTo, value: file.id)

        do {
            try FileManager.default.removeItem(at: location(of: file))
        }
        catch {
            print(error)
        }
    }

    // MARK: - Private

    private let database: PlainDatabase<File>

    private func get(_ predicate: NSPredicate) -> [File] {
        let request = database.request(with: predicate)

        return database.sync { context in
            let objects = try context.fetch(request)
            var result: [NSManagedObject] = []

            for object in objects {
                guard let file = File(managedObject: object) else {
                    continue
                }

                guard let expiryInterval = file.expiryInterval,
                   file.dateCreated.addingTimeInterval(expiryInterval) < Date() else {
                    result.append(object)
                    continue
                }

                // Delete
                context.delete(object)

                do {
                    try FileManager.default.removeItem(at: location(of: file))
                }
                catch {
                    print(error)
                }
            }

            return result
        }
    }
}