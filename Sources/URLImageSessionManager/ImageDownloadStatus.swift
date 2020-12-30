//
//  ImageDownloadStatus.swift
//  
//
//  Created by Dmytro Anokhin on 30/12/2020.
//


/// Status of the image
public enum ImageDownloadStatus {

    /// Download not started
    case none

    /// Download in progress
    case inProgress

    /// Image is cached on disk
    case onDisk
}
