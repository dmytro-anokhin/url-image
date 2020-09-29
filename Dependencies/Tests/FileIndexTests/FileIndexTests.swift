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
        XCTAssertTrue(FileManager.default.fileExists(atPath: file.location.path))
        XCTAssertEqual(try contentsOf(file.location), "This is a test")

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
        XCTAssertFalse(FileManager.default.fileExists(atPath: file.location.path))
        XCTAssertTrue(files3.isEmpty)
    }

    func testWrite() throws {
        let originalURL = URL(string: "https://localhost")!
        let urlResponse = URLResponse(url: originalURL, mimeType: "text", expectedContentLength: -1, textEncodingName: nil)

        // Write file
        let file = try index.write("This is a test".data(using: .utf8)!, originalURL: originalURL, urlResponse: urlResponse)
        XCTAssertTrue(FileManager.default.fileExists(atPath: file.location.path))
        XCTAssertEqual(try contentsOf(file.location), "This is a test")

        // Get using original url
        let files1 = index.get(originalURL)
        XCTAssertEqual(files1.count, 1)
        XCTAssertEqual(files1.first, file)
        XCTAssertURLResponse(files1.first!.urlResponse!, urlResponse)

        // Get using identifier
        let files2 = index.get(file.id)
        XCTAssertEqual(files2.count, 1)
        XCTAssertEqual(files2.first, file)
        XCTAssertURLResponse(files2.first!.urlResponse!, urlResponse)

        // Delete file
        index.delete(file)
        let files3 = index.get(file.id)
        XCTAssertFalse(FileManager.default.fileExists(atPath: file.location.path))
        XCTAssertTrue(files3.isEmpty)
    }

    func testExpired() throws {
        let tmpLocation = makeTemporaryFile("This is a test")
        let originalURL = URL(string: "https://localhost")!

        // Copy file
        let file = try index.copy(tmpLocation, originalURL: originalURL, expireAfter: 0.1)
        XCTAssertTrue(FileManager.default.fileExists(atPath: file.location.path))
        XCTAssertEqual(try contentsOf(file.location), "This is a test")

        Thread.sleep(forTimeInterval: 0.1)

        // File was deleted
        let files = index.get(originalURL)
        XCTAssertTrue(files.isEmpty)
        XCTAssertFalse(FileManager.default.fileExists(atPath: file.location.path))
    }

    func testNotExpired() throws {
        let tmpLocation = makeTemporaryFile("This is a test")
        let originalURL = URL(string: "https://localhost")!

        // Copy file
        let file = try index.copy(tmpLocation, originalURL: originalURL, expireAfter: 1.0)
        XCTAssertTrue(FileManager.default.fileExists(atPath: file.location.path))
        XCTAssertEqual(try contentsOf(file.location), "This is a test")

        Thread.sleep(forTimeInterval: 0.1)

        // File still exists
        let files = index.get(originalURL)
        XCTAssertEqual(files.count, 1)
        XCTAssertEqual(files.first, file)
        XCTAssertTrue(FileManager.default.fileExists(atPath: file.location.path))
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

    /// Compare some fields of URLResponse to determine equality for test purposes
    private func XCTAssertURLResponse(_ lhs: URLResponse, _ rhs: URLResponse) {
        XCTAssertTrue(type(of: lhs) === type(of: rhs))
        XCTAssertEqual(lhs.url, rhs.url)
        XCTAssertEqual(lhs.mimeType, rhs.mimeType)
        XCTAssertEqual(lhs.expectedContentLength, rhs.expectedContentLength)
        XCTAssertEqual(lhs.textEncodingName, rhs.textEncodingName)
        XCTAssertEqual((lhs as? HTTPURLResponse)?.statusCode, (rhs as? HTTPURLResponse)?.statusCode)
    }
}
