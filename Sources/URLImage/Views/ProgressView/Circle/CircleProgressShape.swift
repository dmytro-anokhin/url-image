//
//  CircleProgressShape.swift
//  URLImage
//  
//
//  Created by Dmytro Anokhin on 26/09/2019.
//  Copyright © 2019 Dmytro Anokhin. All rights reserved.
//

import SwiftUI


@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
struct CircleProgressShape: Shape {

    struct Geometry {

        init(rect: CGRect) {
            self.rect = rect
        }

        init(size: CGSize) {
            self.rect = CGRect(origin: .zero, size: size)
        }

        let rect: CGRect

        var center: CGPoint {
            return CGPoint(x: rect.midX, y: rect.midY)
        }

        var radius: CGFloat {
            return min(rect.width, rect.height) * 0.5
        }

        func startPoint(forAngle angle: Angle) -> CGPoint {
            return CGPoint(x: center.x + radius * CGFloat(cos(angle.radians)),
                           y: center.y + radius * CGFloat(sin(angle.radians)))
        }
    }

    var progress: Double

    var damping: Double = 0.35

    func path(in rect: CGRect) -> Path {
        Path { path in
            let geometry = Geometry(rect: rect)
            path.move(to: geometry.startPoint(forAngle: startAngle))
            path.addArc(center: geometry.center, radius: geometry.radius, startAngle: self.startAngle, endAngle: self.endAngle, clockwise: false)
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

    private var startAngle: Angle {
        let angle: Angle

        if damping <= 0.5 {
            if progress > (1.0 - damping) {
                angle = Angle(degrees: 360.0 * (2.0 * progress - 1.0))
            } else if progress > damping {
                angle = Angle(degrees: 360.0 * (progress - damping))
            } else {
                angle = Angle(degrees: 0.0)
            }
        }
        else {
            angle = Angle(degrees: 0.0)
        }

        return angle
    }

    private var endAngle: Angle {
        return Angle(degrees: min(max(progress, 0.0), 1.0) * 360.0)
    }
}
