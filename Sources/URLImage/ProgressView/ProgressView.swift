//
//  ProgressView.swift
//  
//
//  Created by Dmytro Anokhin on 24/09/2019.
//

import SwiftUI


public struct ProgressView<Content>: View where Content : View {

    public init(_ downloadProgressWrapper: DownloadProgressWrapper, content: @escaping (_ progress: Float) -> Content) {
        self.downloadProgressWrapper = downloadProgressWrapper
        self.content = content
    }

    @ObservedObject public var downloadProgressWrapper: DownloadProgressWrapper

    public var content: (_ progress: Float) -> Content

    public var body: some View {
        content($downloadProgressWrapper.progress.wrappedValue ?? 0.0)
    }
}
