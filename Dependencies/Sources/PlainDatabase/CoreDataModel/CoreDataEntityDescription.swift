//
//  CoreDataEntityDescription.swift
//  
//
//  Created by Dmytro Anokhin on 08/09/2020.
//

import CoreData


/// Used to create `NSEntityDescription`
@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
public struct CoreDataEntityDescription<ManagedObject: NSManagedObject> {

    public init(name: String, managedObjectClassName: String, attributes: [CoreDataAttributeDescription], indexes: [CoreDataFetchIndexDescription]) {
        self.name = name
        self.managedObjectClassName = managedObjectClassName
        self.attributes = attributes
        self.indexes = indexes
    }

    public init(name: String, managedObjectClass: ManagedObject.Type, attributes: [CoreDataAttributeDescription], indexes: [CoreDataFetchIndexDescription]) {
        self.init(name: name, managedObjectClassName: NSStringFromClass(managedObjectClass), attributes: attributes, indexes: indexes)
    }

    public var name: String

    public var managedObjectClassName: String

    public var attributes: [CoreDataAttributeDescription]

    public var indexes: [CoreDataFetchIndexDescription]
}
