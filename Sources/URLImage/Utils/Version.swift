//
//  Version.swift
//  URLImage
//
//  Created by Dmytro Anokhin on 26/10/2019.
//  Copyright © 2019 Dmytro Anokhin. All rights reserved.
//


/// Basic implementation of the semantic versioning standard without pre-release identifiers.
///
/// [semver.org](www.semver.org)
struct Version: Codable, Equatable, Comparable {

    /// The major version according to the semantic versioning standard.
    var major: Int

    /// The minor version according to the semantic versioning standard.
    var minor: Int

    /// The patch version according to the semantic versioning standard.
    var patch: Int

    /**
     Precedence refers to how versions are compared to each other when ordered. Precedence MUST be calculated by separating the version into major, minor, patch and pre-release identifiers in that order (Build metadata does not figure into precedence). Precedence is determined by the first difference when comparing each of these identifiers from left to right as follows: Major, minor, and patch versions are always compared numerically. Example: 1.0.0 < 2.0.0 < 2.1.0 < 2.1.1.
     */
    static func < (lhs: Version, rhs: Version) -> Bool {
        guard lhs.major == rhs.major else {
            return lhs.major < rhs.major
        }

        guard lhs.minor == rhs.minor else {
            return lhs.minor < rhs.minor
        }

        return lhs.patch < rhs.patch
    }
}
