//
//  VersionTests.swift
//  URLImageTests
//
//  Created by Dmytro Anokhin on 26/10/2019.
//  Copyright © 2019 Dmytro Anokhin. All rights reserved.
//

import XCTest
@testable import URLImage


final class VersionTests: XCTestCase {

    /// Test that 1.0.0 < 2.0.0 < 2.1.0 < 2.1.1
    func testVersionComparison() {

        let version_1_0_0 = Version(major: 1, minor: 0, patch: 0)
        let version_2_0_0 = Version(major: 2, minor: 0, patch: 0)
        let version_2_1_0 = Version(major: 2, minor: 1, patch: 0)
        let version_2_1_1 = Version(major: 2, minor: 1, patch: 1)

        XCTAssertTrue(version_1_0_0 < version_2_0_0, "")
        XCTAssertTrue(version_2_0_0 < version_2_1_0, "")
        XCTAssertTrue(version_2_1_0 < version_2_1_1, "")

        XCTAssertTrue(version_1_0_0 == version_1_0_0, "")
        XCTAssertTrue(version_2_0_0 == version_2_0_0, "")
        XCTAssertTrue(version_2_1_0 == version_2_1_0, "")
        XCTAssertTrue(version_2_1_1 == version_2_1_1, "")
    }
}
