//
//  PlainDatabaseTests.swift
//
//
//  Created by Dmytro Anokhin on 08/09/2020.
//

import XCTest
import CoreData
@testable import PlainDatabase


@available(iOS 14.0, tvOS 14.0, macOS 11.0, watchOS 6.0, *)
final class PlainDatabaseTests: XCTestCase {

    override func setUp() {
        super.setUp()

        try? FileManager.default.createDirectory(at: databaseDirectoryURL, withIntermediateDirectories: false, attributes: nil)
        database = PlainDatabase<TestObject>(configuration: configuration, modelDescription: TestObject.modelDescription)
    }

    override func tearDown() {
        database = nil
        try? FileManager.default.removeItem(at: databaseDirectoryURL)

        super.tearDown()
    }

    func testCRUD() {
        var testObject = TestObject(string: "foo", date: Date(), number: 42)

        database.create(testObject)
        XCTAssertEqual(testObject, database.read(where: "uuid", is: .equalTo, value: testObject.uuid).first)

        let expectation = self.expectation(description: "Read Async")
        database.read(where: "uuid", is: .equalTo, value: testObject.uuid) { objects in
            XCTAssertEqual(testObject, objects.first)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 0.1)

        testObject.string = "bar"
        database.update(testObject, where: "uuid", is: .equalTo, value: testObject.uuid)
        XCTAssertEqual(testObject, database.read(where: "uuid", is: .equalTo, value: testObject.uuid).first)

        database.delete(where: "uuid", is: .equalTo, value: testObject.uuid)
        XCTAssertTrue(database.read(where: "uuid", is: .equalTo, value: testObject.uuid).isEmpty)
    }

    func testPredicate() {
        let testObject = TestObject(string: "foo", date: Date(), number: 42)
        database.create(testObject)

        XCTAssertEqual(testObject, database.read(where: "number", is: .lessThan, value: 43).first)
        XCTAssertEqual(testObject, database.read(where: "number", is: .lessThanOrEqualTo, value: 42).first)
        XCTAssertEqual(testObject, database.read(where: "number", is: .greaterThan, value: 41).first)
        XCTAssertEqual(testObject, database.read(where: "number", is: .greaterThanOrEqualTo, value: 42).first)
        XCTAssertEqual(testObject, database.read(where: "number", is: .notEqualTo, value: 0).first)

        XCTAssertEqual(testObject, database.read(where: "string", is: .like, value: "f*").first)
    }

    func testStringComparison() {
        let testObject = TestObject(string: "fóó", date: Date(), number: 42)
        database.create(testObject)

        XCTAssertEqual(testObject, database.read(where: "string", is: .like, value: "FOO", stringOptions: [ .caseInsensitive, .diacriticInsensitive]).first)
    }

    func testURLComparison() {
        let testObject = TestObject(string: "foo", date: Date(), number: 42, url: URL(string: "http://foo.bar/baz?quz=42")!)
        database.create(testObject)

        XCTAssertEqual(testObject, database.read(where: "url", is: .equalTo, value: URL(string: "http://foo.bar/baz?quz=42")!).first)
        XCTAssertEqual(testObject, database.read(where: "url", is: .like, value: URL(string: "http://foo.bar/*")!).first)
    }

    // MARK: - Private

    private struct TestObject : Equatable, ManagedObjectCodable {

        static let modelDescription = CoreDataModelDescription(
            entity: .init(name: "TestObject",
                          managedObjectClass: NSManagedObject.self,
                          attributes: [
                            .attribute(name: "uuid", type: .UUIDAttributeType),
                            .attribute(name: "string", type: .stringAttributeType),
                            .attribute(name: "date", type: .dateAttributeType),
                            .attribute(name: "number", type: .integer64AttributeType),
                            .attribute(name: "url", type: .URIAttributeType, isOptional: true)
                          ],
                          indexes: [
                            .index(name: "byUUID", elements: [ .property(name: "uuid") ])
                          ])
        )

        var uuid: UUID

        var string: String

        var date: Date

        var number: Int

        var url: URL?

        init(uuid: UUID = UUID(), string: String, date: Date, number: Int, url: URL? = nil) {
            self.uuid = uuid
            self.string = string
            self.date = date
            self.number = number
            self.url = url
        }

        init?(managedObject: NSManagedObject) {
            guard let uuid = managedObject.value(forKey: "uuid") as? UUID,
                  let string = managedObject.value(forKey: "string") as? String,
                  let date = managedObject.value(forKey: "date") as? Date,
                  let number = managedObject.value(forKey: "number") as? Int
            else {
                return nil
            }

            self.uuid = uuid
            self.string = string
            self.date = date
            self.number = number
            self.url = managedObject.value(forKey: "url") as? URL
        }

        func encode(to object: NSManagedObject) {
            object.setValue(uuid, forKey: "uuid")
            object.setValue(string, forKey: "string")
            object.setValue(date, forKey: "date")
            object.setValue(number, forKey: "number")
            object.setValue(url, forKey: "url")
        }
    }

    private let databaseDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        .appendingPathComponent("PlainDatabaseTests", isDirectory: true)

    private var configuration: Database.Configuration {
        Database.Configuration(name: "PlainDatabaseTests", directoryURL: databaseDirectoryURL)
    }

    private var database: PlainDatabase<TestObject>!
}
