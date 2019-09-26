//
//  PartialImage.swift
//  
//
//  Created by Dmytro Anokhin on 21/09/2019.
//

import Combine


public final class PartialImage: ObservableObject {

    @Published public var progress: Float?

    public init(progress: Float? = nil) {
        self.progress = progress
    }
}
