//
//  CoreDataAttributeDescription.swift
//  
//
//  Created by Dmytro Anokhin on 08/09/2020.
//

import CoreData


/// Used to create `NSAttributeDescription`
@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
public struct CoreDataAttributeDescription {

    public static func attribute(name: String, type: NSAttributeType, isOptional: Bool = false) -> CoreDataAttributeDescription {
        CoreDataAttributeDescription(name: name, attributeType: type, isOptional: isOptional)
    }

    public var name: String

    public var attributeType: NSAttributeType

    public var isOptional: Bool

    func makeAttribute() -> NSAttributeDescription {
        let attribute = NSAttributeDescription()
        attribute.name = name
        attribute.attributeType = attributeType
        attribute.isOptional = isOptional

        return attribute
    }
}
