//
//  CircleProgressView.swift
//  URLImage
//  
//
//  Created by Dmytro Anokhin on 21/09/2019.
//  Copyright © 2019 Dmytro Anokhin. All rights reserved.
//

import SwiftUI


@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
public struct CircleProgressView: View {

    public init(_ progress: Float) {
        self.progress = progress
    }

    public var progress: Float = 0.0

    public func stroke(lineWidth: CGFloat = 1) -> CircleProgressView {
        var result = self
        result.lineWidth = lineWidth

        return result
    }

    public var body: some View {
        CircleProgressShape(progress: Double(progress), damping: 1.0)
            .stroke(lineWidth: lineWidth)
            .rotation(.degrees(-90.0))
            .animation(.linear(duration: 0.25))
    }

    private var lineWidth: CGFloat = 1
}
