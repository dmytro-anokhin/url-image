//
//  DiskCache.swift
//  
//
//  Created by Dmytro Anokhin on 02/10/2020.
//

import Foundation
import CoreGraphics
import Combine

#if canImport(FileIndex)
import FileIndex
#endif

#if canImport(Log)
import Log
#endif


@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
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
        fileIndexQueue.async { [weak self] in
            guard let self = self else { return }

            guard let file = self.getFile(withIdentifier: identifier, orURL: url) else {
                completion(.success(nil))
                return
            }

            let location = self.fileIndex.location(of: file)

            self.decodeQueue.async { [weak self] in
                guard let _ = self else { return }

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
        fileIndexQueue.async { [weak self] in
            guard let self = self else {
                return
            }

            _ = try? self.fileIndex.write(data,
                                          originalURL: url,
                                          identifier: identifier,
                                          fileName: fileName,
                                          fileExtension: fileExtension,
                                          expireAfter: expiryInterval)
        }
    }

    func cacheImageFile(at location: URL, url: URL, identifier: String?, fileName: String?, fileExtension: String?, expireAfter expiryInterval: TimeInterval?) {
        fileIndexQueue.async { [weak self] in
            guard let self = self else {
                return
            }

            _ = try? self.fileIndex.move(location,
                                         originalURL: url,
                                         identifier: identifier,
                                         fileName: fileName,
                                         fileExtension: fileExtension,
                                         expireAfter: expiryInterval)
        }
    }

    // MARK: - Cleanup

    func cleanup() {
        fileIndexQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else {
                return
            }

            self.fileIndex.deleteExpired()
        }
    }

    func deleteAll() {
        fileIndexQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else {
                return
            }

            self.fileIndex.deleteAll()
        }
    }

    func delete(withIdentifier identifier: String?, orURL url: URL?) {
        fileIndexQueue.async(flags: .barrier) { [weak self] in
            log_debug(self, #function, {
                if let identifier = identifier {
                    return "identifier = " + identifier
                }

                if let url = url {
                    return "url = " + url.absoluteString
                }

                return "No identifier or url"
            }(), detail: log_normal)

            guard let self = self else {
                return
            }

            guard let file = self.getFile(withIdentifier: identifier, orURL: url) else {
                return
            }

            self.fileIndex.delete(file)
        }
    }

    // MARK: - Private

    private let fileIndexQueue = DispatchQueue(label: "URLImage.DiskCache.fileIndexQueue", attributes: .concurrent)
    private let decodeQueue = DispatchQueue(label: "URLImage.DiskCache.decodeQueue", attributes: .concurrent)

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
