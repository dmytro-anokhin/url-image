//
//  ActivityIndicator.swift
//  
//
//  Created by Dmytro Anokhin on 12/08/2020.
//

import SwiftUI


#if canImport(UIKit) && !os(watchOS)

import UIKit


@available(iOS 13.0, tvOS 13.0, *)
@available(watchOS, unavailable)
struct ActivityIndicatorUIKit: UIViewRepresentable {

    func makeUIView(context: Context) -> UIActivityIndicatorView {
        UIActivityIndicatorView(style: .medium)
    }

    func updateUIView(_ uiView: UIActivityIndicatorView, context: Context) {
        uiView.startAnimating()
    }
}

#endif


#if canImport(AppKit) && !targetEnvironment(macCatalyst)

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

    #if canImport(UIKit) && !os(watchOS)
    public var body: some View {
        ActivityIndicatorUIKit()
    }
    #elseif canImport(AppKit)
    public var body: some View {
        ActivityIndicatorAppKit()
    }
    #else
    public var body: some View {
        EmptyView()
    }
    #endif
}


@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
struct ActivityIndicator_Previews: PreviewProvider {
    static var previews: some View {
        ActivityIndicator()
            .background(Color.white)
    }
}
