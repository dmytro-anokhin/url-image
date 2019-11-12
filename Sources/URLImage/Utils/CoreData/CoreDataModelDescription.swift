//
//  CoreDataModelDescription.swift
//  URLImage
//
//  Created by Dmytro Anokhin on 02/08/2019.
//  Copyright © 2019 Dmytro Anokhin. All rights reserved.
//

import CoreData


/// Used to create `NSManagedObjectModel`
@available(iOS 11.0, tvOS 11.0, macOS 10.13, watchOS 4.0, *)
struct CoreDataModelDescription {

    var entities: [CoreDataEntityDescription]

    init(entities: [CoreDataEntityDescription]) {
        self.entities = entities
    }

    func makeModel() -> NSManagedObjectModel {

        // For convenience: the package objects use "Description" suffix, Core Data objects have no suffix.
        let entitiesDescriptions = self.entities
        let entities: [NSEntityDescription]

        // Model creation has next steps:
        // - Create entities and their attributes. Entities are mapped to their names for faster lookup.
        // - Last step builds indexes. This must be done in the last step because changing entities hierarchy structurally drops indexes.

        // First step
        var entityNameToEntity: [String: NSEntityDescription] = [:]
        var entityNameToPropertyNameToProperty: [String: [String: NSPropertyDescription]] = [:]

        for entityDescription in entitiesDescriptions {
            let entity = NSEntityDescription()
            entity.name = entityDescription.name
            entity.managedObjectClassName = entityDescription.managedObjectClassName

            var propertyNameToProperty: [String: NSPropertyDescription] = [:]

            for attributeDescription in entityDescription.attributes {
                let attribute = attributeDescription.makeAttribute()
                propertyNameToProperty[attribute.name] = attribute
            }

            entity.properties = Array(propertyNameToProperty.values)

            // Map the entity to its name
            entityNameToEntity[entityDescription.name] = entity

            // Map properties
            entityNameToPropertyNameToProperty[entityDescription.name] = propertyNameToProperty
        }

        entities = Array(entityNameToEntity.values)

        // Last step, build indexes
        for entityDescription in entitiesDescriptions {
            let entity = entityNameToEntity[entityDescription.name]!
            let propertyNameToProperty = entityNameToPropertyNameToProperty[entityDescription.name] ?? [:]

            entity.indexes = entityDescription.indexes.map { indexDescription in
                let elements: [NSFetchIndexElementDescription] = indexDescription.elements.compactMap { elementDescription in
                    switch elementDescription.property {
                        case .property(let name):
                            guard let property = propertyNameToProperty[name] else {
                                assertionFailure("Can not find attribute, fetched property, or relationship with name: \(name).")
                                return nil
                            }

                            return NSFetchIndexElementDescription(property: property, collationType: elementDescription.type)
                    }
                }

                return NSFetchIndexDescription(name: indexDescription.name, elements: elements)
            }
        }

        // Create model

        let model = NSManagedObjectModel()
        model.entities = entities

        return model
    }
}
