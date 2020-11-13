//
//  RemoteContentViewLoadOptions+URLImageOptions_LoadOptions.swift
//  
//
//  Created by Dmytro Anokhin on 08/11/2020.
//

#if canImport(RemoteContentView)
import RemoteContentView
#endif


@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
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
