//
//  FileIndexTests.swift
//  
//
//  Created by Dmytro Anokhin on 12/09/2020.
//

import Foundation
import XCTest
@testable import FileIndex


@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
final class FileIndexTests: XCTestCase {

    func testCopy() throws {
        let tmpLocation = makeTemporaryFile("This is a test")
        let originalURL = URL(string: "https://localhost")!

        // Copy file
        let file = try index.move(tmpLocation, originalURL: originalURL)
        XCTAssertTrue(FileManager.default.fileExists(atPath: index.location(of: file).path))
        XCTAssertEqual(try contentsOf(index.location(of: file)), "This is a test")

        // Get using original url
        let files1 = index.get(originalURL)
        XCTAssertEqual(files1.count, 1)
        XCTAssertEqual(files1.first, file)

        // Get using identifier
        let files2 = index.get(file.id)
        XCTAssertEqual(files2.count, 1)
        XCTAssertEqual(files2.first, file)

        // Delete file
        index.delete(file)
        let files3 = index.get(file.id)
        XCTAssertFalse(FileManager.default.fileExists(atPath: index.location(of: file).path))
        XCTAssertTrue(files3.isEmpty)
    }

    func testWrite() throws {
        let originalURL = URL(string: "https://localhost")!

        // Write file
        let file = try index.write("This is a test".data(using: .utf8)!, originalURL: originalURL)
        XCTAssertTrue(FileManager.default.fileExists(atPath: index.location(of: file).path))
        XCTAssertEqual(try contentsOf(file), "This is a test")

        // Get using original url
        let files1 = index.get(originalURL)
        XCTAssertEqual(files1.count, 1)
        XCTAssertEqual(files1.first, file)

        // Get using identifier
        let files2 = index.get(file.id)
        XCTAssertEqual(files2.count, 1)
        XCTAssertEqual(files2.first, file)

        // Delete file
        index.delete(file)
        let files3 = index.get(file.id)
        XCTAssertFalse(FileManager.default.fileExists(atPath: index.location(of: file).path))
        XCTAssertTrue(files3.isEmpty)
    }

    func testExpired() throws {
        let tmpLocation = makeTemporaryFile("This is a test")
        let originalURL = URL(string: "https://localhost")!

        // Copy file
        let file = try index.move(tmpLocation, originalURL: originalURL, expireAfter: 0.1)
        XCTAssertTrue(FileManager.default.fileExists(atPath: index.location(of: file).path))
        XCTAssertEqual(try contentsOf(file), "This is a test")

        // Time travel
        Thread.sleep(forTimeInterval: 0.1)

        // Expired file must still be there on access
        let files = index.get(originalURL)
        XCTAssertFalse(files.isEmpty)
        XCTAssertTrue(FileManager.default.fileExists(atPath: index.location(of: file).path))
    }

    func testNotExpired() throws {
        let tmpLocation = makeTemporaryFile("This is a test")
        let originalURL = URL(string: "https://localhost")!

        // Copy file
        let file = try index.move(tmpLocation, originalURL: originalURL, expireAfter: 1.0)
        XCTAssertTrue(FileManager.default.fileExists(atPath: index.location(of: file).path))
        XCTAssertEqual(try contentsOf(file), "This is a test")

        // Time travel
        Thread.sleep(forTimeInterval: 0.1)

        // File still exists
        let files = index.get(originalURL)
        XCTAssertEqual(files.count, 1)
        XCTAssertEqual(files.first, file)
        XCTAssertTrue(FileManager.default.fileExists(atPath: index.location(of: file).path))
    }

    func testFileInDatabaseButDeletedFromDisk() throws {
        let originalURL = URL(string: "https://localhost")!

        // Write file
        let file = try index.write("This is a test".data(using: .utf8)!, originalURL: originalURL)
        XCTAssertTrue(FileManager.default.fileExists(atPath: index.location(of: file).path))
        XCTAssertEqual(try contentsOf(file), "This is a test")

        // File must be in the index
        let files1 = index.get(originalURL)
        XCTAssertEqual(files1.count, 1)
        XCTAssertEqual(files1.first, file)

        // Delete file
        try FileManager.default.removeItem(at: index.location(of: file))

        // Result must be empty
        let files2 = index.get(originalURL)
        XCTAssertTrue(files2.isEmpty)
    }

    func testDeleteExpired() throws {
        let tmpLocation1 = makeTemporaryFile("This file expiring soon")
        let tmpLocation2 = makeTemporaryFile("This file expiring not so soon")
        let tmpLocation3 = makeTemporaryFile("This file won't expire")

        let originalURL = URL(string: "https://localhost")!

        let file1 = try index.move(tmpLocation1, originalURL: originalURL, expireAfter: 0.1)
        let file2 = try index.move(tmpLocation2, originalURL: originalURL, expireAfter: 1.0)
        let file3 = try index.move(tmpLocation3, originalURL: originalURL)

        // Files must be in the index
        let files1 = index.get(originalURL)
        XCTAssertEqual(files1.count, 3)

        for file in files1 {
            XCTAssertTrue(FileManager.default.fileExists(atPath: index.location(of: file).path))
        }

        // Time travel
        Thread.sleep(forTimeInterval: 0.1)

        // Delete is async
        let deleteExpiredExpectation = expectation(description: "Delete expired")

        index.deleteExpired {
            // First file expired
            XCTAssertFalse(FileManager.default.fileExists(atPath: self.index.location(of: file1).path))
            // Second and third must be in place
            XCTAssertTrue(FileManager.default.fileExists(atPath: self.index.location(of: file2).path))
            XCTAssertTrue(FileManager.default.fileExists(atPath: self.index.location(of: file3).path))

            // Index must contain only last two files
            let files2 = self.index.get(originalURL)
            XCTAssertEqual(files2.count, 2)
            XCTAssertEqual(files2, [file2, file3])

            deleteExpiredExpectation.fulfill()
        }

        waitForExpectations(timeout: 1.0)
    }

    func testDeleteAll() throws {
        let tmpLocation1 = makeTemporaryFile("This file expiring soon")
        let tmpLocation2 = makeTemporaryFile("This file expiring not so soon")
        let tmpLocation3 = makeTemporaryFile("This file won't expire")

        let originalURL = URL(string: "https://localhost")!

        let _ = try index.move(tmpLocation1, originalURL: originalURL)
        let _ = try index.move(tmpLocation2, originalURL: originalURL)
        let _ = try index.move(tmpLocation3, originalURL: originalURL)

        // Files must be in the index
        let files1 = index.get(originalURL)
        XCTAssertEqual(files1.count, 3)

        for file in files1 {
            XCTAssertTrue(FileManager.default.fileExists(atPath: index.location(of: file).path))
        }

        // Delete is async
        let deleteAllExpectation = expectation(description: "Delete all")

        index.deleteAll {
            // Files must be deleted
            for file in files1 {
                XCTAssertFalse(FileManager.default.fileExists(atPath: self.index.location(of: file).path))
            }

            // Index must be empty
            let files2 = self.index.get(originalURL)
            XCTAssertTrue(files2.isEmpty)

            deleteAllExpectation.fulfill()
        }

        waitForExpectations(timeout: 1.0)
    }

    private var index: FileIndex!

    override func setUp() {
        super.setUp()

        index = FileIndex(
            configuration: .init(
                name: "FileIndexTests",
                filesDirectoryName: "Files",
                baseDirectoryName: "FileIndexTests"
            ))
    }

    override func tearDown() {
        let directoryURL = index.configuration.directoryURL
        index = nil
        try? FileManager.default.removeItem(at: directoryURL)

        super.tearDown()
    }

    private func makeTemporaryFile(_ contents: String) -> URL {
        let location = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent(UUID().uuidString)
        try? contents.write(to: location, atomically: true, encoding: .utf8)

        return location
    }

    private func contentsOf(_ location: URL) throws -> String {
        try String(contentsOf: location, encoding: .utf8)
    }

    private func contentsOf(_ file: File) throws -> String {
        try contentsOf(index.location(of: file))
    }
}
