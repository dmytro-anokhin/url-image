//
//  URLImageError.swift
//  
//
//  Created by Dmytro Anokhin on 02/10/2020.
//


public enum URLImageError : Error {

    /// Failed to decode the image from data. Either after download or when reading from disk.
    case decode
}
