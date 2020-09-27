//
//  File.swift
//  
//
//  Created by Dmytro Anokhin on 09/09/2020.
//

import Foundation
import CoreData
import PlainDatabase


@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public struct File : Identifiable {

    public var id: String

    public var dateCreated: Date

    /// `nil` stands for never expire
    public var expiryInterval: TimeInterval?

    public var originalURL: URL

    public var location: URL

    public var urlResponse: URLResponse?

    public init(id: String, dateCreated: Date, expiryInterval: TimeInterval?, originalURL: URL, location: URL, urlResponse: URLResponse?) {
        self.id = id
        self.dateCreated = dateCreated
        self.expiryInterval = expiryInterval
        self.originalURL = originalURL
        self.location = location
        self.urlResponse = urlResponse
    }
}


@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension File : Equatable {

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
            && lhs.dateCreated == rhs.dateCreated
            && lhs.expiryInterval == rhs.expiryInterval
            && lhs.originalURL == rhs.originalURL
            && lhs.location == rhs.location
    }
}


@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension File : ManagedObjectCodable {

    public init?(managedObject: NSManagedObject) {
        guard let id = managedObject.value(forKey: "identifier") as? String,
              let dateCreated = managedObject.value(forKey: "dateCreated") as? Date,
              let originalURL = managedObject.value(forKey: "originalURL") as? URL,
              let location = managedObject.value(forKey: "location") as? URL
        else {
            return nil
        }

        let expiryInterval = managedObject.value(forKey: "expiryInterval") as? TimeInterval

        let urlResponse: URLResponse?

        if let data = managedObject.value(forKey: "urlResponse") as? Data {
            urlResponse = URLResponse.decode(data)
        }
        else {
            urlResponse = nil
        }

        self.init(id: id, dateCreated: dateCreated, expiryInterval: expiryInterval, originalURL: originalURL, location: location, urlResponse: urlResponse)
    }

    public func encode(to object: NSManagedObject) {
        object.setValue(id, forKey: "identifier")
        object.setValue(dateCreated, forKey: "dateCreated")
        object.setValue(expiryInterval, forKey: "expiryInterval")
        object.setValue(originalURL, forKey: "originalURL")
        object.setValue(location, forKey: "location")

        if let urlResponse = urlResponse {
            object.setValue(urlResponse.encode(), forKey: "urlResponse")
        }
    }
}


@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension URLResponse {

    static func decode(_ data: Data) -> URLResponse? {
        try? NSKeyedUnarchiver.unarchivedObject(ofClasses: [HTTPURLResponse.self, URLResponse.self], from: data) as? URLResponse
    }

    func encode() -> Data? {
        try? NSKeyedArchiver.archivedData(withRootObject: self, requiringSecureCoding: true)
    }
}
