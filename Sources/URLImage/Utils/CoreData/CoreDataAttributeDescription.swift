//
//  CoreDataModelDescription.swift
//  URLImage
//
//  Created by Dmytro Anokhin on 02/08/2019.
//  Copyright © 2019 Dmytro Anokhin. All rights reserved.
//

import CoreData


/// Used to create `NSAttributeDescription`
struct CoreDataAttributeDescription {

    static func attribute(name: String, type: NSAttributeType, isOptional: Bool = false) -> CoreDataAttributeDescription {
        CoreDataAttributeDescription(name: name, attributeType: type, isOptional: isOptional)
    }

    var name: String

    var attributeType: NSAttributeType

    var isOptional: Bool

    func makeAttribute() -> NSAttributeDescription {
        let attribute = NSAttributeDescription()
        attribute.name = name
        attribute.attributeType = attributeType
        attribute.isOptional = isOptional

        return attribute
    }
}
