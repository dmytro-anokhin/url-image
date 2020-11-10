//
//  FileIndex.swift
//  
//
//  Created by Dmytro Anokhin on 11/09/2020.
//

import Foundation
import CoreData

#if canImport(PlainDatabase)
import PlainDatabase
#endif

#if canImport(Log)
import Log
#endif

#if canImport(Common)
import Common
#endif


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

        public var filesDirectoryURL: URL {
            directoryURL.appendingPathComponent(filesDirectoryName)
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
                            .attribute(name: "expiryDate", type: .dateAttributeType, isOptional: true)
                          ],
                          indexes: [
                            .index(name: "byIdentifier", elements: [ .property(name: "identifier") ]),
                            .index(name: "byOriginalURL", elements: [ .property(name: "originalURL") ]),
                            .index(name: "byExpiryDate", elements: [ .property(name: "expiryDate") ])
                          ])
        )

        var databaseConfiguration: Database.Configuration {
            Database.Configuration(name: name, directoryURL: directoryURL)
        }
    }

    public let configuration: Configuration

    public init(configuration: Configuration) {
        defer {
            log_debug(self, #function, "FileIndex path: \(configuration.directoryURL.path)")
        }

        self.configuration = configuration

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

    /// Move downloaded file to index directory and record it in the database
    @discardableResult
    public func move(_ sourceLocation: URL,
                     originalURL: URL,
                     identifier: String? = nil,
                     fileName: String? = nil,
                     fileExtension: String? = nil,
                     expireAfter expiryInterval: TimeInterval? = nil
    ) throws -> File {
        let id: String = .string(suggested: identifier, generator: UUID().uuidString)
        let fileName: String = .string(suggested: fileName, generator: UUID().uuidString)
        let fileExtension: String? = .string(suggested: fileExtension, generator: originalURL.pathExtension)

        let file = File(id: id,
                        dateCreated: Date(),
                        expiryInterval: expiryInterval,
                        originalURL: originalURL,
                        fileName: fileName,
                        fileExtension: fileExtension)

        try FileManager.default.moveItem(at: sourceLocation, to: location(of: file))
        database.create(file)

        return file
    }

    /// Write data to a file in index directory and record it in the database
    @discardableResult
    public func write(_ data: Data,
                      originalURL: URL,
                      identifier: String? = nil,
                      fileName: String? = nil,
                      fileExtension: String? = nil,
                      expireAfter expiryInterval: TimeInterval? = nil
    ) throws -> File {
        let id: String = .string(suggested: identifier, generator: UUID().uuidString)
        let fileName: String = .string(suggested: fileName, generator: UUID().uuidString)
        let fileExtension: String? = .string(suggested: fileExtension, generator: originalURL.pathExtension)

        let file = File(id: id,
                        dateCreated: Date(),
                        expiryInterval: expiryInterval,
                        originalURL: originalURL,
                        fileName: fileName,
                        fileExtension: fileExtension)

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

    public func deleteAll(_ completion: (() -> Void)? = nil) {
        let request = database.request()
        delete(request: request, completion)
    }

    public func deleteExpired(_ completion: (() -> Void)? = nil) {
        let predicate = database.predicate(key: "expiryDate", operator: .lessThan, value: Date(), stringOptions: .caseInsensitive)
        let request = database.request(with: predicate)
        delete(request: request, completion)
    }

    private func delete(request: NSFetchRequest<NSManagedObject>, _ completion: (() -> Void)? = nil) {
        database.sync { context -> Void in
            let objects = try context.fetch(request)

            for object in objects {
                guard let file = File(managedObject: object) else {
                    continue
                }

                context.delete(object)

                do {
                    try FileManager.default.removeItem(at: self.location(of: file))
                }
                catch {
                    print(error)
                }
            }

            if context.hasChanges {
                try context.save()
            }

            completion?()
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

                let location = self.location(of: file)

                guard FileManager.default.fileExists(atPath: location.path) else {
                    // File was deleted from disk, need to also delete it from the database
                    context.delete(object)
                    continue
                }

                result.append(object)
            }

            if context.hasChanges {
                try context.save()
            }

            return result
        }
    }
}


private extension String {

    /// Returns suggested string if not nil or empty, otherwise returns generator result.
    static func string(suggested: String?, generator: @autoclosure () -> String) -> String {
        if let suggested = suggested, !suggested.isEmpty {
            return suggested
        }

        return generator()
    }
}

private extension Optional where Wrapped == String {

    /// Returns suggested string if not nil or empty, otherwise returns generator result.
    static func string(suggested: String?, generator: @autoclosure () -> String?) -> String? {
        if let suggested = suggested, !suggested.isEmpty {
            return suggested
        }

        return generator()
    }
}
