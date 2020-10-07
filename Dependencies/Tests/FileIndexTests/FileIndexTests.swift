//
//  FileIndexTests.swift
//  
//
//  Created by Dmytro Anokhin on 12/09/2020.
//

import Foundation
import XCTest
@testable import FileIndex


final class FileIndexTests: XCTestCase {

    func testCopy() throws {
        let tmpLocation = makeTemporaryFile("This is a test")
        let originalURL = URL(string: "https://localhost")!

        // Copy file
        let file = try index.copy(tmpLocation, originalURL: originalURL)
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
        let file = try index.copy(tmpLocation, originalURL: originalURL, expireAfter: 0.1)
        XCTAssertTrue(FileManager.default.fileExists(atPath: index.location(of: file).path))
        XCTAssertEqual(try contentsOf(file), "This is a test")

        Thread.sleep(forTimeInterval: 0.1)

        // File was deleted
        let files = index.get(originalURL)
        XCTAssertTrue(files.isEmpty)
        XCTAssertFalse(FileManager.default.fileExists(atPath: index.location(of: file).path))
    }

    func testNotExpired() throws {
        let tmpLocation = makeTemporaryFile("This is a test")
        let originalURL = URL(string: "https://localhost")!

        // Copy file
        let file = try index.copy(tmpLocation, originalURL: originalURL, expireAfter: 1.0)
        XCTAssertTrue(FileManager.default.fileExists(atPath: index.location(of: file).path))
        XCTAssertEqual(try contentsOf(file), "This is a test")

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
