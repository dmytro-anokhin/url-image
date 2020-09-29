//
//  ManagedObjectCodable.swift
//  
//
//  Created by Dmytro Anokhin on 08/09/2020.
//

import CoreData


public typealias ManagedObjectCodable = ManagedObjectDecodable & ManagedObjectEncodable


public protocol ManagedObjectDecodable {

    init?(managedObject: NSManagedObject)
}


public protocol ManagedObjectEncodable {

    func encode(to: NSManagedObject)
}
