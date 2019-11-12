//
//  CircleActivityView.swift
//  
//
//  Created by Dmytro Anokhin on 26/09/2019.
//

import SwiftUI


@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
public struct CircleActivityView : View {

    public init() {
    }

    public func stroke(lineWidth: CGFloat = 1) -> CircleActivityView {
        var result = self
        result.lineWidth = lineWidth

        return result
    }

    public var animation: Animation {
        Animation.linear(duration: 2.0).repeatForever(autoreverses: false)
    }

    public var body: some View {
        CircleProgressShape(progress: progress)
            .stroke(lineWidth: lineWidth)
            .rotationEffect(Angle(degrees: -90.0))
            .onAppear() {
                withAnimation(self.animation) {
                    self.progress = 1.0
                }
            }
    }

    @State private var progress: Double = 0.0

    private var lineWidth: CGFloat = 8.0
}
