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

    let name: String

    let attributeType: NSAttributeType

    let indexed: Bool

    private init(name: String, attributeType: NSAttributeType, indexed: Bool) {
        self.name = name
        self.attributeType = attributeType
        self.indexed = indexed
    }

    static func attribute(name: String, type: NSAttributeType, indexed: Bool = false) -> CoreDataAttributeDescription {
        return CoreDataAttributeDescription(name: name, attributeType: type, indexed: indexed)
    }

    func makeAttribute() -> NSAttributeDescription {
        let attribute = NSAttributeDescription()
        attribute.name = name
        attribute.attributeType = attributeType
        attribute.isIndexed = indexed

        return attribute
    }
}
