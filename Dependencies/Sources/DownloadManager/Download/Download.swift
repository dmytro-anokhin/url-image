//
//  Download.swift
//  
//
//  Created by Dmytro Anokhin on 07/07/2020.
//

import Foundation


/**
    The `Download` object describes a single file download.
 */
public struct Download {

    public var url: URL

    public var id: UUID

    public enum Destination : Codable, Hashable {

        /// Download to a shared buffer in memory
        case inMemory

        /// Download to a file at the given path on disk
        case onDisk(_ path: String)

        /// Destination enum without associated value for `Codable` protocol implementation
        private enum Destination : String, Codable {

            case inMemory, onDisk
        }

        enum CodingKeys : String, CodingKey, Codable {

            /// Case in the enclosing enum
            case destination

            /// `path` associated value in  the`onDisk` case
            case path
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let destination = try container.decode(Destination.self, forKey: .destination)

            switch destination {
                case .inMemory:
                    self = .inMemory

                case .onDisk:
                    let path = try container.decode(String.self, forKey: .path)
                    self = .onDisk(path)
            }
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)

            switch self {
                case .inMemory:
                    try container.encode(Destination.inMemory, forKey: .destination)

                case .onDisk(let path):
                    try container.encode(Destination.onDisk, forKey: .destination)
                    try container.encode(path, forKey: .path)
            }
        }
    }

    public var destination: Destination

    public struct DownloadPolicy : OptionSet, Codable, Hashable {

        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        /// Keep download alive even with no subscribers
        public static let keepAlive = DownloadPolicy(rawValue: 1 << 0)
    }

    public var downloadPolicy: DownloadPolicy

    public struct URLRequestConfiguration : Hashable, Codable {

        public var allHTTPHeaderFields: [String : String]?

        public var cachePolicy: URLRequest.CachePolicy

        public init(allHTTPHeaderFields: [String : String]? = nil, cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy) {
            self.allHTTPHeaderFields = allHTTPHeaderFields
            self.cachePolicy = cachePolicy
        }
    }

    public var urlRequestConfiguration: URLRequestConfiguration

    public init(url: URL,
                id: UUID = UUID(),
                destination: Destination = .inMemory,
                downloadPolicy: DownloadPolicy = [],
                urlRequestConfiguration: URLRequestConfiguration = URLRequestConfiguration()) {
        self.url = url
        self.id = id
        self.destination = destination
        self.downloadPolicy = downloadPolicy
        self.urlRequestConfiguration = urlRequestConfiguration
    }
}

extension Download : CustomStringConvertible {}
extension Download : Identifiable {}
extension Download : Hashable {}
extension Download : Codable {}

extension URLRequest.CachePolicy : Codable {}
