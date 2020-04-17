//
//  ImageDecoder.swift
//
//
//  Created by Dmytro Anokhin on 16/11/2019.
//
//  ImageDecoder is based on ImageDecoderCG from WebCore https://trac.webkit.org/browser/webkit/trunk/Source/WebCore/platform/graphics/cg/ImageDecoderCG.cpp

import ImageIO
import Foundation


@available(iOS 9.0, macOS 10.11, *)
final class ImageDecoder {

    struct DecodingOptions {

        enum Mode {

            case synchronous

            case asynchronous
        }

        static var `default`: DecodingOptions {
            DecodingOptions(mode: .asynchronous, sizeForDrawing: nil)
        }

        var mode: Mode

        var sizeForDrawing: CGSize?
    }

    enum SubsamplingLevel: Int {

        case level0 = 1

        case level1 = 2

        case level2 = 4

        case level3 = 8

        static var `default`: SubsamplingLevel {
            .level0
        }
    }

    enum EncodedDataStatus {

        case unknown

        case error

        case typeAvailable

        case sizeAvailable

        case complete
    }

    // MARK: - Public

    init() {
        imageSource = CGImageSourceCreateIncremental(nil)
    }

    convenience init?(url: URL) {
        guard let dataProvider = CGDataProvider(url: url as CFURL) else {
            return nil
        }

        self.init()
        setDataProvider(dataProvider, allDataReceived: true)
    }

    private(set) var isAllDataReceived: Bool = false

    func setData(_ data: Data, allDataReceived: Bool) {
        assert(!isAllDataReceived)

        isAllDataReceived = allDataReceived
        CGImageSourceUpdateData(imageSource, data as CFData, allDataReceived)
    }

    func setDataProvider(_ dataProvider: CGDataProvider, allDataReceived: Bool) {
        assert(!isAllDataReceived)
        isAllDataReceived = allDataReceived
        CGImageSourceUpdateDataProvider(imageSource, dataProvider, allDataReceived)
    }

    var uti: String? {
        CGImageSourceGetType(imageSource) as String?
    }

    var encodedDataStatus: EncodedDataStatus {
        guard let uti = self.uti, !uti.isEmpty else {
            return .unknown
        }

        switch CGImageSourceGetStatus(imageSource) {
            case .statusUnknownType:
                return .error

            case .statusUnexpectedEOF:
                fallthrough
            case .statusInvalidData:
                fallthrough
            case .statusReadingHeader:
                // Ragnaros yells: TOO SOON! You have awakened me TOO SOON, Executus!
                return isAllDataReceived ? .error : .unknown

            case .statusIncomplete:
                // WebCore checks isSupportedImageType here and returns error if not:
                // if (!isSupportedImageType(uti))
                //     return EncodedDataStatus::Error;

                guard let image0Properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, imageSourceOptions()) as? [CFString: Any] else {
                    return .typeAvailable
                }

                guard let _ = image0Properties[kCGImagePropertyPixelWidth] as? Int, let _ = image0Properties[kCGImagePropertyPixelHeight] as? Int else {
                    return .typeAvailable
                }

                return .sizeAvailable

            case .statusComplete:
                // WebCore checks isSupportedImageType here and returns error if not
                // if (!isSupportedImageType(uti))
                //     return EncodedDataStatus::Error;

                return .complete

            @unknown default:
                return .unknown
        }
    }

    var frameCount: Int {
        CGImageSourceGetCount(imageSource)
    }

    func frameDuration(at index: Int) -> TimeInterval? {
        guard let frameProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, index, imageSourceOptions()) as? [CFString: Any] else {
            return nil
        }

        var animationProperties = ImageDecoder.animationProperties(from: frameProperties)

        if animationProperties == nil {
            if let properties = CGImageSourceCopyProperties(imageSource, imageSourceOptions()) as? [CFString: Any] {
                animationProperties = ImageDecoder.animationHEICSProperties(from: properties, at: index)
            }
        }

        let duration: TimeInterval

        // Use the unclamped frame delay if it exists. Otherwise use the clamped frame delay.
        if let unclampedDelay = animationProperties?["UnclampedDelayTime" as CFString] as? TimeInterval {
            duration = unclampedDelay
        }
        else if let delay = animationProperties?["DelayTime" as CFString] as? TimeInterval {
            duration = delay
        }
        else {
            duration = 0.0
        }

        // WebCore won't allow frame duration faster than 10ms. See original comment:
        //
        // Many annoying ads specify a 0 duration to make an image flash as quickly as possible.
        // We follow Firefox's behavior and use a duration of 100 ms for any frames that specify
        // a duration of <= 10 ms. See <rdar://problem/7689300> and <http://webkit.org/b/36082>
        // for more information.
        return duration < 0.011 ? 0.1 : duration
    }

    func frameSize(at index: Int, subsamplingLevel: SubsamplingLevel = .default) -> CGSize? {
        guard let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, index, imageSourceOptions(with: subsamplingLevel)) as? [CFString: Any] else {
            return nil
        }

        guard let width = properties[kCGImagePropertyPixelWidth] as? Int, let height = properties[kCGImagePropertyPixelHeight] as? Int else {
            return nil
        }

        return CGSize(width: width, height: height)
    }

    func createFrameImage(at index: Int, subsamplingLevel: SubsamplingLevel = .default, decodingOptions: DecodingOptions = .default) -> CGImage? {

        guard index < frameCount else {
            return nil
        }

        let image: CGImage?
        let options: CFDictionary

        switch decodingOptions.mode {
            case .asynchronous:
                // Don't consider the subsamplingLevel when comparing the image native size with sizeForDrawing.
                guard var size = frameSize(at: index) else {
                    return nil
                }

                if let sizeForDrawing = decodingOptions.sizeForDrawing {
                    // See which size is smaller: the image native size or the sizeForDrawing.
                    if sizeForDrawing.width * sizeForDrawing.height < size.width * size.height {
                        size = sizeForDrawing
                    }
                }

                options = imageSourceAsyncOptions(sizeForDrawing: size, subsamplingLevel: subsamplingLevel)
                image = CGImageSourceCreateThumbnailAtIndex(imageSource, index, options)

            case .synchronous:
                options = imageSourceOptions(with: subsamplingLevel)
                image = CGImageSourceCreateImageAtIndex(imageSource, index, options)
        }

        // WebKit has support for xbm images but we don't

        return image
    }

    func isFrameComplete(at index: Int) -> Bool {
        assert(frameCount > index)

        // CGImageSourceGetStatusAtIndex() changes the return status value from kCGImageStatusIncomplete
        // to kCGImageStatusComplete only if (index > 1 && index < frameCount() - 1). To get an accurate
        // result for the last frame (or the single frame of the static image) use CGImageSourceGetStatus()
        // instead for this frame.
        if index == frameCount - 1 {
            return CGImageSourceGetStatus(imageSource) == .statusComplete
        }

        return CGImageSourceGetStatusAtIndex(imageSource, index) == .statusComplete
    }

    func frameOrientation(at index: Int) -> CGImagePropertyOrientation? {
        guard index < frameCount else {
            return nil
        }

        guard let frameProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, index, imageSourceOptions()) as? [CFString: Any] else {
            return nil
        }

        guard let orientation = frameProperties[kCGImagePropertyOrientation] as? UInt32 else {
            return nil
        }

        return CGImagePropertyOrientation(rawValue: orientation)
    }

    // MARK: - Private

    private static let imageSourceOptions: [CFString: Any] = [
        kCGImageSourceShouldCache: true
    ]

    private static let imageSourceAsyncOptions: [CFString: Any] = [
        kCGImageSourceShouldCacheImmediately: true,
        kCGImageSourceCreateThumbnailFromImageAlways: true
    ]

    private let imageSource: CGImageSource

    private func imageSourceOptions(with subsamplingLevel: SubsamplingLevel = .default) -> CFDictionary {
        var options = ImageDecoder.imageSourceOptions

        switch subsamplingLevel {
            case .default:
                return options as CFDictionary
            default:
                options[kCGImageSourceSubsampleFactor] = subsamplingLevel
                return options as CFDictionary
        }
    }

    private func imageSourceAsyncOptions(sizeForDrawing: CGSize, subsamplingLevel: SubsamplingLevel = .default) -> CFDictionary {
        var options = ImageDecoder.imageSourceAsyncOptions

        options[kCGImageSourceThumbnailMaxPixelSize] = Int(max(sizeForDrawing.width, sizeForDrawing.height))

        switch subsamplingLevel {
            case .default:
                return options as CFDictionary
            default:
                options[kCGImageSourceSubsampleFactor] = subsamplingLevel
                return options as CFDictionary
        }
    }
}


@available(iOS 9.0, macOS 10.11, *)
extension ImageDecoder {

    fileprivate static func animationProperties(from properties: [CFString: Any]) -> [CFString: Any]? {
        if let gifProperties = properties[kCGImagePropertyGIFDictionary] as? [CFString: Any] {
            return gifProperties
        }

        if let pngProperties = properties[kCGImagePropertyPNGDictionary] as? [CFString: Any] {
            return pngProperties
        }

        if #available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *) {
            if let heicsProperties = properties[kCGImagePropertyHEICSDictionary] as? [CFString: Any] {
                return heicsProperties
            }
        }

        return nil
    }

    fileprivate static func animationHEICSProperties(from properties: [CFString: Any], at index: Int) -> [CFString: Any]? {
        // For HEICS images, ImageIO does not create a properties dictionary for each HEICS frame. Instead it maintains
        // all frames' information in the image properties dictionary. Here is how ImageIO structures the properties
        // dictionary for HEICS image:
        //  "{HEICS}" =  {
        //      FrameInfo = ( { DelayTime = "0.1"; }, { DelayTime = "0.1"; }, ... );
        //      LoopCount = 0;
        //      ...
        //  };
        if #available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *) {
            guard let heicsProperties = properties[kCGImagePropertyHEICSDictionary] as? [CFString: Any] else {
                return nil
            }

            guard let array = heicsProperties["FrameInfo" as CFString] as? [[CFString: Any]], array.count > index else {
                return nil
            }

            return array[index]
        }

        return nil
    }
}
