//
//  ImageDecoderTests.swift
//
//
//  Created by Dmytro Anokhin on 15/09/2020.
//

import XCTest
import CoreGraphics
@testable import ImageDecoder


@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
final class ImageDecoderTests: XCTestCase {

    private struct TestImage : Codable {

        var name: String

        var `extension`: String?

        var allDataReceived: Bool

        var frameCount: Int

        var tolerance: Float

        var url: URL {
            Bundle.module.url(forResource: name, withExtension: `extension`)!
        }

        func load() throws -> Data {
            try Data(contentsOf: url)
        }

        var fileName: String {
            guard let `extension` = self.extension else {
                return name
            }

            return name + "." + `extension`
        }
    }

    private func loadTestImages(name: String) throws -> [TestImage] {
        guard let url = Bundle.module.url(forResource: name, withExtension: "json") else {
            return []
        }

        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([TestImage].self, from: data)
    }

    func testDecodingData() throws {
        let testImages = try loadTestImages(name: "TestImages")
        XCTAssertFalse(testImages.isEmpty) // Sanity check: there has to be something to test

        for testImage in testImages {
            print("Testing \(testImage.fileName)")

            let data = try testImage.load()
            let decoder = ImageDecoder()
            decoder.setData(data, allDataReceived: testImage.allDataReceived)

            XCTAssertEqual(decoder.frameCount, testImage.frameCount)

            guard decoder.frameCount > 0 else {
                continue
            }

            // If all data received the frame must be complete
            XCTAssertEqual(decoder.isFrameComplete(at: 0), testImage.allDataReceived)

            let image = decoder.createFrameImage(at: 0)!
            XCTAssertTrue(try compare(decoded: image, data: data, tolerance: testImage.tolerance))
        }
    }

//    static var allTests = [
//        ("testDecoding", testDecoding),
//    ]
}

#if canImport(AppKit)

import AppKit

extension NSImage {

    var cgImage: CGImage? {
        var imageRect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        return cgImage(forProposedRect: &imageRect, context: nil, hints: nil)
    }
}

func compare(decoded decodedImage: CGImage, data: Data, tolerance: Float) throws -> Bool {
    guard let referenceImage = NSBitmapImageRep(data: data)?.cgImage else {
        assertionFailure("Can not load reference image")
        return false
    }

    return try CGImage.compare(image: decodedImage, referenceImage: referenceImage, tolerance: tolerance)
}

#endif


#if canImport(UIKit)

import UIKit

func compare(decoded decodedImage: CGImage, data: Data, tolerance: Float) throws -> Bool {
    guard let referenceImage = UIImage(data: data)?.cgImage else {
        assertionFailure("Can not load reference image")
        return false
    }

    return try CGImage.compare(image: decodedImage, referenceImage: referenceImage, tolerance: 1.0)
}

#endif


fileprivate extension CGImage {

    enum ComparisonError : Error {

        case unknownColorSpace

        case cgContext
    }

    // Based on https://github.com/facebookarchive/ios-snapshot-test-case/blob/master/FBSnapshotTestCase/Categories/UIImage%2BCompare.m
    static func compare(image: CGImage, referenceImage: CGImage, tolerance: Float) throws -> Bool {
        guard image.width == referenceImage.width && image.height == referenceImage.height else {
            return false
        }

        guard let colorSpace = image.colorSpace,
              let referenceColorSpace = referenceImage.colorSpace
        else {
            throw ComparisonError.unknownColorSpace
        }

        let size = CGSize(width: image.width, height: image.height)
        let numberOfPixels = image.width * image.height

        let pixels = UnsafeMutablePointer<UInt32>.allocate(capacity: numberOfPixels)
        let referencePixels = UnsafeMutablePointer<UInt32>.allocate(capacity: numberOfPixels)

        let pixelsRaw = UnsafeMutableRawPointer(pixels)
        let referencePixelsRaw = UnsafeMutableRawPointer(referencePixels)

        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)

        let bytesPerRow = min(image.bytesPerRow, referenceImage.bytesPerRow)

        guard let context = CGContext(data: pixelsRaw,
                                      width: Int(size.width),
                                      height: Int(size.height),
                                      bitsPerComponent: image.bitsPerComponent,
                                      bytesPerRow: bytesPerRow,
                                      space: colorSpace, bitmapInfo: bitmapInfo.rawValue),
              let referenceContext = CGContext(data: referencePixelsRaw,
                                               width: Int(size.width),
                                               height: Int(size.height),
                                               bitsPerComponent: referenceImage.bitsPerComponent,
                                               bytesPerRow: bytesPerRow,
                                               space: referenceColorSpace,
                                               bitmapInfo: bitmapInfo.rawValue)
        else {
            pixels.deallocate()
            referencePixels.deallocate()

            throw ComparisonError.cgContext
        }

        context.draw(image, in: CGRect(origin: .zero, size: size))
        referenceContext.draw(referenceImage, in: CGRect(origin: .zero, size: size))

        let buffer = UnsafeBufferPointer(start: pixels, count: numberOfPixels)
        let referenceBuffer = UnsafeBufferPointer(start: referencePixels, count: numberOfPixels)

        var result = true

        if tolerance == 0.0 {
            result = buffer.elementsEqual(referenceBuffer)
        }
        else {
            // Go through each pixel in turn and see if it is different
            var numDiffPixels = 0

            for pixel in 0 ..< numberOfPixels where buffer[pixel] != referenceBuffer[pixel] {
                // If this pixel is different, increment the pixel diff count and see if we have hit our limit.
                numDiffPixels += 1
                let percentage = 100 * Float(numDiffPixels) / Float(numberOfPixels)
                if percentage > tolerance {
                    result = false
                    break
                }
            }
        }

        pixels.deallocate()
        referencePixels.deallocate()

        return result
    }
}
