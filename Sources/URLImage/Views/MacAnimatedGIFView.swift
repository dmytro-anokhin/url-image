#if os(macOS)
import AppKit
import AVFoundation
import os

@available(macOS 11.0, *)
final class MacAnimatedGIFView: PlatformView {
    private static let logger = Logger(subsystem: "com.groovy.ca", category: "GIFPlayback")

    private let displayLayer = CALayer()
    private let playerLayer = AVPlayerLayer()
    private var currentFileURL: URL?
    private var currentMaxPixelSize: CGSize?
    private var playbackMode: GIFPlaybackMode = .animated
    private var playbackEngine: GIFPlaybackEngine?
    private var posterTask: Task<Void, Never>?
    private var videoTask: Task<Void, Never>?
    private var videoPlayer: AVPlayer?
    private var currentVideoURL: URL?
    private var playbackLoopObserver: NSObjectProtocol?
    private var fallbackImage: NSImage?
    private var posterFrame: CGImage?
#if DEBUG
    private var renderedFrameCount = 0
    private var lastFrameLogTime: TimeInterval = 0
#endif

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer = CALayer()
        layer?.masksToBounds = true
        displayLayer.contentsGravity = .resizeAspect
        playerLayer.videoGravity = .resizeAspect
        playerLayer.isHidden = true
        layer?.addSublayer(displayLayer)
        layer?.addSublayer(playerLayer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layout() {
        super.layout()
        displayLayer.frame = bounds
        playerLayer.frame = bounds
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()

        guard window != nil else {
            Self.logger.debug("mac gif window detached url=\(self.currentFileURL?.lastPathComponent ?? "-", privacy: .public)")
            stopVideoPlayback(cancelTranscodeTask: true)
            playbackEngine?.showPoster()
            return
        }

        if let currentFileURL {
            applyPlaybackMode(fileURL: currentFileURL, maxPixelSize: currentMaxPixelSize)
        } else {
            applyPlaybackMode()
        }
    }

    func update(source: GIFImageSource, contentMode: GIFContentMode, playbackMode: GIFPlaybackMode, preferredMaxPixelSize: CGSize?) {
        displayLayer.contentsGravity = contentMode.layerContentsGravity
        playerLayer.videoGravity = contentMode.playerVideoGravity
        self.playbackMode = playbackMode

        switch source {
        case .image(let image):
            stopVideoPlayback(cancelTranscodeTask: true)
            currentFileURL = nil
            currentMaxPixelSize = nil
            posterTask?.cancel()
            posterTask = nil
            playbackEngine?.invalidate()
            playbackEngine = nil
            fallbackImage = image
            posterFrame = nil
            applyPlaybackMode()
        case .file(let url):
            let maxPixelSize = preferredMaxPixelSize ?? bounds.size.maxPixelSize(backingScaleFactor: window?.backingScaleFactor ?? 1)
            if currentFileURL != url || currentMaxPixelSize != maxPixelSize {
                currentFileURL = url
                currentMaxPixelSize = maxPixelSize
                fallbackImage = nil
                posterFrame = nil
#if DEBUG
                renderedFrameCount = 0
                lastFrameLogTime = 0
#endif
                posterTask?.cancel()
                posterTask = nil
                stopVideoPlayback(cancelTranscodeTask: true)
                playbackEngine?.invalidate()
                playbackEngine = nil
                displayLayer.contents = nil
            }

            applyPlaybackMode(fileURL: url, maxPixelSize: maxPixelSize)
        }
    }

    func reset() {
        Self.logger.debug("mac gif reset url=\(self.currentFileURL?.lastPathComponent ?? "-", privacy: .public)")
        currentFileURL = nil
        currentMaxPixelSize = nil
        fallbackImage = nil
        posterFrame = nil
#if DEBUG
        renderedFrameCount = 0
        lastFrameLogTime = 0
#endif
        stopVideoPlayback(cancelTranscodeTask: true)
        posterTask?.cancel()
        posterTask = nil
        playbackEngine?.invalidate()
        playbackEngine = nil
        displayLayer.contents = nil
    }

    private func applyPlaybackMode() {
        stopVideoPlayback(cancelTranscodeTask: true)
        displayLayer.isHidden = false
        displayLayer.contents = fallbackImage?.cgImage(forProposedRect: nil, context: nil, hints: nil)
    }

    private func applyPlaybackMode(fileURL: URL, maxPixelSize: CGSize?) {
        switch playbackMode {
        case .animated:
            posterTask?.cancel()
            posterTask = nil

            guard window != nil else {
                Self.logger.debug("mac gif animated requested off-window url=\(fileURL.lastPathComponent, privacy: .public)")
                stopVideoPlayback(cancelTranscodeTask: true)
                if let posterFrame {
                    displayLayer.isHidden = false
                    displayLayer.contents = posterFrame
                } else {
                    showPoster(fileURL: fileURL, maxPixelSize: maxPixelSize)
                }
                return
            }

            startVideoPlayback(fileURL: fileURL, maxPixelSize: maxPixelSize)
        case .poster:
            Self.logger.debug("mac gif poster url=\(fileURL.lastPathComponent, privacy: .public)")
            stopVideoPlayback(cancelTranscodeTask: true)
            if let posterFrame {
                displayLayer.isHidden = false
                displayLayer.contents = posterFrame
                playbackEngine?.invalidate()
                playbackEngine = nil
                posterTask?.cancel()
                posterTask = nil
                return
            }

            showPoster(fileURL: fileURL, maxPixelSize: maxPixelSize)
        }
    }

    private func showPoster(fileURL: URL, maxPixelSize: CGSize?) {
        displayLayer.isHidden = false
        playerLayer.isHidden = true

        guard posterTask == nil else {
            return
        }

        guard let playbackEngine = ensurePlaybackEngine(url: fileURL, maxPixelSize: maxPixelSize) else {
            displayLayer.contents = posterFrame
            return
        }

        posterTask = Task { [weak self, weak playbackEngine] in
            let poster = await playbackEngine?.posterFrame()
            guard !Task.isCancelled else {
                return
            }

            guard let self else {
                return
            }

            if let poster {
                self.posterFrame = poster
                self.displayLayer.contents = poster
            }

            if self.playbackMode == .poster {
                playbackEngine?.invalidate()
                if self.playbackEngine === playbackEngine {
                    self.playbackEngine = nil
                }
            } else if self.videoTask != nil {
                playbackEngine?.invalidate()
                if self.playbackEngine === playbackEngine {
                    self.playbackEngine = nil
                }
            }

            self.posterTask = nil
        }
    }

    private func startVideoPlayback(fileURL: URL, maxPixelSize: CGSize?) {
        if let currentVideoURL,
           currentVideoURL == GIFVideoTranscodeCache.shared.cachedVideoURL(for: fileURL, maxPixelSize: maxPixelSize),
           videoPlayer != nil {
            displayLayer.isHidden = true
            playerLayer.isHidden = false
            videoPlayer?.play()
            return
        }

        if let cachedVideoURL = GIFVideoTranscodeCache.shared.cachedVideoURL(for: fileURL, maxPixelSize: maxPixelSize) {
            startVideoPlayer(videoURL: cachedVideoURL, sourceURL: fileURL)
            return
        }

        showPoster(fileURL: fileURL, maxPixelSize: maxPixelSize)

        guard videoTask == nil else {
            return
        }

        Self.logger.notice("mac gif video requested source=\(fileURL.lastPathComponent, privacy: .public) maxPixel=\(String(describing: maxPixelSize), privacy: .public)")
        videoTask = Task { @MainActor [weak self] in
            do {
                let videoURL = try await GIFVideoTranscodeCache.shared.videoURL(for: fileURL, maxPixelSize: maxPixelSize)
                guard !Task.isCancelled,
                      let self,
                      self.currentFileURL == fileURL,
                      self.playbackMode == .animated,
                      self.window != nil else {
                    return
                }

                self.videoTask = nil
                self.startVideoPlayer(videoURL: videoURL, sourceURL: fileURL)
            } catch is CancellationError {
                guard let self, self.currentFileURL == fileURL else {
                    return
                }
                self.videoTask = nil
            } catch {
                guard let self,
                      self.currentFileURL == fileURL,
                      self.playbackMode == .animated,
                      self.window != nil else {
                    return
                }

                self.videoTask = nil
                self.startFrameEngineFallback(fileURL: fileURL, maxPixelSize: maxPixelSize, error: error)
            }
        }
    }

    private func startVideoPlayer(videoURL: URL, sourceURL: URL) {
        if currentVideoURL == videoURL, videoPlayer != nil {
            displayLayer.isHidden = true
            playerLayer.isHidden = false
            videoPlayer?.play()
            return
        }

        stopVideoPlayback(cancelTranscodeTask: false)
        playbackEngine?.invalidate()
        playbackEngine = nil

        let playerItem = AVPlayerItem(url: videoURL)
        let player = AVPlayer(playerItem: playerItem)
        player.actionAtItemEnd = .none
        videoPlayer = player
        currentVideoURL = videoURL
        playerLayer.player = player
        displayLayer.isHidden = true
        playerLayer.isHidden = false
        playbackLoopObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime,
                                                                       object: playerItem,
                                                                       queue: .main) { [weak player] _ in
            Task { @MainActor [weak player] in
                player?.seek(to: .zero)
                player?.play()
            }
        }

        Self.logger.notice("mac gif video play source=\(sourceURL.lastPathComponent, privacy: .public) video=\(videoURL.lastPathComponent, privacy: .public)")
        player.play()
    }

    private func startFrameEngineFallback(fileURL: URL, maxPixelSize: CGSize?, error: Error) {
        Self.logger.error("mac gif video fallback source=\(fileURL.lastPathComponent, privacy: .public) error=\(String(describing: error), privacy: .public)")
        stopVideoPlayback(cancelTranscodeTask: false)
        displayLayer.isHidden = false

        guard let playbackEngine = ensurePlaybackEngine(url: fileURL, maxPixelSize: maxPixelSize) else {
            displayLayer.contents = posterFrame
            return
        }

        Self.logger.debug("mac gif start url=\(fileURL.lastPathComponent, privacy: .public) maxPixel=\(String(describing: maxPixelSize), privacy: .public)")
        playbackEngine.start()
    }

    private func stopVideoPlayback(cancelTranscodeTask: Bool) {
        if cancelTranscodeTask {
            videoTask?.cancel()
            videoTask = nil
        }

        if let playbackLoopObserver {
            NotificationCenter.default.removeObserver(playbackLoopObserver)
            self.playbackLoopObserver = nil
        }

        videoPlayer?.pause()
        videoPlayer?.replaceCurrentItem(with: nil)
        videoPlayer = nil
        currentVideoURL = nil
        playerLayer.player = nil
        playerLayer.isHidden = true
        displayLayer.isHidden = false
    }

    private func ensurePlaybackEngine(url: URL, maxPixelSize: CGSize?) -> GIFPlaybackEngine? {
        if let playbackEngine {
            return playbackEngine
        }

        let playbackEngine = GIFPlaybackEngine(url: url, maxPixelSize: maxPixelSize) { [weak self] frame in
            guard let self else {
                return
            }

            if self.posterFrame == nil {
                self.posterFrame = frame
            }

            self.displayLayer.isHidden = false
            self.displayLayer.contents = frame
#if DEBUG
            self.renderedFrameCount += 1
            let now = ProcessInfo.processInfo.systemUptime
            if self.renderedFrameCount <= 3 || now - self.lastFrameLogTime >= 1 {
                self.lastFrameLogTime = now
                Self.logger.debug("mac gif frame url=\(self.currentFileURL?.lastPathComponent ?? "-", privacy: .public) count=\(self.renderedFrameCount, privacy: .public) window=\(self.window != nil, privacy: .public) mode=\(String(describing: self.playbackMode), privacy: .public)")
            }
#endif
        }
        self.playbackEngine = playbackEngine
        return playbackEngine
    }
}

private extension GIFContentMode {
    var layerContentsGravity: CALayerContentsGravity {
        switch self {
        case .fit:
            return .resizeAspect
        case .fill:
            return .resizeAspectFill
        }
    }

    var playerVideoGravity: AVLayerVideoGravity {
        switch self {
        case .fit:
            return .resizeAspect
        case .fill:
            return .resizeAspectFill
        }
    }
}

private extension CGSize {
    func maxPixelSize(backingScaleFactor: CGFloat) -> CGSize? {
        guard width > 0, height > 0 else {
            return nil
        }

        return applying(.init(scaleX: backingScaleFactor, y: backingScaleFactor))
    }
}
#endif
