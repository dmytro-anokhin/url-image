//
//  DiskCache.swift
//  
//
//  Created by Dmytro Anokhin on 02/10/2020.
//

import Foundation
import Combine
import FileIndex


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

    func image(with url: URL) throws -> TransientImage? {
        guard let file = fileIndex.get(url).first else {
            return nil
        }

        let location = fileIndex.location(of: file)

        return try TransientImage.decode(location)
    }

    func image(with url: URL, _ completion: @escaping (_ result: Result<TransientImage?, Swift.Error>) -> Void) {
        DispatchQueue.global().async { [weak self] in
            guard let self = self else {
                return
            }

            do {
                let transientImage = try self.image(with: url)
                completion(.success(transientImage))
            }
            catch {
                completion(.failure(error))
            }
        }
    }

    func imagePublisher(with url: URL) -> AnyPublisher<TransientImage?, Swift.Error> {
        return Future<TransientImage?, Swift.Error> { [weak self] promise in
            guard let self = self else {
                return
            }

            self.image(with: url) {
                promise($0)
            }
        }.eraseToAnyPublisher()
    }

    func cacheImageData(_ data: Data, for url: URL) {
        _ = try? fileIndex.write(data, originalURL: url)
    }
}
