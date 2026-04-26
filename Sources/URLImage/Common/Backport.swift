//
//  File.swift
//  URLImage
//
//  Created by sonoma on 8/1/24.
//

import Foundation
import SwiftUI

struct Backport<Content: View> {
    let content: Content
}

extension View {
    var backport: Backport<Self> {
        Backport(content: self)
    }
}

extension Backport {
    @inlinable
    @MainActor
    @ViewBuilder
    func task(priority: TaskPriority = .userInitiated, _ action: @escaping @Sendable () async -> Void) -> some View {
        if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
            content.task(priority: priority, action)
        } else {
            content.modifier(TaskModifier(priority: priority, action: action))
        }
    }
}

struct TaskModifier: ViewModifier {
    @State private var loaded = false
    var priority: TaskPriority
    var action: () async -> Void
    
    init(priority: TaskPriority, action: @escaping @Sendable () async -> Void) {
        self.priority = priority
        self.action = action
    }
    
    func body(content: Content) -> some View {
        content.onAppear {
            if !loaded {
                loaded = true
                Task(priority: priority, operation: {
                    await action()
                })
            }
        }
    }
}
