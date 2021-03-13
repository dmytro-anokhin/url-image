//
//  URLImageFileStore.swift
//  
//
//  Created by Dmytro Anokhin on 08/01/2021.
//

import Foundation
import CoreGraphics

#if canImport(FileIndex)
import FileIndex
#endif

#if canImport(Log)
import Log
#endif

#if canImport(URLImage)
import URLImage
#endif

#if canImport(ImageDecoder)
import ImageDecoder
#endif


@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public final class URLImageFileStore {

    let fileIndex: FileIndex

    init(fileIndex: FileIndex) {
        self.fileIndex = fileIndex
    }

    public convenience init() {
        let fileIndexConfiguration = FileIndex.Configuration(name: "URLImage",
                                                             filesDirectoryName: "images",
                                                             baseDirectoryName: "URLImage")
        let fileIndex = FileIndex(configuration: fileIndexConfiguration)
        self.init(fileIndex: fileIndex)
    }

    // MARK: - Access Image Files

    public func getImageLocation(_ identifier: String,
                                 completionQueue: DispatchQueue? = nil,
                                 completion: @escaping (_ location: URL?) -> Void) {
        getImageLocation([ .identifier(identifier) ], completionQueue: completionQueue, completion: completion)
    }

    public func getImageLocation(_ url: URL,
                                 completionQueue: DispatchQueue? = nil,
                                 completion: @escaping (_ location: URL?) -> Void) {
        getImageLocation([ .url(url) ], completionQueue: completionQueue, completion: completion)
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

            let file: File?

            if let identifier = identifier {
                file = self.fileIndex.get(identifier).first
            }
            else if let url = url {
                file = self.fileIndex.get(url).first
            }
            else {
                file = nil
            }

            if let file = file {
                self.fileIndex.delete(file)
            }
        }
    }

    // MARK: - Private

    private let fileIndexQueue = DispatchQueue(label: "URLImageStore.fileIndexQueue", attributes: .concurrent)
    private let decodeQueue = DispatchQueue(label: "URLImageStore.decodeQueue", attributes: .concurrent)

    private func getImageLocation(_ keys: [URLImageStoreKey],
                                  completionQueue: DispatchQueue? = nil,
                                  completion: @escaping (_ location: URL?) -> Void) {

        fileIndexQueue.async { [weak self] in
            guard let self = self else {
                return
            }

            var file: File?

            for key in keys {
                switch key {
                    case .identifier(let identifier):
                        file = self.fileIndex.get(identifier).first
                    case .url(let url):
                        file = self.fileIndex.get(url).first
                }

                if file != nil {
                    break
                }
            }

            if let file = file {
                let location = self.fileIndex.location(of: file)
                let queue = completionQueue ?? DispatchQueue.global()

                queue.async {
                    completion(location)
                }
            }
            else {
                completion(nil)
            }
        }
    }
}


@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension URLImageFileStore: URLImageFileStoreType {

    public func removeAllImages() {
        fileIndexQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else {
                return
            }

            self.fileIndex.deleteAll()
        }
    }

    public func removeImageWithURL(_ url: URL) {
        fileIndexQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else {
                return
            }

            log_debug(self, #function, { "url = " + url.absoluteString }(), detail: log_normal)

            guard let file = self.fileIndex.get(url).first else {
                return
            }

            self.fileIndex.delete(file)
        }
    }

    public func removeImageWithIdentifier(_ identifier: String) {
        fileIndexQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else {
                return
            }

            log_debug(self, #function, { "identifier = " + identifier }(), detail: log_normal)

            guard let file = self.fileIndex.get(identifier).first else {
                return
            }

            self.fileIndex.delete(file)
        }
    }

    public func getImage<T>(_ keys: [URLImageStoreKey],
                            open: @escaping (_ location: URL) throws -> T?,
                            completion: @escaping (_ result: Result<T?, Swift.Error>) -> Void) {

        getImageLocation(keys, completionQueue: decodeQueue) { [weak self] location in
            guard let _ = self else { // Just a sanity check if the cache object is still exists
                return
            }

            guard let location = location else {
                completion(.success(nil))
                return
            }

            do {
                let object = try open(location)
                completion(.success(object))
            } catch {
                completion(.failure(error))
            }
        }
    }

    public func storeImageData(_ data: Data, info: URLImageStoreInfo) {

        fileIndexQueue.async { [weak self] in
            guard let self = self else {
                return
            }

            let fileName = UUID().uuidString
            let fileExtension = ImageDecoder.preferredFileExtension(forTypeIdentifier: info.uti)

            _ = try? self.fileIndex.write(data,
                                          originalURL: info.url,
                                          identifier: info.identifier,
                                          fileName: fileName,
                                          fileExtension: fileExtension,
                                          expireAfter: nil)
        }
    }

    public func moveImageFile(from location: URL, info: URLImageStoreInfo) {

        fileIndexQueue.async { [weak self] in
            guard let self = self else {
                return
            }

            let fileName = UUID().uuidString
            let fileExtension: String?

            if !location.pathExtension.isEmpty {
                fileExtension = location.pathExtension
            } else {
                fileExtension = ImageDecoder.preferredFileExtension(forTypeIdentifier: info.uti)
            }

            _ = try? self.fileIndex.move(location,
                                         originalURL: info.url,
                                         identifier: info.identifier,
                                         fileName: fileName,
                                         fileExtension: fileExtension,
                                         expireAfter: nil)
        }
    }
}
