//
//  URLImageStore.swift
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


@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public final class URLImageStore {

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
}


@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension URLImageStore: URLImageCache {

    public func getImage<T>(_ key: URLImageCacheKey,
                            open: @escaping (_ location: URL) throws -> T?,
                            completion: @escaping (_ result: Result<T?, Swift.Error>) -> Void) {

        fileIndexQueue.async { [weak self] in
            guard let self = self else {
                return
            }

            let file: File?

            switch key {
                case .identifier(let identifier):
                    file = self.fileIndex.get(identifier).first
                case .url(let url):
                    file = self.fileIndex.get(url).first
            }

            if let file = file {
                let location = self.fileIndex.location(of: file)

                self.decodeQueue.async { [weak self] in
                    guard let _ = self else { // Just a sanity check if the cache object is still exists
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
            else {
                completion(.success(nil))
            }
        }
    }

    public func cacheImageData(_ data: Data,
                               url: URL,
                               identifier: String?,
                               fileName: String?,
                               fileExtension: String?,
                               expireAfter expiryInterval: TimeInterval?) {

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

    public func cacheImageFile(at location: URL,
                               url: URL,
                               identifier: String?,
                               fileName: String?,
                               fileExtension: String?,
                               expireAfter expiryInterval: TimeInterval?) {

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
}
