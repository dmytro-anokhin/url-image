//
//  ActivityIndicator.swift
//  
//
//  Created by Dmytro Anokhin on 12/08/2020.
//

import SwiftUI


#if canImport(UIKit)

import UIKit


struct ActivityIndicatorImpl: UIViewRepresentable {

    func makeUIView(context: Context) -> UIActivityIndicatorView {
        UIActivityIndicatorView(style: .medium)
    }

    func updateUIView(_ uiView: UIActivityIndicatorView, context: Context) {
        uiView.startAnimating()
    }
}

#endif


@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public struct ActivityIndicator: View {

    public init() {
    }

    public var body: some View {
        #if canImport(UIKit)
            ActivityIndicatorImpl()
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
