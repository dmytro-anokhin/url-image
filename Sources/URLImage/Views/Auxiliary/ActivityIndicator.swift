//
//  ActivityIndicator.swift
//  
//
//  Created by Dmytro Anokhin on 12/08/2020.
//

import SwiftUI


@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
public struct ActivityIndicator: View {

    public init() {
    }

    public var body: some View {
        ProgressView().progressViewStyle(.circular)
    }
}


@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
struct ActivityIndicator_Previews: PreviewProvider {
    static var previews: some View {
        ActivityIndicator()
            .background(Color.white)
    }
}
