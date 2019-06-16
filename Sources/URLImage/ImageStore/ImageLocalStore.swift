//
//  ImageLocalStore.swift
//  URLImage
//
//  Created by Dmytro Anokhin on 06/06/2019.
//  Copyright © 2019 Dmytro Anokhin. All rights reserved.
//

import UIKit


final class ImageLocalStore : ImageStoreType {

    // MARK: Public
    
    enum Error : Swift.Error {
    
        case generic
    }

    // MARK: ImageStoreType

    func loadImage(for remoteURL: URL, completion: @escaping (Result<(UIImage, URL?), Swift.Error>) -> Void) {
        queue.async {
            if self.imageFiles == nil {
                self.imageFiles = self.load()
            }

            if let file = self.imageFiles![remoteURL] {
                let localURL = CacheHelper.imageCachesDirectoryURL.appendingPathComponent(file.name, isDirectory: false)

                if let image = UIImage(contentsOfFile: localURL.path) {
                    completion(.success((image, localURL)))
                }
                else {
                    // Failed to read image file
                    completion(.failure(Error.generic))
                }
            }
            else {
                // Image is not in the local store
                completion(.failure(Error.generic))
            }
        }
    }

    func saveImage(_ image: UIImage, remoteURL: URL, localURL: URL) {
        queue.async {
            if self.imageFiles == nil {
                self.imageFiles = self.load()
            }

            let file = ImageFile(name: localURL.lastPathComponent, remoteURL: remoteURL)
            self.imageFiles![remoteURL] = file
            self.save(imageFiles: self.imageFiles!)
        }
    }

    // MARK: Private

    private struct ImageFile: Codable {

        let name: String

        let remoteURL: URL
    }
    
    private static let imagesFileName = "imagesMap"

    /// Serial queue
    private let queue = DispatchQueue(label: "URLImage.ImageLocalStore")

    private var imageFiles: [URL: ImageFile]?
    
    private var imageFilesURL: URL {
        return CacheHelper.cachesDirectoryURL.appendingPathComponent(Self.imagesFileName, isDirectory: false)
    }

    private func load() -> [URL: ImageFile] {
        do {
            let data = try Data(contentsOf: imageFilesURL)
            let decoder = JSONDecoder()
            
            return try decoder.decode([URL: ImageFile].self, from: data)
        }
        catch {
            return [:]
        }
    }
    
    private func save(imageFiles: [URL: ImageFile]) {
        let encoder = JSONEncoder()
        
        do {
            let data = try encoder.encode(imageFiles)
            try? FileManager.default.createDirectory(at: CacheHelper.cachesDirectoryURL, withIntermediateDirectories: false, attributes: nil)
            try data.write(to: imageFilesURL)
        }
        catch {
            print(error)
        }
    }
}
