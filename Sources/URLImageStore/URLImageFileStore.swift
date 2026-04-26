//
//  URLImageFileStore.swift
//  
//
//  Created by Dmytro Anokhin on 08/01/2021.
//

import Foundation
import CoreGraphics
import FileIndex
import Log
import URLImage
import ImageDecoder


@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
public final class URLImageFileStore: Sendable {

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

    // MARK: - Access Images

    public func getImage(_ identifier: String,
                         maxPixelSize: CGSize? = nil,
                         completionQueue: DispatchQueue? = nil,
                         completion: @Sendable @escaping (_ image: CGImage?) -> Void) {
        getImage([ .identifier(identifier) ], maxPixelSize: maxPixelSize, completionQueue: completionQueue, completion: completion)
    }

    public func getImage(_ url: URL,
                         maxPixelSize: CGSize? = nil,
                         completionQueue: DispatchQueue? = nil,
                         completion: @Sendable @escaping (_ image: CGImage?) -> Void) {
        getImage([ .url(url) ], maxPixelSize: maxPixelSize, completionQueue: completionQueue, completion: completion)
    }

    public func getImageLocation(_ identifier: String,
                                 completionQueue: DispatchQueue? = nil,
                                 completion: @Sendable @escaping (_ location: URL?) -> Void) {
        getImageLocation([ .identifier(identifier) ], completionQueue: completionQueue, completion: completion)
    }

    public func getImageLocation(_ url: URL,
                                 completionQueue: DispatchQueue? = nil,
                                 completion: @Sendable @escaping (_ location: URL?) -> Void) {
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

    /// The queue used to access file index
    private let fileIndexQueue = DispatchQueue(label: "URLImageStore.fileIndexQueue")

    /// The queue used to decode images
    private let decodeQueue = DispatchQueue(label: "URLImageStore.decodeQueue")

    private func getImageLocation(_ keys: [URLImageKey],
                                  completionQueue: DispatchQueue? = nil,
                                  completion: @Sendable @escaping (_ location: URL?) -> Void) {

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

    private func getImage(_ keys: [URLImageKey],
                          maxPixelSize: CGSize? = nil,
                          completionQueue: DispatchQueue? = nil,
                          completion: @Sendable @escaping (_ image: CGImage?) -> Void) {
        getImage(keys,
                 open: { location -> CGImage? in
            guard let decoder = ImageDecoder(url: location) else {
                return nil
            }
            
            if let sizeForDrawing = maxPixelSize {
                let decodingOptions = ImageDecoder.DecodingOptions(mode: .asynchronous, sizeForDrawing: sizeForDrawing)
                return decoder.createFrameImage(at: 0, decodingOptions: decodingOptions)!
            } else {
                return decoder.createFrameImage(at: 0)!
            }
        }, completion: { result in
            let queue = completionQueue ?? DispatchQueue.global()
            
            switch result {
                
            case .success(let image):
                queue.async {
                    completion(image)
                }
                
            case .failure:
                queue.async {
                    completion(nil)
                }
            }
        })
    }
}


@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
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

    public func getImage<T>(_ keys: [URLImageKey],
                            open: @Sendable @escaping (_ location: URL) throws -> T?,
                            completion: @Sendable @escaping (_ result: Result<T?, Swift.Error>) -> Void) {

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
