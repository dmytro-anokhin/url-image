//
//  RemoteContentViewLoadOptions+URLImageOptions_LoadOptions.swift
//  
//
//  Created by Dmytro Anokhin on 08/11/2020.
//

import RemoteContentView


extension RemoteContentViewLoadOptions {

    init(_ loadOptions: URLImageOptions.LoadOptions) {

        var options = RemoteContentViewLoadOptions()

        if loadOptions.contains(.loadImmediately) {
            options = options.union(.loadImmediately)
        }

        if loadOptions.contains(.loadOnAppear) {
            options = options.union(.loadOnAppear)
        }

        if loadOptions.contains(.cancelOnDisappear) {
            options = options.union(.cancelOnDisappear)
        }

        self = options
    }
}
