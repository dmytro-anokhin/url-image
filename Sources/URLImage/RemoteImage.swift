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

        typealias DecodeResult = (image: CGImage, orientation: CGImagePropertyOrientation?)

        cancellable = downloadManager.publisher(for: download)
            .tryMap { result -> DecodeResult in
                // Decode backing image
                print("Decode backing image")

                switch result {
                    case .data(let data):
                        print("Decode image from data")
                        let decoder = ImageDecoder()
                        decoder.setData(data, allDataReceived: true)

                        guard let image = decoder.createFrameImage(at: 0) else {
                            print("Fail")
                            throw Error.decode
                        }

                        print("Success")
                        let orientation = decoder.frameOrientation(at: 0)

                        return (image, orientation)

                    case .file:
                        fatalError("Not implemented")
                }
            }
            .receive(on: RunLoop.main)
            .map {
                // Instantiate `Image` object
                let image: Image

                if let cgOrientation = $0.orientation {
                    let orientation = Image.Orientation(cgOrientation)
                    image = Image(decorative: $0.image, scale: 1.0, orientation: orientation)
                }
                else {
                    image = Image(decorative: $0.image, scale: 1.0)
                }

                return .success(image)
            }
            .catch {
                // Process error
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
