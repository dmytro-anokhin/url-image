# URLImage

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fdmytro-anokhin%2Furl-image%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/dmytro-anokhin/url-image)
[![Follow me on Twitter](https://img.shields.io/twitter/follow/dmytroanokhin?style=social)](https://twitter.com/intent/follow?screen_name=dmytroanokhin)


`URLImage` is a SwiftUI view that displays an image downloaded from provided URL. `URLImage` manages downloading remote image and caching it locally, both in memory and on disk, for you.

Using `URLImage` is dead simple:

```swift
URLImage(url: url) { image in
    image
        .resizable()
        .aspectRatio(contentMode: .fit)
}
```

Take a look at some examples in [the demo app](https://github.com/dmytro-anokhin/url-image-demo).

# Table of Contents
- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
    - [View Customization](#view-customization)
    - [Options](#options)
    - [Image Information](#image-information)
    - [Zoom In](#zoom-in)
- [Cache](#cache) 
    - [Store Use cases](#store-use-cases) 
- [Advanced](#advanced)
    - [Start Loading](#start-loading)
    - [Make Your Own URLImage](#make-your-own-urlimage)
    - [Fetching an Image](#fetching-an-image)
    - [Download an Image in iOS 14 Widget](#download-an-image-in-ios-14-widget)
- [Migration Notes v2 to v3](#migration-notes-v2-to-v3)
- [Reporting a Bug](#reporting-a-bug)
- [Requesting a Feature](#requesting-a-feature)
- [Contributing](#contributing)

## Features
- SwiftUI image view for remote images;
- Local image cache;
- Fully customizable including placeholder, progress indication, error, and the image view;
- Control over various download aspects for better performance.

## Installation

`URLImage` can be installed using Swift Package Manager.

1. In Xcode open **File/Swift Packages/Add Package Dependency...** menu.

2. Copy and paste the package URL:

```
https://github.com/dmytro-anokhin/url-image
```

For more details refer to [Adding Package Dependencies to Your App](https://developer.apple.com/documentation/xcode/adding_package_dependencies_to_your_app) documentation.

## Usage

You can create `URLImage` with URL and a [`ViewBuilder`](https://developer.apple.com/documentation/swiftui/viewbuilder) to display downloaded image.

```swift
import URLImage // Import the package module

let url: URL = //...

URLImage(url) { image in
    image
        .resizable()
        .aspectRatio(contentMode: .fit)
}
```

*Note: first argument of the `URLImage` initialiser is of `URL` type, if you have a `String` you must first create a `URL` object.*

### View Customization

`URLImage` view manages and transitions between 4 download states: 

- Empty state, when download has not started yet, or there is nothing to display;
- In Progress state to indicate download process;
- Failure state in case there is an error;
- Content to display the image.

Each of this states has a separate view. You can customize one or more using `ViewBuilder` arguments.

```swift
URLImage(item.imageURL) {
    // This view is displayed before download starts
    EmptyView()
} inProgress: { progress in
    // Display progress
    Text("Loading...")
} failure: { error, retry in
    // Display error and retry button
    VStack {
        Text(error.localizedDescription)
        Button("Retry", action: retry)
    }
} content: { image in
    // Downloaded image
    image
        .resizable()
        .aspectRatio(contentMode: .fit)
}
```

### Options

`URLImage` allows to control certain aspects using `URLImageOptions` structure. Things like whenever to download image or use cached, when to start and cancel download, how to configure network request, what is the maximum pixel size, etc.

`URLImageOptions` is the environment value and can be set using `\.urlImageOptions` key path.

```swift
URLImage(url) { image in
    image
        .resizable()
        .aspectRatio(contentMode: .fit)
}
.environment(\.urlImageOptions, URLImageOptions(
    maxPixelSize: CGSize(width: 600.0, height: 600.0)
))
```

Setting `URLImageOptions` in the environment value allows to set options for a whole or a part of your views hierarchy.

```swift
@main
struct MyApp: App {

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.urlImageOptions, URLImageOptions(
                    maxPixelSize: CGSize(width: 600.0, height: 600.0)
                ))
        }
    }
}
```

### Image Information

You can use `ImageInfo` structure if you need information about an image, like actual size, or access the underlying `CGImage` object. `ImageInfo` is an argument of `content` view builder closure. 

```swift
URLImage(item.imageURL) { image, info in
    if info.size.width < 1024.0 {
        image
            .resizable()
            .aspectRatio(contentMode: .fit)
    } else {
        image
            .resizable()
            .aspectRatio(contentMode: .fill)
    }
}
```

### Zoom In

If you want to add ability to scale the image consider checking [AdvancedScrollView](https://github.com/dmytro-anokhin/advanced-scrollview) package.

```swift
import AdvancedScrollView
import URLImage

URLImage(url) { image in
    AdvancedScrollView(magnificationRange: 1.0...4.0) { _ in
        image
    }
}
```

## Cache

`URLImage` can also cache images to lower network bandwith or for offline use.

By default, `URLImage` uses protocol cache policy, i.e. Cache-Control HTTP header and `URLCache`. This corresponds to how images work on web and requires network connection.

Alternatively, if you want to view images offline, you must configure the file store. When configured, `URLImage` will no longer use protocol cache policy, and instead follow `URLImageOptions.FetchPolicy` setting.

```swift
import URLImage
import URLImageStore

@main
struct MyApp: App {

    var body: some Scene {

        let urlImageService = URLImageService(fileStore: URLImageFileStore(),
                                          inMemoryStore: URLImageInMemoryStore())

        return WindowGroup {
            FeedListView()
                .environment(\.urlImageService, urlImageService)
        }
    }
}
```

Make sure to include `URLImageStore` library under "Frameworks, Libraries,and Embedded Content" of your target settings.

### Store Use Cases

You may ask when to use protocol or custom cache. `URLImage` designed to serve two use cases:

Use protocol cache policy when an app can only work connected to the internet. Ecommerce apps, such as shopping, travel, event reservation apps, etc., work like this. Following protocol cache policy you can be sure that images are cached in a way that your CDN defines, can still be accessed quickly, and don't take unnecessary space on user devices.

Configure `URLImageStore` for content that needs to be accessed offline or downloaded in background. This can be a reader app, you probably want to download articles before user opens them, maybe while the app is in the background. This content should stay for a considerably long period of time.

## Advanced

### Start Loading

`URLImage` starts loading when the image view is rendered. In some cases (like with `List`) you may want to start loading when view appears and cancel when it disappears. You can customize this using `URLImageOptions.LoadOptions` options. You can combine multiple to achieve behaviour that fits your UI best.

```swift
List(/* ... */) {
    // ...
}
    .environment(\.urlImageOptions, URLImageOptions(loadOptions: [ .loadOnAppear, .cancelOnDisappear ]))
``` 

Note: versions prior to 3.1 start loading on appearance and cancel when view disappears. Version 3.1 starts loading when the view renders. This is because `onAppear` and `onDisappear` callbacks are quite unpredictable without context.

### Make Your Own URLImage

Alternatively you can make your own `URLImage` to customize appearance and behaviour for your needs. 

```swift
struct MyURLImage: View {

    @ObservedObject private var remoteImage: RemoteImage

    init(service: URLImageService, url: URL) {
        remoteImage = service.makeRemoteImage(url: url, identifier: nil, options: URLImageOptions())
    }

    var body: some View {
        ZStack {
            switch remoteImage.loadingState {
                case .success(let value):
                    value.image

                default:
                    EmptyView()
            }
        }
        .onAppear {
            remoteImage.load()
        }
    }
}
```

You can access service environment value from enclosing view: `@Environment(\.urlImageService) var service: URLImageService`.

### Fetching an Image

You may want to download an image without a view. This is possible using the `RemoteImagePublisher` object. The `RemoteImagePublisher` can cache images for future use by the `URLImage` view.

Download an image as `CGImage` and ignore any errors:

```swift
cancellable = URLImageService.shared.remoteImagePublisher(url)
    .tryMap { $0.cgImage }
    .catch { _ in
        Just(nil)
    }
    .sink { image in
        // image is CGImage or nil
    }
```

Download multiple images as an array of `[CGImage?]`:

```swift
let publishers = urls.map { URLImageService.shared.remoteImagePublisher($0) }

cancellable = Publishers.MergeMany(publishers)
    .tryMap { $0.cgImage }
    .catch { _ in
        Just(nil)
    }
    .collect()
    .sink { images in
        // images is [CGImage?]
    }
```

When downloading image using the `RemoteImagePublisher` object all options apply as they do for the `URLImage` object. Be default downloaded image will be cached on the disk. This can speedup displaying images on later stage of your app. Also, this is currently the only supported way to display images in iOS 14 widgets.

### Download an Image in iOS 14 Widget

Unfortunately views in WidgetKit can not run asynchronous operations: https://developer.apple.com/forums/thread/652581. The recommended way is to load your content, including images, in `TimelineProvider`.

You can still use `URLImage` for this. The idea is that you load image in `TimelineProvider` using the `RemoteImagePublisher` object, and display it in the `URLImage` view.

## Migration Notes v2 to v3

- `URLImage` initialiser now omits an argument label for the first parameter, making `URLImage(url: url)` just `URLImage(url)`.
- `URLImage` initialiser now uses `ViewBuilder` attribute for closures that construct views.
- `URLImageOptions` now passed in the environment, instead of as an argument. Custom identifier can still be passed as an argument of `URLImage`.
- By default `URLImage` uses protocol cache policy and `URLCache`. This won't store images for offline usage. You can configure the file store as described in [cache](#cache) section.
- Swift Package Manager is now the only officially supported dependency manager.

## Reporting a Bug

Use GitHub issues to report a bug. Include this information when possible:

Summary and/or background;
OS and what device you are using;
Version of URLImage library;
What you expected would happen;
What actually happens;
Additional information:
Screenshots or video demonstrating a bug;
Crash log;
Sample code, try isolating it so it compiles without dependancies;
Test data: if you use public resource provide URLs of the images.

Please make sure there is a reproducible scenario. Ideally provide a sample code. And if you submit a sample code - make sure it compiles ;)

## Requesting a Feature

Use GitHub issues to request a feature.

## Contributing

Contributions are welcome. Please create a GitHub issue before submitting a pull request to plan and discuss implementation.
