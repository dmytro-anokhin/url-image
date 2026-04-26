import XCTest
import SwiftUI
@testable import URLImage

@available(macOS 11.0, *)
final class URLImageTests: XCTestCase {
    func testInstalledRemoteViewOnlyStartsImmediateLoadsDuringInstallation() {
        XCTAssertTrue(
            InstalledRemoteView<EmptyView>.shouldStartLoadingDuringInstallation(
                loadOptions: URLImageOptions.LoadOptions.loadImmediately
            )
        )
        XCTAssertFalse(
            InstalledRemoteView<EmptyView>.shouldStartLoadingDuringInstallation(
                loadOptions: URLImageOptions.LoadOptions.loadOnAppear
            )
        )
        XCTAssertFalse(
            InstalledRemoteView<EmptyView>.shouldStartLoadingDuringInstallation(
                loadOptions: [
                    URLImageOptions.LoadOptions.loadOnAppear,
                    URLImageOptions.LoadOptions.cancelOnDisappear
                ]
            )
        )
    }

    func testRemoteImageMemoryLookupKeysPreferIdentifierOverURL() {
        let url = URL(string: "https://example.com/image.gif")!

        XCTAssertEqual(
            RemoteImage.memoryLookupKeys(identifier: "detail-image", url: url),
            [.identifier("detail-image")]
        )
        XCTAssertEqual(
            RemoteImage.memoryLookupKeys(identifier: nil, url: url),
            [.url(url)]
        )
    }

    static let allTests = [
        ("testInstalledRemoteViewOnlyStartsImmediateLoadsDuringInstallation", testInstalledRemoteViewOnlyStartsImmediateLoadsDuringInstallation),
        ("testRemoteImageMemoryLookupKeysPreferIdentifierOverURL", testRemoteImageMemoryLookupKeysPreferIdentifierOverURL),
    ]
}
