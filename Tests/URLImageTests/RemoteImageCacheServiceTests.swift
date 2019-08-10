//
//  RemoteImageCacheServiceTests.swift
//  URLImageTests
//
//  Created by Dmytro Anokhin on 01/08/2019.
//  Copyright © 2019 Dmytro Anokhin. All rights reserved.
//

import XCTest

@testable import URLImage


@available(iOS 13.0, tvOS 13.0, *)
final class RemoteImageCacheServiceTests: XCTestCase {

    /// Test images
    private let testImages: [[[Pixel]]] = [
        /// 3x2 image with red/green/blue and white/black/gray pixels, and constant 1.0 alpha.
        [
            [ (r: 1.0, g: 0.0, b: 0.0, a: 1.0), (r: 0.0, g: 1.0, b: 0.0, a: 1.0), (r: 0.0, g: 0.0, b: 1.0, a: 1.0) ],
            [ (r: 1.0, g: 1.0, b: 1.0, a: 1.0), (r: 0.0, g: 0.0, b: 0.0, a: 1.0), (r: 0.5, g: 0.5, b: 0.5, a: 1.0) ]
        ]
    ]

    /// Helper function that creates a test image file in the temporary directory
    private func prepareTestImageFile(pixels: [[Pixel]]) -> URL? {
        guard let image = CGImage.draw(pixels: pixels) else {
            print("Failed to draw the test image")
            return nil
        }

        let fileName = UUID().uuidString
        let url = testDirectoryURL.appendingPathComponent(fileName).appendingPathExtension("png")

        do {
            try image.write(to: url)
        }
        catch {
            print("Failed to write an image \(error)")
        }

        return url
    }

    private let testDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("URLImageTests")

    override func setUp() {
        super.setUp()

        do {
            try FileManager.default.createDirectory(at: testDirectoryURL, withIntermediateDirectories: true, attributes: nil)
            print("Created the test directory at: \(testDirectoryURL)")
        }
        catch {
            print("Failed to create the test directory at: \(testDirectoryURL) with error: \(error)")
        }
    }

    override func tearDown() {
        do {
            try FileManager.default.removeItem(at: testDirectoryURL)
            print("Removed the test directory")
        }
        catch {
            print("Failed to remove the test directory with error: \(error)")
        }

        super.tearDown()
    }

    // MARK: Tests

    static var allTests = [
        ("testAddingRemovingFile", testAddingRemovingFile),
    ]

    func testAddingRemovingFile() throws {
        guard let sourceURL = prepareTestImageFile(pixels: testImages[0]) else {
            XCTFail("Can not create a test image")
            return
        }

        let manager = RemoteFileCacheServiceImpl(name: "URLImage", baseURL: testDirectoryURL)
        let managedURL = try manager.addFile(withRemoteURL: sourceURL, sourceURL: sourceURL)

        // Verify file copied
        XCTAssertTrue(FileManager.default.fileExists(atPath: managedURL.path), "Image file must exist at the managed URL")

        let completeExpectation = expectation(description: "Test complete")

        manager.getFile(withRemoteURL: sourceURL) { localURL in
            // Verify file info
            XCTAssertTrue(localURL == managedURL)

            do {
                try manager.delete(fileName: managedURL.lastPathComponent)

                // Verify file deleted
                XCTAssertFalse(FileManager.default.fileExists(atPath: managedURL.path), "Image file must exist at the managed URL")

                // Verify file info removed
                manager.getFile(withRemoteURL: sourceURL) { localURL in
                    XCTAssertNil(localURL)
                    completeExpectation.fulfill()
                }
            }
            catch {
                XCTFail("Failed to delete an image \(error)")
            }
        }

        wait(for: [completeExpectation], timeout: 0.1)
    }
}
