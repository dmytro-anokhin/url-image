//
//  CoreDataFetchIndexDescription.swift
//  
//
//  Created by Dmytro Anokhin on 08/09/2020.
//

import CoreData


/// Describes `NSFetchIndexDescription`
@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
public struct CoreDataFetchIndexDescription {

    /// Describes `NSFetchIndexElementDescription`
    public struct Element {

        public enum Property {

            case property(name: String)
        }

        public static func property(name: String, type: NSFetchIndexElementType = .binary, ascending: Bool = true) -> Element {
            Element(property: .property(name: name), type: type, ascending: ascending)
        }

        public var property: Property

        public var type: NSFetchIndexElementType

        public var ascending: Bool
    }

    public static func index(name: String, elements: [Element]) -> CoreDataFetchIndexDescription {
        CoreDataFetchIndexDescription(name: name, elements: elements)
    }

    public var name: String

    public var elements: [Element]
}
