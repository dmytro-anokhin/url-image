//
//  DownloadModel.swift
//  
//
//  Created by Dmytro Anokhin on 04/02/2020.
//

import Foundation
import Combine


struct DownloadConfiguration {

    let delay: TimeInterval = 0.0

    let incremental: Bool = false

    let expiryDate: Date? = nil
}


@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
final class DownloadModel<Object>: ObservableObject {

    @Published var object: Object? = nil

    let url: URL

    unowned let downloadCoordinator: URLSessionDownloadCoordinator

    let downloadConfiguration: DownloadConfiguration

    init(_ url: URL, _ downloadCoordinator: URLSessionDownloadCoordinator, _ downloadConfiguration: DownloadConfiguration = DownloadConfiguration(), _ map: @escaping (URL) -> Object?) {
        self.url = url
        self.downloadCoordinator = downloadCoordinator
        self.downloadConfiguration = downloadConfiguration

        subscriber = downloadCoordinator
            .downloadFilePublisher(with: url)
            
            // TODO: Dispatch on private queue
            // .receive(on: DispatchQueue.global())
            .compactMap { result -> Object? in
                log_debug(self, "Subscriber received result for: \(url)", detail: log_extreme)

                switch result {
                    case .success(let resultURL):
                        return map(resultURL)

                    case .failure(let error):
                        log_error(nil, "\(error)")
                        return nil
                }
            }
            // .receive(on: RunLoop.main)
            .assign(to: \.object, on: self)
    }

    /// Can be called any number of times. Download can also be initiated by another object.
    func download() {
        downloadCoordinator.downloadFile(with: url) { _ in
            // TODO: Implement or remove
        }
    }

    private var subscriber: AnyCancellable!
}
