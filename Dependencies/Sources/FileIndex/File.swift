//
//  File.swift
//  
//
//  Created by Dmytro Anokhin on 09/09/2020.
//

import Foundation
import CoreData

#if canImport(PlainDatabase)
import PlainDatabase
#endif


@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public struct File : Identifiable {

    public var id: String

    public var dateCreated: Date

    /// `nil` stands for never expire
    public var expiryInterval: TimeInterval?

    public var originalURL: URL

    public var fileName: String

    public var fileExtension: String?

    public init(id: String, dateCreated: Date, expiryInterval: TimeInterval?, originalURL: URL, fileName: String, fileExtension: String?) {
        self.id = id
        self.dateCreated = dateCreated
        self.expiryInterval = expiryInterval
        self.originalURL = originalURL
        self.fileName = fileName
        self.fileExtension = fileExtension
    }
}


@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension File : Equatable {

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
            && lhs.dateCreated == rhs.dateCreated
            && lhs.expiryInterval == rhs.expiryInterval
            && lhs.originalURL == rhs.originalURL
            && lhs.fileName == rhs.fileName
            && lhs.fileExtension == rhs.fileExtension
    }
}


@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension File : ManagedObjectCodable {

    public init?(managedObject: NSManagedObject) {
        guard let id = managedObject.value(forKey: "identifier") as? String,
              let dateCreated = managedObject.value(forKey: "dateCreated") as? Date,
              let originalURL = managedObject.value(forKey: "originalURL") as? URL,
              let fileName = managedObject.value(forKey: "fileName") as? String
        else {
            return nil
        }

        let expiryInterval = managedObject.value(forKey: "expiryInterval") as? TimeInterval
        let fileExtension = managedObject.value(forKey: "fileExtension") as? String

        self.init(id: id, dateCreated: dateCreated, expiryInterval: expiryInterval, originalURL: originalURL, fileName: fileName, fileExtension: fileExtension)
    }

    public func encode(to object: NSManagedObject) {
        object.setValue(id, forKey: "identifier")
        object.setValue(dateCreated, forKey: "dateCreated")
        object.setValue(expiryInterval, forKey: "expiryInterval")
        object.setValue(originalURL, forKey: "originalURL")
        object.setValue(fileName, forKey: "fileName")
        object.setValue(fileExtension, forKey: "fileExtension")

        if let expiryInterval = expiryInterval {
            let expiryDate = dateCreated.addingTimeInterval(expiryInterval)
            object.setValue(expiryDate, forKey: "expiryDate")
        }
    }
}
