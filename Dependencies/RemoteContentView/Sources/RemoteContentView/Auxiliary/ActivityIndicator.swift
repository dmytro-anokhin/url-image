//
//  ActivityIndicator.swift
//  
//
//  Created by Dmytro Anokhin on 12/08/2020.
//

import SwiftUI


#if canImport(UIKit)

import UIKit


@available(iOS 13.0, tvOS 13.0, watchOS 6.0, *)
struct ActivityIndicatorUIKit: UIViewRepresentable {

    func makeUIView(context: Context) -> UIActivityIndicatorView {
        UIActivityIndicatorView(style: .medium)
    }

    func updateUIView(_ uiView: UIActivityIndicatorView, context: Context) {
        uiView.startAnimating()
    }
}

#endif


#if canImport(AppKit)

@available(macOS 10.15, *)
struct ActivityIndicatorAppKit: NSViewRepresentable {

    func makeNSView(context: Context) -> NSProgressIndicator {
        let progressIndicator = NSProgressIndicator()
        progressIndicator.isIndeterminate = true
        progressIndicator.style = .spinning

        return progressIndicator
    }

    func updateNSView(_ nsView: NSProgressIndicator, context: Context) {
        nsView.startAnimation(nil)
    }
}

#endif


@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public struct ActivityIndicator: View {

    public init() {
    }

    public var body: some View {
        #if canImport(UIKit)
            ActivityIndicatorUIKit()
        #elseif canImport(AppKit)
            ActivityIndicatorAppKit()
        #else
            EmptyView()
        #endif
    }
}


@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
struct ActivityIndicator_Previews: PreviewProvider {
    static var previews: some View {
        ActivityIndicator()
            .background(Color.white)
    }
}
