//
//  CircleProgressView.swift
//  
//
//  Created by Dmytro Anokhin on 21/09/2019.
//

import SwiftUI


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
