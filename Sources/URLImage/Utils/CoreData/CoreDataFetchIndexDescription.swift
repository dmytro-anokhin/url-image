//
//  CoreDataFetchIndexDescription.swift
//  URLImage
//
//  Created by Dmytro Anokhin on 23/10/2019.
//  Copyright © 2019 Dmytro Anokhin. All rights reserved.
//

import CoreData


/// Describes `NSFetchIndexDescription`
@available(iOS 11.0, tvOS 11.0, macOS 10.13, watchOS 4.0, *)
struct CoreDataFetchIndexDescription {

    /// Describes `NSFetchIndexElementDescription`
    struct Element {

        enum Property {

            case property(name: String)
        }

        static func property(name: String, type: NSFetchIndexElementType = .binary, ascending: Bool = true) -> Element {
            Element(property: .property(name: name), type: type, ascending: ascending)
        }

        var property: Property

        var type: NSFetchIndexElementType

        var ascending: Bool
    }

    static func index(name: String, elements: [Element]) -> CoreDataFetchIndexDescription {
        CoreDataFetchIndexDescription(name: name, elements: elements)
    }

    var name: String

    var elements: [Element]
}
