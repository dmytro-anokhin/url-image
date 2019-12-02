//
//  AnimatedImageView.swift
//  
//
//  Created by Dmytro Anokhin on 02/12/2019.
//

import SwiftUI

#if os(iOS) || os(tvOS)

import UIKit


@available(iOS 13.0, tvOS 13.0, *)
@available(OSX, unavailable)
@available(watchOS, unavailable)
public struct AnimatedImage: UIViewRepresentable {

    public let uiImage: UIImage

    public let aspectRatio: ContentMode

    public init(uiImage: UIImage, aspectRatio: ContentMode = .fill) {
        self.uiImage = uiImage
        self.aspectRatio = aspectRatio
    }

    public func makeUIView(context: UIViewRepresentableContext<AnimatedImage>) -> UIView {
        let uiView = AnimatedImageContainerView()
        update(uiView)

        return uiView
    }

    public func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<AnimatedImage>) {
        update(uiView as! AnimatedImageContainerView)
    }

    private final class AnimatedImageContainerView: UIView {

        let imageView = UIImageView()

        override init(frame: CGRect) {
            super.init(frame: frame)
            init_AnimatedImageContainerView()
        }

        required init?(coder: NSCoder) {
            super.init(coder: coder)
            init_AnimatedImageContainerView()
        }

        private func init_AnimatedImageContainerView() {
            imageView.translatesAutoresizingMaskIntoConstraints = false
            addSubview(imageView)

            NSLayoutConstraint.activate([
                imageView.topAnchor.constraint(equalTo: topAnchor),
                imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
                imageView.bottomAnchor.constraint(equalTo: bottomAnchor),
                imageView.trailingAnchor.constraint(equalTo: trailingAnchor)
            ])
        }
    }

    private func update(_ uiView: AnimatedImageContainerView) {
        uiView.imageView.image = uiImage

        switch aspectRatio {
            case .fit:
                uiView.imageView.contentMode = .scaleAspectFit
            case .fill:
                uiView.imageView.contentMode = .scaleAspectFill
        }
    }
}


#endif
