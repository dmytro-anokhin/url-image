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
    
    let directory: URL

    init(directory: URL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!) {
        self.directory = directory
    }

    // MARK: ImageStoreType

    func loadImage(for url: URL, completion: @escaping (Result<UIImage, Swift.Error>) -> Void) {
        queue.async {
            if self.imageFiles == nil {
                self.imageFiles = self.load()
            }

            if let file = self.imageFiles![url] {
                // Try load from disk
                let url = self.fileURL(for: file)

                if let image = UIImage(contentsOfFile: url.path) {
                    completion(.success(image))
                }
                else {
                    completion(.failure(Error.generic))
                }
            }
            else {
                completion(.failure(Error.generic))
            }
        }
    }

    func saveImage(_ image: UIImage, for url: URL) {
        queue.async {
            if self.imageFiles == nil {
                self.imageFiles = self.load()
            }

            do {
                let file = ImageFile(url: url)
                let data = image.pngData()
                let fileURL = self.fileURL(for: file)
                try data?.write(to: fileURL)
                self.imageFiles![url] = file
            }
            catch {
                print(error)
            }

            self.save(imageFiles: self.imageFiles!)
        }
    }

    // MARK: Private

    private struct ImageFile: Codable {

        let uuid = UUID()
        
        let url: URL
    }
    
    private static let imagesFileName = "images"
    
    private static let cachedImagesDirectoryName = "cachedImages"

    /// Serial queue
    private let queue = DispatchQueue(label: "URLImage.ImageLocalStore")

    private var imageFiles: [URL: ImageFile]?
    
    private var imageFilesURL: URL {
        return directory.appendingPathComponent(Self.imagesFileName, isDirectory: false)
    }
    
    private var cachedImagesDirectoryURL: URL {
        return directory.appendingPathComponent(Self.cachedImagesDirectoryName, isDirectory: true)
    }
    
    private func fileURL(for imageFile: ImageFile) -> URL {
        return cachedImagesDirectoryURL.appendingPathComponent(imageFile.uuid.uuidString, isDirectory: false)
    }
    
    private func load() -> [URL: ImageFile] {
        try? FileManager.default.createDirectory(at: cachedImagesDirectoryURL, withIntermediateDirectories: false, attributes: nil)
        
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
            try data.write(to: imageFilesURL)
        }
        catch {
            print(error)
        }
    }
}
