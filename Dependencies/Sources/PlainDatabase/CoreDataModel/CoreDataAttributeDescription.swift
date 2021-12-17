//
//  CoreDataAttributeDescription.swift
//  
//
//  Created by Dmytro Anokhin on 08/09/2020.
//

import CoreData


/// Used to create `NSAttributeDescription`
@available(iOS 14.0, tvOS 14.0, macOS 11.0, watchOS 7.0, *)
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
