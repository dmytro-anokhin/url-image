#if os(macOS)
import Foundation
import CoreGraphics
import ImageDecoder

@available(macOS 11.0, *)
@MainActor
final class GIFPlaybackEngine {
    typealias FrameHandler = @MainActor (CGImage?) -> Void

    private let decoder: ImageDecoder
    private let maxPixelSize: CGSize?
    private let frameHandler: FrameHandler
    private let frameCount: Int
    private let frameDurations: [TimeInterval]

    private var playbackTask: Task<Void, Never>?
    private var decodeTasks: [Int: Task<CGImage?, Never>] = [:]
    private var frameCache: [Int: CGImage] = [:]

    private let prefetchDepth = 1

    init?(url: URL, maxPixelSize: CGSize?, frameHandler: @escaping FrameHandler) {
        guard let decoder = ImageDecoder(url: url) else {
            return nil
        }

        let frameCount = max(decoder.frameCount, 1)

        self.decoder = decoder
        self.maxPixelSize = maxPixelSize
        self.frameHandler = frameHandler
        self.frameCount = frameCount
        self.frameDurations = (0..<frameCount).map { index in
            max(decoder.frameDuration(at: index) ?? 0.1, 0.02)
        }
    }

    func start() {
        guard playbackTask == nil else {
            return
        }

        playbackTask = Task { [weak self] in
            await self?.runPlaybackLoop()
        }
    }

    func showPoster() {
        stopPlayback(keepPoster: true)

        Task { [weak self] in
            guard let self else {
                return
            }

            let poster = await frame(at: 0)
            frameHandler(poster)
        }
    }

    func posterFrame() async -> CGImage? {
        await frame(at: 0)
    }

    func invalidate() {
        stopPlayback(keepPoster: false)
        frameCache.removeAll()
        decodeTasks.values.forEach { $0.cancel() }
        decodeTasks.removeAll()
    }

    private func runPlaybackLoop() async {
        var frameIndex = 0

        while !Task.isCancelled {
            let frame = await frame(at: frameIndex)
            guard !Task.isCancelled else {
                break
            }
            frameHandler(frame)
            prefetchFrames(after: frameIndex)

            let delay = frameDurations[frameIndex]
            let sleepNanoseconds = UInt64(delay * 1_000_000_000)
            try? await Task.sleep(nanoseconds: sleepNanoseconds)

            frameIndex = (frameIndex + 1) % frameCount
        }
    }

    private func frame(at index: Int) async -> CGImage? {
        if let cached = frameCache[index] {
            return cached
        }

        if let existingTask = decodeTasks[index] {
            let image = await existingTask.value
            if let image {
                cache(image, for: index)
            }
            return image
        }

        let task = Task.detached(priority: .utility) { [decoder, maxPixelSize] () -> CGImage? in
            guard !Task.isCancelled else {
                return nil
            }
            let decodingOptions = ImageDecoder.DecodingOptions(mode: .asynchronous, sizeForDrawing: maxPixelSize)
            let image = decoder.createFrameImage(at: index, decodingOptions: decodingOptions)
            guard !Task.isCancelled else {
                return nil
            }
            return image
        }

        decodeTasks[index] = task
        let image = await task.value
        decodeTasks[index] = nil

        if let image {
            cache(image, for: index)
        }

        return image
    }

    private func prefetchFrames(after index: Int) {
        guard frameCount > 1 else {
            return
        }

        for offset in 1...prefetchDepth {
            let nextIndex = (index + offset) % frameCount
            guard frameCache[nextIndex] == nil, decodeTasks[nextIndex] == nil else {
                continue
            }

            decodeTasks[nextIndex] = Task.detached(priority: .background) { [decoder, maxPixelSize] () -> CGImage? in
                guard !Task.isCancelled else {
                    return nil
                }
                let decodingOptions = ImageDecoder.DecodingOptions(mode: .asynchronous, sizeForDrawing: maxPixelSize)
                let image = decoder.createFrameImage(at: nextIndex, decodingOptions: decodingOptions)
                guard !Task.isCancelled else {
                    return nil
                }
                return image
            }
        }
    }

    private func cache(_ image: CGImage, for index: Int) {
        frameCache[index] = image

        let keepIndices = Set([
            0,
            index,
            (index + 1) % frameCount
        ])

        frameCache = frameCache.filter { keepIndices.contains($0.key) }

        for key in Array(decodeTasks.keys) where !keepIndices.contains(key) {
            decodeTasks[key]?.cancel()
            decodeTasks[key] = nil
        }
    }

    private func stopPlayback(keepPoster: Bool) {
        playbackTask?.cancel()
        playbackTask = nil

        decodeTasks.values.forEach { $0.cancel() }
        decodeTasks.removeAll()

        if keepPoster, let poster = frameCache[0] {
            frameCache = [0: poster]
        } else if !keepPoster {
            frameCache.removeAll()
        }
    }
}
#endif
