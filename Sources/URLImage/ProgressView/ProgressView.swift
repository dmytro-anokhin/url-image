//
//  ProgressView.swift
//  
//
//  Created by Dmytro Anokhin on 24/09/2019.
//

import SwiftUI


public struct ProgressView<Content>: View where Content : View {

    public init(_ partialImage: PartialImage, content: @escaping (_ progress: Float) -> Content) {
        self.partialImage = partialImage
        self.content = content
    }

    @ObservedObject public var partialImage: PartialImage

    public var content: (_ progress: Float) -> Content

    public var body: some View {
        content($partialImage.progress.wrappedValue ?? 0.0)
    }
}
