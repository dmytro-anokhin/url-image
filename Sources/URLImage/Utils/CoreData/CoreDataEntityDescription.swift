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

    static func entity(name: String,
                              managedObjectClass: NSManagedObject.Type = NSManagedObject.self,
                              parentEntity: String? = nil,
                              attributes: [CoreDataAttributeDescription] = [],
                              indexes: [CoreDataFetchIndexDescription] = []) -> CoreDataEntityDescription {
        CoreDataEntityDescription(name: name, managedObjectClassName: NSStringFromClass(managedObjectClass), parentEntity: parentEntity, attributes: attributes, indexes: indexes)
    }

    var name: String

    var managedObjectClassName: String

    var parentEntity: String?

    var attributes: [CoreDataAttributeDescription]

    var indexes: [CoreDataFetchIndexDescription]
}
