//
//  Synchronized.swift
//  
//
//  Created by Dmytro Anokhin on 08/02/2021.
//

import Foundation


/// Provides synchronization of the wrapped value using concurrent queue with barrier.
///
/// `Synchronized` provides getter/setter synchronization, thread safety of the wrapped value is up to its implementation.
@propertyWrapper
public final class Synchronized<Value> {

    public var wrappedValue: Value {
        get {
            synchronizationQueue.sync {
                value
            }
        }

        set {
            synchronizationQueue.async(flags: .barrier) {
                self.value = newValue
            }
        }
    }

    public init(wrappedValue: Value) {
        value = wrappedValue
    }

    private let synchronizationQueue = DispatchQueue(label: "Synchronized.synchronizationQueue.\(UUID().uuidString)", attributes: .concurrent)

    private var value: Value
}
