//
//  Model.swift
//  
//
//  Created by Dmytro Anokhin on 26/01/2020.
//

import Foundation
import Combine


@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
class Model: ObservableObject {

    /// Image for incremental loading
    @Published var imageProxy: ImageProxy? = nil

    private var sub: AnyCancellable? = nil

    let downloadProgressWrapper = DownloadProgressWrapper()

    let urlRequest: URLRequest

    let services: Services

    init(_ urlRequest: URLRequest, delay: TimeInterval, incremental: Bool, expireAfter expiryDate: Date? = nil, processors: [ImageProcessing]?, services: Services) {

        self.urlRequest = urlRequest

        self.services = services

        log_debug(self, "Subscribe model: \(Unmanaged.passUnretained(self).toOpaque()) for: \(urlRequest.url!)", detail: log_extreme)

        sub = services.fileDownloadService
            .downloadFilePublisher(with: urlRequest)
            // .receive(on: DispatchQueue.global())
            .compactMap { result -> ImageWrapper? in
                log_debug(self, "Subscriber received result for: \(urlRequest.url!)", detail: log_extreme)

                switch result {
                    case .success(let resultURL):
                        if let decoder = ImageDecoder(url: resultURL), let image = decoder.createFrameImage(at: 0) {
                            return ImageWrapper(cgImage: image)
                        }
                        else {
                            log_error(self, "Image can not be decoded")
                        }

                    case .failure(let error):
                        log_error(self, "\(error)")
                }

                return nil
            }
            .receive(on: RunLoop.main)
            .assign(to: \.imageProxy, on: self)
    }

    private var item: DispatchWorkItem?

    func load() {
        guard item == nil else {
            return
        }

        item = DispatchWorkItem {
            log_debug(self, "View start load: \(self.urlRequest.url!)", detail: log_normal)

            guard self.imageProxy == nil else {
                return
            }

            self.services.fileDownloadService.downloadFile(with: self.urlRequest) { _ in
                print("TODO: Implement Completion")
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01, execute: item!)
    }

    func cancel() {
        item?.cancel()
        item = nil
    }

    deinit {
        log_debug(self, "Model \(Unmanaged.passUnretained(self).toOpaque()) deinit", detail: log_extreme)
    }
}
