//
//  URLImageInMemoryStore.swift
//  
//
//  Created by Dmytro Anokhin on 09/02/2021.
//

import Foundation


/// The `URLImageInMemoryStoreType` describes an object used to store images in-memory for fast access.
public protocol URLImageInMemoryStoreType: URLImageStoreType {

    func getImage<T>(_ keys: [URLImageStoreKey]) -> T?

    func store<T>(_ image: T, info: URLImageStoreInfo)
}
