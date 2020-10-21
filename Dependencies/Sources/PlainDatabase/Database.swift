//
//  Database.swift
//  
//
//  Created by Dmytro Anokhin on 08/09/2020.
//

import Foundation
import CoreData


@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
public final class Database {

    public struct Configuration {

        public var name: String

        public var directoryURL: URL

        public var fileExtension: String

        public init(name: String, directoryURL: URL, fileExtension: String = "db") {
            self.name = name
            self.directoryURL = directoryURL
            self.fileExtension = fileExtension
        }
    }

    public static let fileExtension = "db"

    // <Application_Home>/Library/Caches/<name>.db
    public init(configuration: Configuration, model: NSManagedObjectModel) {

        let storeDescription = NSPersistentStoreDescription()
        storeDescription.url = configuration.directoryURL
            .appendingPathComponent(configuration.name, isDirectory: false)
            .appendingPathExtension(configuration.fileExtension)

        container = NSPersistentContainer(name: configuration.name, managedObjectModel: model)
        container.persistentStoreDescriptions = [storeDescription]
        container.load()

        context = container.newBackgroundContext()
        context.undoManager = nil
    }

    public func async(_ closure: @escaping (_ context: NSManagedObjectContext) throws -> Void) {
        context.perform { [unowned self] in
            do {
                try closure(self.context)
            }
            catch {
                print(error)
            }
        }
    }

    public func sync(_ closure: (_ context: NSManagedObjectContext) throws -> Void) {
        context.performAndWait { [unowned self] in
            do {
                try closure(self.context)
            }
            catch {
                print(error)
            }
        }
    }

    @discardableResult
    public func sync<T>(_ closure: (_ context: NSManagedObjectContext) throws -> T) throws -> T {
        var result: Result<T, Error>? = nil

        context.performAndWait { [unowned self] in
            do {
                result = .success(try closure(self.context))
            }
            catch {
                result = .failure(error)
            }
        }

        switch result! {
            case .success(let value):
                return value
            case .failure(let error):
                throw error
        }
    }

    private let container: NSPersistentContainer

    private let context: NSManagedObjectContext
}


@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
fileprivate extension NSPersistentContainer {

    func load() {
        let semaphore = DispatchSemaphore(value: 1)

        loadPersistentStores { result, error in
            semaphore.signal()
        }

        semaphore.wait()
    }
}
