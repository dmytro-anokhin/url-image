//
//  RemoteImage.swift
//  
//
//  Created by Dmytro Anokhin on 25/08/2020.
//

import Combine
import SwiftUI
import DownloadManager
import RemoteContentView
import ImageDecoder


@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public final class RemoteImage : RemoteContent {

    public enum Error : Swift.Error {

        case decode
    }

    /// Reference to the download manager used to download the image.
    unowned let downloadManager: DownloadManager

    /// Download object describes how the image should be downloaded.
    let download: Download

    init(downloadManager: DownloadManager, download: Download) {
        self.downloadManager = downloadManager
        self.download = download
    }

    deinit {
        print("deinit \(self)")
    }

    @Published public private(set) var loadingState: RemoteContentLoadingState<Image, Float?> = .initial {
        didSet {
            print("Loading state did change from: \(oldValue), to: \(loadingState)")
        }
    }

    public func load() {
        guard !loadingState.isInProgress else {
            return
        }

        loadingState = .inProgress(nil)

        cancellable = downloadManager.publisher(for: download)
            .tryMap(TransientImage.decode)
            .receive(on: RunLoop.main)
            .map {
                .success(Image(transientImage: $0))
            }
            .catch {
                Just(.failure($0))
            }
            .assign(to: \.loadingState, on: self)
    }

    public func cancel() {
        guard loadingState.isInProgress else {
            return
        }

        // Reset loading state
        loadingState = .initial

        // Stop loading
        cancellable?.cancel()
        cancellable = nil
    }

    private var cancellable: AnyCancellable?
}


fileprivate struct TransientImage {

    static func decode(_ downloadResult: DownloadResult) throws -> TransientImage {

        switch downloadResult {
            case .data(let data):
                let decoder = ImageDecoder()
                decoder.setData(data, allDataReceived: true)

                guard let image = decoder.createFrameImage(at: 0) else {
                    throw RemoteImage.Error.decode
                }

                return TransientImage(cgImage: image,
                                    cgOrientation: decoder.frameOrientation(at: 0))

            case .file:
                fatalError("Not implemented")
        }
    }

    var cgImage: CGImage

    var cgOrientation: CGImagePropertyOrientation?
}


fileprivate extension Image {

    init(transientImage: TransientImage) {
        if let cgOrientation = transientImage.cgOrientation {
            let orientation = Image.Orientation(cgOrientation)
            self.init(decorative: transientImage.cgImage, scale: 1.0, orientation: orientation)
        }
        else {
            self.init(decorative: transientImage.cgImage, scale: 1.0)
        }
    }
}
