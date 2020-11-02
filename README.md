# URLImage

![Supported platform: iOS, macOS, tvOS, watchOS](https://img.shields.io/badge/platform-iOS%2C%20macOS%2C%20tvOS%2C%20watchOS-lightgrey)
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
- [Cache](#cache)
- [Options](#options)
- [Reporting a Bug](#reporting-a-bug)
- [Requesting a Feature](#requesting-a-feature)
- [Contributing](#contributing)

## Features
- SwiftUI image view for remote images;
- Asynchronous image loading in the background with cancellation when view disappears;
- Local disk cache for downloaded images;
- Download progress indication;
- Fully customizable including placeholder, progress indication, and the image view;
- Control over download delay for better scroll performance;
- Images can be downloaded directly to disk or in memory.

## Installation

`URLImage` can be installed using Swift Package Manager or CocoaPods.

## Usage

`URLImage` expects URL of the image and the content view:

```swift
URLImage(url: url,
         content: { image in
             image
                 .resizable()
                 .aspectRatio(contentMode: .fit)
         })
```

`URLImage` transitions between 4 states:
- Empty state, when download has not started yet, or there is nothing to display;
- In Progress state to indicate download process;
- Failure state in case there is an error;
- Content to display the image.

Each of this states has a separate view that can be provided using closures. You can also customize certain settings, like cache policy and expiry interval, using `URLImageOptions`.

```swift
struct MyView: View {

    let url: URL
    let id: UUID

    init(url: URL, id: UUID) {
        self.url = url
        self.id = id

        formatter = NumberFormatter()
        formatter.numberStyle = .percent
    }
    
    private let formatter: NumberFormatter // Used to format download progress as percentage. Note: this is only for example, better use shared formatter to avoid creating it for every view.
    
    var body: some View {
        URLImage(url: url,
                 options: URLImageOptions(
                    identifier: id.uuidString,      // Custom identifier
                    expireAfter: 300.0,             // Expire after 5 minutes
                    cachePolicy: .returnCacheElseLoad(cacheDelay: nil, downloadDelay: 0.25) // Return cached image or download after delay 
                 ),
                 empty: {
                    Text("Nothing here")            // This view is displayed before download starts
                 },
                 inProgress: { progress -> Text in  // Display progress
                    if let progress = progress {
                        return Text(formatter.string(from: progress as NSNumber) ?? "Loading...")
                    }
                    else {
                        return Text("Loading...")
                    }
                 },
                 failure: { error, retry in         // Display error and retry button
                    VStack {
                        Text(error.localizedDescription)
                        Button("Retry", action: retry)
                    }
                 },
                 content: { image in                // Content view
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                 })
    }
}
```

## Cache

`URLImage`  uses two caches:
- In memory cache for quick access;
- Local disk cache.

Downloaded images stored in user caches folder. This allows OS to take care of cleaning up files. It is also a good idea to perform manual cleanup time to time.

You can remove expired images by calling `cleanup` as a part of your startup routine. This will also remove image files from the previous `URLImage` version if you used it.

```swift
URLImageService.shared.cleanup()
```

Downloaded images expire after some time. Expired images removed in `cleanup` routine. Expiry interval can be set using `expiryInterval` property of `URLImageOptions`.

You can also remove individual or all cached images using `URLImageService`.

## Options

`URLImage` allows controlling various aspects of download and cache using `URLImageOptions` structure. You can set default options using `URLImageService.shared.defaultOptions` property. Here are the main settings:

**`identifier: String?`**

By default an image is identified by its URL. Alternatively, you can provide a string identifier to override this.

**`expiryInterval: TimeInterval?`**

Time interval after which the cached image expires and can be deleted. Images are deleted as part of cleanup routine described in [Cache](#cache) paragraph.

**`maxPixelSize: CGSize?`**

Maximum size of a decoded image in pixels. If this property is not specified, the width and height of a decoded is not limited and may be as big as the image itself.

**`cachePolicy: CachePolicy`**

The cache policy controls how the image loaded from cache.

### Cache Policy

Cache policy, `URLImageOptions.CachePolicy` type, allows to specify how `URLImage` utilizes it's cache, similar to `NSURLRequest.CachePolicy`. This type also allows to specify delays for accessing disk cache and starting download.

**`case returnCacheElseLoad`**
    
Return an image from cache or download it.

**`returnCacheDontLoad`**

Return an image from cache, do not download it.

**`ignoreCache`**

Ignore cached image and download remote one.

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

## Requesting a Feature

Use GitHub issues to request a feature.

## Contributing

Contributions are welcome. Please create a GitHub issue before submitting a pull request to plan and discuss implementation.
