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

    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                CircleProgressShape(progress: Double(self.progress))
                    .stroke(lineWidth: 8.0)
                    .rotation(.degrees(-90.0))
                    .animation(.linear(duration: 0.1))
            }
        }
    }
}


fileprivate struct CircleProgressShape: Shape {

    var progress: Double

    func path(in rect: CGRect) -> Path {
        Path { path in
            let diameter = min(rect.width, rect.height)
            let radius = diameter * 0.5
            let center = CGPoint(x: rect.midX, y: rect.midY)

            let startAngle = Angle(degrees: 0.0)
            let endAngle = Angle(degrees: min(max(self.progress, 0.0), 1.0) * 360.0)

            let start = CGPoint(x: center.x + radius * CGFloat(cos(startAngle.radians)),
                                y: center.y + radius * CGFloat(sin(startAngle.radians)))

            path.move(to: start)
            path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        }
    }

    var animatableData: Double {
        get {
            return progress
        }

        set {
            progress = newValue
        }
    }
}
