#if os(macOS)
@preconcurrency import Foundation
@preconcurrency import AVFoundation
import CoreGraphics
import CryptoKit
@preconcurrency import ImageIO
import os
import URLImageFFmpeg

@available(macOS 11.0, *)
actor GIFVideoTranscodeCache {
    static let shared = GIFVideoTranscodeCache()

    private static let logger = Logger(subsystem: "com.groovy.ca", category: "GIFPlayback")
    private static let transcodeLimiter = GIFVideoTranscodeLimiter(maxConcurrentJobs: 1)
    private static let cacheFormatVersion = "upright-v2"

    private var activeTasks: [String: Task<URL, Error>] = [:]

    nonisolated func cachedVideoURL(for gifURL: URL, maxPixelSize: CGSize?) -> URL? {
        guard let location = try? Self.cacheLocation(for: gifURL, maxPixelSize: maxPixelSize),
              FileManager.default.fileExists(atPath: location.videoURL.path) else {
            return nil
        }

        return location.videoURL
    }

    func videoURL(for gifURL: URL, maxPixelSize: CGSize?) async throws -> URL {
        let location = try Self.cacheLocation(for: gifURL, maxPixelSize: maxPixelSize)

        if FileManager.default.fileExists(atPath: location.videoURL.path) {
            Self.logger.notice("gif video cache hit source=\(gifURL.lastPathComponent, privacy: .public) video=\(location.videoURL.lastPathComponent, privacy: .public)")
            return location.videoURL
        }

        if let task = activeTasks[location.key] {
            Self.logger.notice("gif video transcode join source=\(gifURL.lastPathComponent, privacy: .public)")
            return try await task.value
        }

        let task = Task(priority: .utility) {
            try await Self.withTranscodePermit {
                try await Self.transcode(gifURL: gifURL,
                                         outputURL: location.videoURL,
                                         temporaryURL: location.temporaryURL,
                                         maxPixelSize: maxPixelSize)
            }
        }

        activeTasks[location.key] = task
        defer {
            activeTasks[location.key] = nil
        }

        return try await task.value
    }

    private static func withTranscodePermit<T>(_ operation: () async throws -> T) async throws -> T {
        await transcodeLimiter.acquire()

        do {
            let value = try await operation()
            await transcodeLimiter.release()
            return value
        } catch {
            await transcodeLimiter.release()
            throw error
        }
    }

    private static func transcode(gifURL: URL,
                                  outputURL: URL,
                                  temporaryURL: URL,
                                  maxPixelSize: CGSize?) async throws -> URL {
        try Task.checkCancellation()
        try FileManager.default.createDirectory(at: outputURL.deletingLastPathComponent(),
                                                withIntermediateDirectories: true)
        try? FileManager.default.removeItem(at: temporaryURL)

        let startedAt = ProcessInfo.processInfo.systemUptime
        logger.notice("gif video transcode start source=\(gifURL.lastPathComponent, privacy: .public) output=\(outputURL.lastPathComponent, privacy: .public) maxPixel=\(String(describing: maxPixelSize), privacy: .public)")

        do {
            if EmbeddedFFmpegGIFTranscoder.isLinked {
                logger.notice("gif video embedded ffmpeg source=\(gifURL.lastPathComponent, privacy: .public) config=\(EmbeddedFFmpegGIFTranscoder.configuration, privacy: .public)")
                try await runEmbeddedFFmpeg(sourceURL: gifURL,
                                            outputURL: temporaryURL,
                                            maxPixelSize: maxPixelSize)
            } else {
                logger.notice("gif video embedded ffmpeg unavailable, using avasset source=\(gifURL.lastPathComponent, privacy: .public) config=\(EmbeddedFFmpegGIFTranscoder.configuration, privacy: .public)")
                try await runAVAssetWriterTranscode(sourceURL: gifURL,
                                                    outputURL: temporaryURL,
                                                    maxPixelSize: maxPixelSize)
            }
            try Task.checkCancellation()

            if FileManager.default.fileExists(atPath: outputURL.path) {
                try FileManager.default.removeItem(at: outputURL)
            }

            try FileManager.default.moveItem(at: temporaryURL, to: outputURL)
            let elapsed = ProcessInfo.processInfo.systemUptime - startedAt
            logger.notice("gif video transcode finish source=\(gifURL.lastPathComponent, privacy: .public) elapsed=\(elapsed, privacy: .public)")
            return outputURL
        } catch {
            try? FileManager.default.removeItem(at: temporaryURL)
            logger.error("gif video transcode fail source=\(gifURL.lastPathComponent, privacy: .public) error=\(String(describing: error), privacy: .public)")
            throw error
        }
    }

    private static func runEmbeddedFFmpeg(sourceURL: URL,
                                          outputURL: URL,
                                          maxPixelSize: CGSize?) async throws {
        let request = FFmpegGIFTranscodeRequest(sourceURL: sourceURL,
                                                outputURL: outputURL,
                                                maxPixelSize: maxPixelSize)
        let transcoder = EmbeddedFFmpegGIFTranscoder(preset: .appleH264)

        try await Task.detached(priority: .utility) {
            try Task.checkCancellation()
            try transcoder.transcode(request)
            try Task.checkCancellation()
        }.value
    }

    private static func runAVAssetWriterTranscode(sourceURL: URL,
                                                  outputURL: URL,
                                                  maxPixelSize: CGSize?) async throws {
        try Task.checkCancellation()

        guard let imageSource = CGImageSourceCreateWithURL(sourceURL as CFURL, nil) else {
            throw GIFVideoTranscodeError.imageSourceUnavailable
        }

        let frameCount = max(CGImageSourceGetCount(imageSource), 1)
        guard let firstFrame = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            throw GIFVideoTranscodeError.frameUnavailable(index: 0)
        }

        let videoSize = outputVideoSize(sourceWidth: firstFrame.width,
                                        sourceHeight: firstFrame.height,
                                        maxPixelSize: maxPixelSize)
        let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
        let input = AVAssetWriterInput(mediaType: .video,
                                       outputSettings: videoOutputSettings(videoSize: videoSize))
        input.expectsMediaDataInRealTime = false

        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input,
                                                           sourcePixelBufferAttributes: pixelBufferAttributes(videoSize: videoSize))

        guard writer.canAdd(input) else {
            throw GIFVideoTranscodeError.assetWriterInputRejected
        }

        writer.add(input)

        guard writer.startWriting() else {
            throw writer.error ?? GIFVideoTranscodeError.assetWriterFailed("startWriting failed")
        }

        writer.startSession(atSourceTime: .zero)
        try await appendFrames(from: imageSource,
                               frameCount: frameCount,
                               videoSize: videoSize,
                               input: input,
                               adaptor: adaptor)
        try await finishWriting(writer)
    }

    private static func appendFrames(from imageSource: CGImageSource,
                                     frameCount: Int,
                                     videoSize: VideoSize,
                                     input: AVAssetWriterInput,
                                     adaptor: AVAssetWriterInputPixelBufferAdaptor) async throws {
        let queue = DispatchQueue(label: "com.groovy.ca.gif-video-transcode.writer", qos: .utility)

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let appender = FrameAppender(imageSource: imageSource,
                                         frameCount: frameCount,
                                         videoSize: videoSize,
                                         input: input,
                                         adaptor: adaptor)

            input.requestMediaDataWhenReady(on: queue) {
                appender.appendReadyFrames(continuation: continuation)
            }
        }
    }

    private final class FrameAppender: @unchecked Sendable {
        private let imageSource: CGImageSource
        private let frameCount: Int
        private let videoSize: VideoSize
        private let input: AVAssetWriterInput
        private let adaptor: AVAssetWriterInputPixelBufferAdaptor
        private let timescale: CMTimeScale = 600

        private var frameIndex = 0
        private var presentationTime = CMTime.zero
        private var lastImage: CGImage?
        private var appendedTerminalFrame = false
        private var resumed = false

        init(imageSource: CGImageSource,
             frameCount: Int,
             videoSize: VideoSize,
             input: AVAssetWriterInput,
             adaptor: AVAssetWriterInputPixelBufferAdaptor) {
            self.imageSource = imageSource
            self.frameCount = frameCount
            self.videoSize = videoSize
            self.input = input
            self.adaptor = adaptor
        }

        func appendReadyFrames(continuation: CheckedContinuation<Void, Error>) {
            guard !resumed else {
                return
            }

            do {
                while input.isReadyForMoreMediaData {
                    if frameIndex < frameCount {
                        guard let image = CGImageSourceCreateImageAtIndex(imageSource, frameIndex, nil) else {
                            throw GIFVideoTranscodeError.frameUnavailable(index: frameIndex)
                        }

                        let pixelBuffer = try makePixelBuffer(image: image,
                                                              videoSize: videoSize,
                                                              adaptor: adaptor)
                        guard adaptor.append(pixelBuffer, withPresentationTime: presentationTime) else {
                            throw GIFVideoTranscodeError.assetWriterFailed("append failed")
                        }

                        lastImage = image
                        presentationTime = presentationTime + CMTime(seconds: frameDuration(imageSource: imageSource, index: frameIndex),
                                                                     preferredTimescale: timescale)
                        frameIndex += 1
                    } else if !appendedTerminalFrame, let lastImage {
                        let pixelBuffer = try makePixelBuffer(image: lastImage,
                                                              videoSize: videoSize,
                                                              adaptor: adaptor)
                        guard adaptor.append(pixelBuffer, withPresentationTime: presentationTime) else {
                            throw GIFVideoTranscodeError.assetWriterFailed("append terminal frame failed")
                        }
                        appendedTerminalFrame = true
                    } else {
                        input.markAsFinished()
                        resumed = true
                        continuation.resume(returning: ())
                        return
                    }
                }
            } catch {
                input.markAsFinished()
                resumed = true
                continuation.resume(throwing: error)
            }
        }
    }

    private static func finishWriting(_ writer: AVAssetWriter) async throws {
        await withCheckedContinuation { continuation in
            writer.finishWriting {
                continuation.resume()
            }
        }

        guard writer.status == .completed else {
            throw writer.error ?? GIFVideoTranscodeError.assetWriterFailed("finishWriting status=\(writer.status.rawValue)")
        }
    }

    private static func makePixelBuffer(image: CGImage,
                                        videoSize: VideoSize,
                                        adaptor: AVAssetWriterInputPixelBufferAdaptor) throws -> CVPixelBuffer {
        guard let pixelBufferPool = adaptor.pixelBufferPool else {
            throw GIFVideoTranscodeError.pixelBufferPoolUnavailable
        }

        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferPoolCreatePixelBuffer(nil, pixelBufferPool, &pixelBuffer)
        guard status == kCVReturnSuccess, let pixelBuffer else {
            throw GIFVideoTranscodeError.pixelBufferCreationFailed(status)
        }

        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        defer {
            CVPixelBufferUnlockBaseAddress(pixelBuffer, [])
        }

        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else {
            throw GIFVideoTranscodeError.pixelBufferBaseAddressUnavailable
        }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo.byteOrder32Little.union(CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue))
        guard let context = CGContext(data: baseAddress,
                                      width: videoSize.width,
                                      height: videoSize.height,
                                      bitsPerComponent: 8,
                                      bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
                                      space: colorSpace,
                                      bitmapInfo: bitmapInfo.rawValue) else {
            throw GIFVideoTranscodeError.pixelBufferContextUnavailable
        }

        let rect = CGRect(x: 0, y: 0, width: videoSize.width, height: videoSize.height)
        context.clear(rect)
        context.interpolationQuality = .medium
        // AVAssetWriter displays this pixel buffer upright when the ImageIO frame is drawn directly.
        context.draw(image, in: rect)
        return pixelBuffer
    }

    private static func videoOutputSettings(videoSize: VideoSize) -> [String: Any] {
        [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: videoSize.width,
            AVVideoHeightKey: videoSize.height,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: max(400_000, videoSize.width * videoSize.height * 4),
                AVVideoProfileLevelKey: AVVideoProfileLevelH264MainAutoLevel
            ]
        ]
    }

    private static func pixelBufferAttributes(videoSize: VideoSize) -> [String: Any] {
        [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String: videoSize.width,
            kCVPixelBufferHeightKey as String: videoSize.height,
            kCVPixelBufferIOSurfacePropertiesKey as String: [:]
        ]
    }

    private static func outputVideoSize(sourceWidth: Int, sourceHeight: Int, maxPixelSize: CGSize?) -> VideoSize {
        var width = max(2, sourceWidth)
        var height = max(2, sourceHeight)

        if let maxPixelSize,
           maxPixelSize.width > 1,
           maxPixelSize.height > 1 {
            let scale = min(1,
                            maxPixelSize.width / CGFloat(width),
                            maxPixelSize.height / CGFloat(height))
            width = max(2, Int((CGFloat(width) * scale).rounded(.down)))
            height = max(2, Int((CGFloat(height) * scale).rounded(.down)))
        }

        width -= width % 2
        height -= height % 2
        return VideoSize(width: max(2, width), height: max(2, height))
    }

    private static func frameDuration(imageSource: CGImageSource, index: Int) -> TimeInterval {
        guard let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, index, nil) as? [CFString: Any],
              let gifProperties = properties[kCGImagePropertyGIFDictionary] as? [CFString: Any] else {
            return 0.1
        }

        let unclampedDelay = gifProperties[kCGImagePropertyGIFUnclampedDelayTime] as? TimeInterval
        let clampedDelay = gifProperties[kCGImagePropertyGIFDelayTime] as? TimeInterval
        return max(unclampedDelay ?? clampedDelay ?? 0.1, 0.02)
    }

    private static func cacheLocation(for gifURL: URL, maxPixelSize: CGSize?) throws -> CacheLocation {
        guard let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            throw GIFVideoTranscodeError.cacheDirectoryUnavailable
        }

        let attributes = try? FileManager.default.attributesOfItem(atPath: gifURL.path)
        let modifiedAt = (attributes?[.modificationDate] as? Date)?.timeIntervalSince1970 ?? 0
        let fileSize = (attributes?[.size] as? NSNumber)?.int64Value ?? 0
        let pixelKey = pixelCacheKey(maxPixelSize)
        let rawKey = "\(cacheFormatVersion)|\(gifURL.path)|\(modifiedAt)|\(fileSize)|\(pixelKey)"
        let digest = SHA256.hash(data: Data(rawKey.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
        let directory = cachesDirectory.appendingPathComponent("URLImageGIFVideoCache", isDirectory: true)
        let videoURL = directory.appendingPathComponent(digest).appendingPathExtension("mp4")
        let temporaryURL = directory.appendingPathComponent("\(digest)-\(UUID().uuidString).tmp").appendingPathExtension("mp4")

        return CacheLocation(key: digest, videoURL: videoURL, temporaryURL: temporaryURL)
    }

    private static func pixelCacheKey(_ maxPixelSize: CGSize?) -> String {
        guard let maxPixelSize else {
            return "original"
        }

        let width = max(0, Int(maxPixelSize.width.rounded(.up)))
        let height = max(0, Int(maxPixelSize.height.rounded(.up)))
        return "\(width)x\(height)"
    }
}

@available(macOS 11.0, *)
private actor GIFVideoTranscodeLimiter {
    private let maxConcurrentJobs: Int
    private var runningJobs = 0
    private var waiters: [CheckedContinuation<Void, Never>] = []

    init(maxConcurrentJobs: Int) {
        self.maxConcurrentJobs = max(1, maxConcurrentJobs)
    }

    func acquire() async {
        if runningJobs < maxConcurrentJobs {
            runningJobs += 1
            return
        }

        await withCheckedContinuation { continuation in
            waiters.append(continuation)
        }
    }

    func release() {
        if waiters.isEmpty {
            runningJobs = max(0, runningJobs - 1)
        } else {
            waiters.removeFirst().resume()
        }
    }
}

private struct CacheLocation: Sendable {
    let key: String
    let videoURL: URL
    let temporaryURL: URL
}

private struct VideoSize: Sendable {
    let width: Int
    let height: Int
}

private enum GIFVideoTranscodeError: Error, CustomStringConvertible {
    case cacheDirectoryUnavailable
    case imageSourceUnavailable
    case frameUnavailable(index: Int)
    case assetWriterInputRejected
    case assetWriterFailed(String)
    case pixelBufferPoolUnavailable
    case pixelBufferCreationFailed(CVReturn)
    case pixelBufferBaseAddressUnavailable
    case pixelBufferContextUnavailable

    var description: String {
        switch self {
        case .cacheDirectoryUnavailable:
            return "cache directory unavailable"
        case .imageSourceUnavailable:
            return "image source unavailable"
        case .frameUnavailable(let index):
            return "frame unavailable index=\(index)"
        case .assetWriterInputRejected:
            return "asset writer input rejected"
        case .assetWriterFailed(let message):
            return "asset writer failed \(message)"
        case .pixelBufferPoolUnavailable:
            return "pixel buffer pool unavailable"
        case .pixelBufferCreationFailed(let status):
            return "pixel buffer creation failed status=\(status)"
        case .pixelBufferBaseAddressUnavailable:
            return "pixel buffer base address unavailable"
        case .pixelBufferContextUnavailable:
            return "pixel buffer context unavailable"
        }
    }
}
#endif
