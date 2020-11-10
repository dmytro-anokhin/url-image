//
//  PlainDatabase.swift
//
//
//  Created by Dmytro Anokhin on 08/09/2020.
//

import Foundation
import CoreData


@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
public typealias PlainDatabaseObject = ManagedObjectCodable


public enum PredicateOperator {

    case lessThan

    case lessThanOrEqualTo

    case greaterThan

    case greaterThanOrEqualTo

    case equalTo

    case notEqualTo

    // case matches

    case like

    // case beginsWith = 8

    // case endsWith = 9

    // case `in`

    // case customSelector

    //@available(macOS 10.5, *)
    // case contains

    //@available(macOS 10.5, *)
    //case between = 100

    var nsComparisonPredicateOperator: NSComparisonPredicate.Operator {
        switch self {
            case .lessThan:
                return .lessThan
            case .lessThanOrEqualTo:
                return .lessThanOrEqualTo
            case .greaterThan:
                return .greaterThan
            case .greaterThanOrEqualTo:
                return .greaterThanOrEqualTo
            case .equalTo:
                return .equalTo
            case .notEqualTo:
                return .notEqualTo
            case .like:
                return .like
        }
    }
}


/**
    A database that stores a plain list of same type objects.
 */
@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
public final class PlainDatabase<Object: PlainDatabaseObject> {

    public init<T: NSManagedObject>(configuration: Database.Configuration, modelDescription: CoreDataModelDescription<T>) {
        database = Database(configuration: configuration, model: modelDescription.model)
        self.entityName = modelDescription.entity.name
    }

    // MARK: - Create

    public func create(_ encodable: Object) {
        database.async { context in
            let object = NSEntityDescription.insertNewObject(forEntityName: self.entityName, into: context)
            encodable.encode(to: object)

            try context.save()
        }
    }

    // MARK: - Read

    /// Synchronous
    public func read<T>(where key: String, is operator: PredicateOperator, value: T, stringOptions: NSComparisonPredicate.Options = []) -> [Object] {
        let predicate = self.predicate(key: key, operator: `operator`, value: value, stringOptions: stringOptions)
        return read(where: predicate)
    }

    private func read(where predicate: NSPredicate) -> [Object] {
        do {
            return try database.sync { context in
                let request = self.request(with: predicate)
                let objects = try context.fetch(request)

                return objects.compactMap {
                    Object(managedObject: $0)
                }
            }
        }
        catch {
            print(error)
            return []
        }
    }

    /// Asynchronous
    public func read<T>(where key: String, is operator: PredicateOperator, value: T, stringOptions: NSComparisonPredicate.Options = [], completion: @escaping (_ objects: [Object]) -> Void) {
        let predicate = self.predicate(key: key, operator: `operator`, value: value, stringOptions: stringOptions)
        read(where: predicate, completion: completion)
    }

    private func read(where predicate: NSPredicate, completion: @escaping (_ objects: [Object]) -> Void) {
        let request = self.request(with: predicate)

        database.async { context in
            let objects = try context.fetch(request)
            let result = objects.compactMap {
                Object(managedObject: $0)
            }

            completion(result)
        }
    }

    // MARK: - Update

    public func update<T>(_ encodable: Object, where key: String, is operator: PredicateOperator, value: T, stringOptions: NSComparisonPredicate.Options = []) {
        let predicate = self.predicate(key: key, operator: `operator`, value: value, stringOptions: stringOptions)
        update(encodable, where: predicate)
    }

    private func update(_ encodable: Object, where predicate: NSPredicate) {
        database.async { context in
            let request = self.request(with: predicate)
            let objects = try context.fetch(request)

            for object in objects {
                encodable.encode(to: object)
            }

            try context.save()
        }
    }

    // MARK: - Delete

    public func delete<T>(where key: String, is operator: PredicateOperator, value: T, stringOptions: NSComparisonPredicate.Options = []) {
        let predicate = self.predicate(key: key, operator: `operator`, value: value, stringOptions: stringOptions)
        delete(where: predicate)
    }

    private func delete(where predicate: NSPredicate) {
        database.async { context in
            let request = self.request(with: predicate)
            let objects = try context.fetch(request)

            for object in objects {
                context.delete(object)
            }

            try context.save()
        }
    }

    // MARK: - Custom

    public func sync(_ closure: (_ context: NSManagedObjectContext) throws -> [NSManagedObject]) -> [Object] {

        if Thread.isMainThread {
            print("Sync database access on the main thread")
        }

        do {
            return try database.sync { context in
                try closure(context).compactMap {
                    Object(managedObject: $0)
                }
            }
        }
        catch {
            print(error)
            return []
        }
    }

    public func sync(_ closure: @escaping (_ context: NSManagedObjectContext) throws -> Void) {
        database.sync { context in
            try closure(context)
        }
    }

    public func async(_ closure: @escaping (_ context: NSManagedObjectContext) throws -> Void) {
        database.async { context in
            do {
                try closure(context)
            }
            catch {
                print(error)
            }
        }
    }

    // MARK: - Utils

    public func predicate<T>(key: String, operator: PredicateOperator, value: T, stringOptions: NSComparisonPredicate.Options) -> NSPredicate {
        let lhs = NSExpression(forKeyPath: key)
        let rhs: NSExpression

        if let url = value as? URL, `operator` == .like {
            // Core Data doesn't implement SQL generation for comparison predicate that uses like and URL value
            rhs = NSExpression(forConstantValue: url.absoluteString)
        }
        else {
            rhs = NSExpression(forConstantValue: value)
        }

        return NSComparisonPredicate(leftExpression: lhs,
                                     rightExpression: rhs,
                                     modifier: .direct,
                                     type: `operator`.nsComparisonPredicateOperator,
                                     options: stringOptions)
    }

    public func request(with predicate: NSPredicate? = nil) -> NSFetchRequest<NSManagedObject> {
        let request = NSFetchRequest<NSManagedObject>(entityName: self.entityName)
        request.predicate = predicate

        return request
    }

    // MARK: - Private

    private let database: Database

    private let entityName: String
}
