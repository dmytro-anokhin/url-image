//
//  SwiftUIView.swift
//
//
//  Created by sonoma on 4/21/24.
//

import SwiftUI
import Model

#if os(iOS) || os(watchOS)
public typealias PlatformView = UIView
public typealias PlatformViewRepresentable = UIViewRepresentable
public typealias PlatformImage = UIImage
public typealias PlatformImageView = UIImageView
#elseif os(macOS)
public typealias PlatformView = NSView
public typealias PlatformImage = NSImage
public typealias PlatformImageView = NSImageView
public typealias PlatformViewRepresentable = NSViewRepresentable
#endif

public enum GIFImageSource {
    case image(PlatformImage)
    case file(URL)
}

public enum GIFPlaybackMode: Sendable {
    case poster
    case animated
}

@available(macOS 12.0, iOS 15.0, *)
public struct GIFImage<Empty, InProgress, Failure, Content> : View where Empty : View,
                                                                         InProgress : View,
                                                                         Failure : View,
                                                                         Content : View {
    @Environment(\.urlImageService) var urlImageService
    @Environment(\.urlImageOptions) var options
    
    var url: URL
    private let identifier: String?
    private let playbackMode: GIFPlaybackMode
    
    private let empty: () -> Empty
    private let inProgress: (_ progress: Float?) -> InProgress
    private let failure: (_ error: Error, _ retry: @escaping () -> Void) -> Failure
    private let content: (_ image: GIFImageView) -> Content
    
    public init(_ url: URL,
                identifier: String? = nil,
                playbackMode: GIFPlaybackMode = .animated,
                 @ViewBuilder empty: @escaping () -> Empty,
                 @ViewBuilder inProgress: @escaping (_ progress: Float?) -> InProgress,
                 @ViewBuilder failure: @escaping (_ error: Error, _ retry: @escaping () -> Void) -> Failure,
                 @ViewBuilder content: @escaping (_ transientImage: GIFImageView) -> Content) {
        
        self.url = url
        self.identifier = identifier
        self.playbackMode = playbackMode
        self.empty = empty
        self.inProgress = inProgress
        self.failure = failure
        self.content = content
    }
    
    public var body: some View {
        InstalledRemoteView(service: urlImageService, url: url, identifier: identifier, options: options) { remoteImage in
            RemoteGIFImageView(remoteImage: remoteImage,
                               loadOptions: options.loadOptions,
                               playbackMode: playbackMode,
                               empty: empty,
                               inProgress: inProgress,
                               failure: failure,
                               content: content)
        }
    }
}

@available(macOS 11.0, iOS 14.0, *)
public struct GIFImageView: View {
    var source: GIFImageSource
    var playbackMode: GIFPlaybackMode
    var preferredMaxPixelSize: CGSize?
    @Environment(\.imageConfigures) var imageConfigures
    
    init(image: PlatformImage, playbackMode: GIFPlaybackMode = .animated, preferredMaxPixelSize: CGSize? = nil) {
        self.source = .image(image)
        self.playbackMode = playbackMode
        self.preferredMaxPixelSize = preferredMaxPixelSize
    }
    
    init(url: URL, playbackMode: GIFPlaybackMode = .animated, preferredMaxPixelSize: CGSize? = nil) {
        self.source = .file(url)
        self.playbackMode = playbackMode
        self.preferredMaxPixelSize = preferredMaxPixelSize
    }
    
    public var body: some View {
        if imageConfigures.resizeble, let aspectRatio = imageConfigures.aspectRatio {
            GIFRepresentView(source: source, playbackMode: playbackMode, preferredMaxPixelSize: preferredMaxPixelSize)
                .aspectRatio(aspectRatio, contentMode: imageConfigures.contentMode == .fit ? .fit:.fill)
        }   else    {
            GIFRepresentView(source: source, playbackMode: playbackMode, preferredMaxPixelSize: preferredMaxPixelSize)
        }
    }
}

public extension View {
    func aspectResizeble(ratio: CGFloat, contentMode: GIFContentMode = .fit) -> some View {
        self.environment(\.imageConfigures, ImageConfigures(aspectRatio: ratio, contentMode: contentMode, resizeble: true))
    }
}

@available(macOS 11.0, iOS 14.0, *)
struct GIFRepresentView: PlatformViewRepresentable {
    var source: GIFImageSource
    var playbackMode: GIFPlaybackMode
    var preferredMaxPixelSize: CGSize?
    @Environment(\.imageConfigures) var imageConfigures
    
#if os(iOS) || os(watchOS)
    public func makeUIView(context: Context) -> PlatformView {
        let view = UIGIFImage()
        view.update(source: source, contentMode: imageConfigures.contentMode, playbackMode: playbackMode)
        return view
    }
    
    public func updateUIView(_ uiView: PlatformView, context: Context) {
        (uiView as? UIGIFImage)?.update(source: source, contentMode: imageConfigures.contentMode, playbackMode: playbackMode)
    }
#elseif os(macOS)
    public func makeNSView(context: Context) -> PlatformView {
        let view = MacAnimatedGIFView()
        view.update(source: source,
                    contentMode: imageConfigures.contentMode,
                    playbackMode: playbackMode,
                    preferredMaxPixelSize: preferredMaxPixelSize)
        return view
    }
    
    public func updateNSView(_ nsView: PlatformView, context: Context) {
        (nsView as? MacAnimatedGIFView)?.update(source: source,
                                                contentMode: imageConfigures.contentMode,
                                                playbackMode: playbackMode,
                                                preferredMaxPixelSize: preferredMaxPixelSize)
    }

    public static func dismantleNSView(_ nsView: PlatformView, coordinator: ()) {
        (nsView as? MacAnimatedGIFView)?.reset()
    }
#endif
}

public final class UIGIFImage: PlatformView {
    let imageView = PlatformImageView()
    private var source: GIFImageSource?
    private var playbackMode: GIFPlaybackMode = .animated
    private var imageConfigures: ImageConfigures?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
#if os(iOS) || os(watchOS)
    public override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = bounds
        if imageView.superview == nil {
            addSubview(imageView)
        }
    }
#elseif os(macOS)
    public override func layout() {
        super.layout()
        imageView.frame = bounds
        if imageView.superview == nil {
            addSubview(imageView)
        }
    }
#endif
    
    private func initView() {
#if os(iOS) || os(watchOS)
        imageView.contentMode = .scaleAspectFit
#elseif os(macOS)
        imageView.imageScaling = .scaleAxesIndependently
        imageView.animates = false
#endif
    }

    func update(source: GIFImageSource, contentMode: GIFContentMode, playbackMode: GIFPlaybackMode) {
        self.source = source
        self.playbackMode = playbackMode
        self.imageConfigures = ImageConfigures(aspectRatio: nil, contentMode: contentMode, resizeble: false)
#if os(iOS) || os(watchOS)
        imageView.contentMode = contentMode == .fit ? .scaleAspectFit:.scaleAspectFill
#elseif os(macOS)
        imageView.imageScaling = contentMode == .fit ? .scaleAxesIndependently:.scaleProportionallyUpOrDown
#endif
        apply()
    }

    private func apply() {
        guard let source else {
            imageView.image = nil
            return
        }

        switch source {
        case .image(let image):
#if os(iOS) || os(watchOS)
            imageView.stopAnimating()
            switch playbackMode {
            case .animated:
                imageView.image = image
                imageView.startAnimating()
            case .poster:
                imageView.image = image.images?.first ?? image
            }
#elseif os(macOS)
            imageView.animates = false
            imageView.image = image
            imageView.animates = playbackMode == .animated
#endif
        case .file:
            break
        }
    }
}


public struct Scenes: Sendable {
    public init() {
        
    }
    
#if os(iOS) || os(watchOS)
    @MainActor func keyScreen() -> UIScreen {
        UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: {
                $0.activationState == .foregroundActive
            })?.screen ?? UIScreen.main
    }
    
    @MainActor public func nativeScale() -> CGFloat {
        keyScreen().nativeScale
    }
#elseif os(macOS)
    public func nativeScale() -> CGFloat {
        NSScreen.main?.backingScaleFactor ?? 1
    }
#endif
}

public enum GIFContentMode: Sendable {
    case fit
    case fill
}

struct ImageConfigures: Sendable {
    var aspectRatio: CGFloat?
    var contentMode: GIFContentMode
    var resizeble: Bool
    
    func aspectRatio(_ aspectRatio: CGFloat) -> ImageConfigures {
        var configures = self
        configures.aspectRatio = aspectRatio
        return configures
    }

    func contentMode(_ contentMode: GIFContentMode) -> ImageConfigures {
        var configures = self
        configures.contentMode = contentMode
        return configures
    }
}

extension EnvironmentValues {
    @Entry var imageConfigures: ImageConfigures = ImageConfigures(aspectRatio: nil, contentMode: .fit, resizeble: false)
}

//@available(iOS 13.0, *)
//struct GIFImageTest: View {
//    @State private var imageData: Data? = nil
//
//    var body: some View {
//        VStack {
//            GIFImage(name: "preview")
//                .frame(height: 300)
//            if let data = imageData {
//                GIFImage(data: data)
//                    .frame(width: 300)
//            } else {
//                Text("Loading...")
//                    .onAppear(perform: loadData)
//            }
//        }
//    }
//
//    private func loadData() {
//        let task = URLSession.shared.dataTask(with: URL(string: "https://github.com/globulus/swiftui-webview/raw/main/Images/preview_macos.gif?raw=true")!) { data, response, error in
//            imageData = data
//        }
//        task.resume()
//    }
//}
//
//
//struct GIFImage_Previews: PreviewProvider {
//    static var previews: some View {
//        GIFImageTest()
//    }
//}
