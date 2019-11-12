//
//  ImageIOUtils.swift
//  
//
//  Created by Dmytro Anokhin on 18/09/2019.
//

import Foundation
import ImageIO


func createCGImage(fileURL url: URL) -> CGImage? {

    let options = [
        kCGImageSourceShouldCache : true,
        kCGImageSourceShouldAllowFloat: true
    ]

    guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, options as CFDictionary) else {
        return nil
    }

    return CGImageSourceCreateImageAtIndex(imageSource, 0, nil)
}


func createCGImage(data: Data) -> CGImage? {

    let options = [
        kCGImageSourceShouldCache : true,
        kCGImageSourceShouldAllowFloat: true
    ]

    guard let imageSource = CGImageSourceCreateWithData(data as CFData, options as CFDictionary) else {
        return nil
    }

    return CGImageSourceCreateImageAtIndex(imageSource, 0, nil)
}


func imageTypeIdentifier(forItemAtURL url: URL) -> String? {
    guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil) else {
        return nil
    }

    return CGImageSourceGetType(imageSource) as String?
}
