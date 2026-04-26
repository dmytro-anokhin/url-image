import CoreGraphics
import Foundation
import CURLImageFFmpeg

public struct FFmpegGIFTranscodeRequest: Sendable {
    public var sourceURL: URL
    public var outputURL: URL
    public var maxPixelSize: CGSize?

    public init(sourceURL: URL, outputURL: URL, maxPixelSize: CGSize?) {
        self.sourceURL = sourceURL
        self.outputURL = outputURL
        self.maxPixelSize = maxPixelSize
    }
}

public struct FFmpegGIFTranscodePreset: Sendable {
    public var encoderArguments: [String]
    public var threadCount: Int

    public init(encoderArguments: [String], threadCount: Int = 2) {
        self.encoderArguments = encoderArguments
        self.threadCount = max(1, threadCount)
    }

    public static let appleH264 = FFmpegGIFTranscodePreset(
        encoderArguments: [
            "-c:v", "h264_videotoolbox",
            "-b:v", "1200k"
        ]
    )

    public static let softwareX264 = FFmpegGIFTranscodePreset(
        encoderArguments: [
            "-c:v", "libx264",
            "-preset", "veryfast",
            "-crf", "24"
        ]
    )

    public func processArguments(for request: FFmpegGIFTranscodeRequest) -> [String] {
        var arguments = [
            "-y",
            "-hide_banner",
            "-loglevel", "error",
            "-i", request.sourceURL.path,
            "-an",
            "-movflags", "+faststart",
            "-pix_fmt", "yuv420p"
        ]

        arguments.append(contentsOf: encoderArguments)
        arguments.append(contentsOf: ["-threads", "\(threadCount)"])
        arguments.append(contentsOf: ["-vf", Self.videoFilter(maxPixelSize: request.maxPixelSize)])
        arguments.append(request.outputURL.path)
        return arguments
    }

    public static func videoFilter(maxPixelSize: CGSize?) -> String {
        guard let maxPixelSize,
              maxPixelSize.width > 1,
              maxPixelSize.height > 1 else {
            return "scale=trunc(iw/2)*2:trunc(ih/2)*2"
        }

        let width = max(2, Int(maxPixelSize.width.rounded(.down)))
        let height = max(2, Int(maxPixelSize.height.rounded(.down)))
        return "scale='min(iw,\(width))':'min(ih,\(height))':force_original_aspect_ratio=decrease:force_divisible_by=2"
    }
}

public enum EmbeddedFFmpegError: Error, CustomStringConvertible {
    case binaryNotLinked(configuration: String)
    case executionFailed(status: Int32)

    public var description: String {
        switch self {
        case .binaryNotLinked(let configuration):
            return "embedded ffmpeg binary is not linked: \(configuration)"
        case .executionFailed(let status):
            return "embedded ffmpeg failed status=\(status)"
        }
    }
}

public struct EmbeddedFFmpegGIFTranscoder: Sendable {
    public var preset: FFmpegGIFTranscodePreset

    public init(preset: FFmpegGIFTranscodePreset = .appleH264) {
        self.preset = preset
    }

    public static var isLinked: Bool {
        urlimage_ffmpeg_is_linked() != 0
    }

    public static var configuration: String {
        guard let pointer = urlimage_ffmpeg_configuration() else {
            return ""
        }

        return String(cString: pointer)
    }

    public func transcode(_ request: FFmpegGIFTranscodeRequest) throws {
        guard Self.isLinked else {
            throw EmbeddedFFmpegError.binaryNotLinked(configuration: Self.configuration)
        }

        var arguments = ["ffmpeg"]
        arguments.append(contentsOf: preset.processArguments(for: request))

        var cArguments = arguments.map { strdup($0) }
        cArguments.append(nil)
        defer {
            for argument in cArguments {
                free(argument)
            }
        }

        let status = cArguments.withUnsafeMutableBufferPointer { buffer in
            urlimage_ffmpeg_execute(Int32(arguments.count), buffer.baseAddress)
        }

        guard status == 0 else {
            throw EmbeddedFFmpegError.executionFailed(status: status)
        }
    }
}
