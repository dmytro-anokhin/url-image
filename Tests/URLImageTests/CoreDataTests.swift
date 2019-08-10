//
//  CoreDataTests.swift
//  URLImageTests
//
//  Created by Dmytro Anokhin on 02/08/2019.
//  Copyright © 2019 Dmytro Anokhin. All rights reserved.
//

import XCTest
import CoreData

@testable import URLImage


@objc(Image)
public class Image: NSManagedObject {

    static let entityName = "Image"

    @NSManaged public var originalURLString: String?

    @NSManaged public var dateCreated: Date?

    @NSManaged public var localURLString: String?
}


@available(iOS 13.0, *)
final class CoreDataTests: XCTestCase {

    static var allTests = [
        ("testSaveLoad", testSaveLoad),
    ]

    func testSaveLoad() throws {

        // Create and load Core Data stack
        let persistentContainer = makePersistentContainer(CoreDataModelDescription(
            entities: [
                .entity(name: Image.entityName, managedObjectClass: Image.self, attributes: [
                    .attribute(name: "originalURLString", type: .stringAttributeType),
                    .attribute(name: "localURLString", type: .stringAttributeType),
                    .attribute(name: "dateCreated", type: .dateAttributeType)
                ])
            ]))

        // Test data
        let originalURLString = "scheme://path/image.png"
        let localURLString = "file:///dev/null/image.png"
        let dateCreated = Date()

        // Build initial managed object
        let imageObject = Image(context: persistentContainer.viewContext)
        imageObject.originalURLString = originalURLString
        imageObject.localURLString = localURLString
        imageObject.dateCreated = dateCreated

        try persistentContainer.viewContext.save()

        // Object saved successfully, load in background
        let fetchInBackgroundExpectation = self.expectation(description: "Data can be fetched in a background context")

        let backgroundContext = persistentContainer.newBackgroundContext()
        backgroundContext.perform {
            let request = NSFetchRequest<Image>(entityName: Image.entityName)

            do {
                let fetchedImageObjects = try backgroundContext.fetch(request)

                // Validate

                XCTAssertEqual(fetchedImageObjects.count, 1)

                for fetchedImageObject in fetchedImageObjects {
                    XCTAssertEqual(fetchedImageObject.originalURLString, originalURLString)
                    XCTAssertEqual(fetchedImageObject.localURLString, localURLString)
                    XCTAssertEqual(fetchedImageObject.dateCreated, dateCreated)
                }

                fetchInBackgroundExpectation.fulfill()
            }
            catch {
                XCTFail("Failed to fetch objects with error \(error)")
            }
        }

        self.wait(for: [fetchInBackgroundExpectation], timeout: 0.1)
    }

    private func makePersistentContainer(_ modelDescription: CoreDataModelDescription) -> NSPersistentContainer {
        let model = modelDescription.makeModel()

        let persistentContainer = NSPersistentContainer(name: "URLImageTests", managedObjectModel: model)

        let persistentStoreDescription = NSPersistentStoreDescription()
        persistentStoreDescription.type = NSInMemoryStoreType
        persistentContainer.persistentStoreDescriptions = [persistentStoreDescription]

        let loadPersistentStoresExpectation = expectation(description: "Persistent container expected to load the store")

        persistentContainer.loadPersistentStores { description, error in
            XCTAssertNil(error)
            loadPersistentStoresExpectation.fulfill()
        }

        wait(for: [loadPersistentStoresExpectation], timeout: 0.1)

        return persistentContainer
    }
}
