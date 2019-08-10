//
//  CoreDataEntityDescription.swift
//  URLImage
//
//  Created by Dmytro Anokhin on 02/08/2019.
//  Copyright © 2019 Dmytro Anokhin. All rights reserved.
//

import CoreData


/// Used to create `NSEntityDescription`
struct CoreDataEntityDescription {

    let name: String

    let managedObjectClassName: String

    let attributes: [CoreDataAttributeDescription]

    /// Use `entity` factory function to create `CoreDataEntityDescription` object because it uses `NSManagedObject.Type` for `managedObjectClass` argument.
    private init(name: String, managedObjectClassName: String, attributes: [CoreDataAttributeDescription]) {
        self.name = name
        self.managedObjectClassName = managedObjectClassName
        self.attributes = attributes
    }

    static func entity(name: String, managedObjectClass: NSManagedObject.Type, attributes: [CoreDataAttributeDescription]) -> CoreDataEntityDescription {
        return CoreDataEntityDescription(name: name, managedObjectClassName: NSStringFromClass(managedObjectClass), attributes: attributes)
    }

    func makeEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = name
        entity.managedObjectClassName = managedObjectClassName
        entity.properties = attributes.map { $0.makeAttribute() }

        return entity
    }
}
