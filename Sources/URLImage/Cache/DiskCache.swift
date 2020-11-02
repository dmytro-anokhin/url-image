//
//  DiskCache.swift
//  
//
//  Created by Dmytro Anokhin on 02/10/2020.
//

import Foundation
import Combine
import CoreGraphics

#if canImport(FileIndex)
import FileIndex
#endif


final class DiskCache {

    let fileIndex: FileIndex

    init(fileIndex: FileIndex) {
        self.fileIndex = fileIndex
    }

    convenience init() {
        let fileIndexConfiguration = FileIndex.Configuration(name: "URLImage",
                                                             filesDirectoryName: "images",
                                                             baseDirectoryName: "URLImage")
        let fileIndex = FileIndex(configuration: fileIndexConfiguration)
        self.init(fileIndex: fileIndex)
    }

    func getImage(withIdentifier identifier: String?,
                  orURL url: URL,
                  maxPixelSize: CGSize?,
                  _ completion: @escaping (_ result: Result<TransientImageType?, Swift.Error>) -> Void
    ) {
        databaseQueue.async { [weak self] in
            guard let self = self else { return }

            guard let file = self.getFile(withIdentifier: identifier, orURL: url) else {
                completion(.success(nil))
                return
            }

            self.decodeQueue.async { [weak self] in
                guard let self = self else { return }

                let location = self.fileIndex.location(of: file)

                if let transientImage = TransientImage(location: location, maxPixelSize: maxPixelSize) {
                    completion(.success(transientImage))
                }
                else {
                    completion(.failure(URLImageError.decode))
                }
            }
        }
    }

    func getImagePublisher(withIdentifier identifier: String?, orURL url: URL, maxPixelSize: CGSize?) -> AnyPublisher<TransientImageType?, Swift.Error> {
        return Future<TransientImageType?, Swift.Error> { [weak self] promise in
            guard let self = self else {
                return
            }

            self.getImage(withIdentifier: identifier, orURL: url, maxPixelSize: maxPixelSize) {
                promise($0)
            }
        }.eraseToAnyPublisher()
    }

    func cacheImageData(_ data: Data, url: URL, identifier: String?, fileName: String?, fileExtension: String?, expireAfter expiryInterval: TimeInterval?) {
        _ = try? fileIndex.write(data,
                                 originalURL: url,
                                 identifier: identifier,
                                 fileName: fileName,
                                 fileExtension: fileExtension,
                                 expireAfter: expiryInterval)
    }

    func cacheImageFile(at location: URL, url: URL, identifier: String?, fileName: String?, fileExtension: String?, expireAfter expiryInterval: TimeInterval?) {
        _ = try? fileIndex.move(location,
                                originalURL: url,
                                identifier: identifier,
                                fileName: fileName,
                                fileExtension: fileExtension,
                                expireAfter: expiryInterval)
    }

    // MARK: - Cleanup

    func cleanup() {
        fileIndex.deleteExpired()
    }

    func deleteAll() {
        fileIndex.deleteAll()
    }

    func delete(withIdentifier identifier: String?, orURL url: URL?) {
        databaseQueue.async { [weak self] in
            guard let self = self else {
                return
            }

            guard let file = self.getFile(withIdentifier: identifier, orURL: url) else {
                return
            }

            self.utilityQueue.async { [weak self] in
                guard let self = self else {
                    return
                }

                self.fileIndex.delete(file)
            }
        }
    }

    // MARK: - Private

    private let databaseQueue = DispatchQueue(label: "URLImage.DiskCache.databaseQueue", attributes: .concurrent)
    private let decodeQueue = DispatchQueue(label: "URLImage.DiskCache.decodeQueue", attributes: .concurrent)
    private let utilityQueue = DispatchQueue(label: "URLImage.DiskCache.utilityQueue", qos: .utility, attributes: .concurrent)

    private func getFile(withIdentifier identifier: String?, orURL url: URL?) -> File? {
        if let identifier = identifier {
            return fileIndex.get(identifier).first
        }
        else if let url = url {
            return fileIndex.get(url).first
        }
        else {
            return nil
        }
    }
}
