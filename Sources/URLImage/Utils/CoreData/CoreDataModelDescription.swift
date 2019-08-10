//
//  CoreDataModelDescription.swift
//  URLImage
//
//  Created by Dmytro Anokhin on 02/08/2019.
//  Copyright © 2019 Dmytro Anokhin. All rights reserved.
//

import CoreData


/// Used to create `NSManagedObjectModel`
struct CoreDataModelDescription {

    var entities: [CoreDataEntityDescription]

    func makeModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()
        model.entities = entities.map { $0.makeEntity() }

        return model
    }
}
