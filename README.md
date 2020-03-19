# URLImage

![Supported platform: iOS, macOS, tvOS, watchOS](https://img.shields.io/badge/platform-iOS%2C%20macOS%2C%20tvOS%2C%20watchOS-lightgrey)
[![Follow me on Twitter](https://img.shields.io/twitter/follow/dmytroanokhin?style=social)](https://twitter.com/intent/follow?screen_name=dmytroanokhin)

`URLImage` is a SwiftUI view that displays an image downloaded from provided URL. `URLImage` manages downloading remote image and caching it locally, both in memory and on disk, for you.

# Table of Contents
- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
    - [Transition from 0.6.3 to 0.7.0 and later](#transition-from-063-to-070-and-later)
- [Advanced Customization](#advanced-customization)
- [Progress View](#progress-view)
- [Incremental Image Loading](#incremental-image-loading)
- [Local Cache](#local-cache)
    - [Maintaining Local Cache](#maintaining-local-cache)
- [Image Processing, Filters, and Resizing](#image-processing-filters-and-resizing)
    - [Custom Image Processor](#custom-image-processor)
    - [Core Image Filters](#core-image-filters)
    - [Resizing and Performance](#resizing-and-performance)
- [Examples](#examples)
    - [Using in a view](#using-in-a-view)
    - [Using in a list](#using-in-a-list)
    - [Using image processors and Core Image filters](#using-image-processors-and-core-image-filters)
- [URLImage](#urlimage-1)
- [Misc](#misc)
    - [Installation](#installation)
    - [Reporting a Bug](#reporting-a-bug)
    - [Requesting a Feature](#requesting-a-feature)
    - [Contributing](#contributing)


## Features
- SwiftUI image view for remote images;
- Asynchronous image loading in the background with cancellation when view disappears;
- Local disk cache for downloaded images;
- Download progress indication;
- Incremental downloading with interlaced images support (interlaced PNG, interlaced GIF, and progressive JPEG);
- Fully customizable including placeholder, progress indication, and the image view;
- Image processing and Core Image filters;
- Control over download delay for better scroll performance in lists;
- Lower memory consumption when downloading image data directly to disk.

## Installation

`URLImage` can be installed using Swift Package Manager or CocoaPods.

To install `URLImage` using Swift Package Manager look for https://github.com/dmytro-anokhin/url-image.git in Xcode (*File/Swift Packages/Add Package Dependency...*). See [Adding Package Dependencies to Your App](https://developer.apple.com/documentation/xcode/adding_package_dependencies_to_your_app) for details.

To install `URLImage` using CocoaPods add `pod 'URLImage'` to your Podfile.

## Usage

`URLImage` can be initialized with `URL`:
 
 ```swift
URLImage(url)
``` 

`URLImage` can also be initialized with `URLRequest` if you need to set additional HTTP headers:
 
 ```swift
URLImage(urlRequest)
```

*Note: the package expects GET request with URL*

When using in lists `delay` can be provided to postpone loading and improve scrolling performance:

```swift
URLImage(url, delay: 0.25)
```

The placeholder image can be changed:

```swift
URLImage(url, placeholder: Image(systemName: "circle"))
```

*Note: `Image(systemName:)` API is not available on macOS*

### Transition from 0.6.3 to 0.7.0 and later

0.7.0 release introduces some breaking changes:
- In 0.6.3 image was internal view. In 0.7.0 image is created by `content` closure with a proxy object. This provides more flexibility in customization.
- Placeholder closure is now also accepts an object that can be used to track download progress.
- Styling functions are now gone. Use `content` closure to style the image.
- Configuration object is now gone.

## Advanced Customization

`URLImage` utilizes closures for customization. Downloaded image can be customized using `(ImageProxy) -> Content` closure. The closure parameter is a proxy that provides access to `Image` and `UIImage` or `NSImage` for iOS and macOS.

```swift
URLImage(url) { proxy in
    proxy.image
        .resizable()                     // Make image resizable
        .aspectRatio(contentMode: .fill) // Fill the frame
        .clipped()                       // Clip overlaping parts
    }
    .frame(width: 100.0, height: 100.0)  // Set frame to 100x100.
```

The placeholder can be customized with `(DownloadProgressWrapper) -> Placeholder` closure.

```swift
URLImage(url, placeholder: { _ in
    Image(systemName: "circle")             // Use different image for the placeholder
        .resizable()                        // Make it resizable
        .frame(width: 150.0, height: 150.0) // Set frame to 150x150
})
```

```swift
URLImage(url, placeholder: { _ in
    // Replace placeholder image with text
    Text("Loading...")
})
```

## Progress View

User `ProgressView` as a placeholder to display download progress.

Downloading image is a two step process:
- When `progress` is 0 the download has not started yet. The best is to display continuously animated activity indicator.
- When download is in progress you can show a progress indicator. Note: for smaller images the progress can go from 0 to 1 in one go. Than this step won't be called.

```swift
URLImage(url, placeholder: {
    ProgressView($0) { progress in
        ZStack {
            if progress > 0.0 {
                // The download has started. CircleProgressView displays the progress.
                CircleProgressView(progress).stroke(lineWidth: 8.0)
            }
            else {
                // The download has not yet started. CircleActivityView is animated activity indicator that suits this case.
                CircleActivityView().stroke(lineWidth: 50.0)
            }
        }
    }
        .frame(width: 50.0, height: 50.0)
})
```

`CircleProgressView` and `CircleActivityView` are two progress views included in the package to showcase the functionality.

## Incremental Image Loading

`URLImage` supports incremental image loading. This way of loading image can create better user experience when using with interlaced PNG, GIF, or progressive JPEG format. Set `incremental` flag to enable it:

```swift
URLImage(url, incremental: true)
```

Incremental download won't report progress but you can still use activity indicator to play animation when the first bytes has not been loaded yet.

Note: memory consumption in this mode is higher because the image data is stored in memory and written to disk only after the download completes.

## Local Cache

`URLImage` stores downloaded image files in the `Caches/` folder. The system may delete the `Caches/` folder to free up disk space. However to provide better control this files have `expiryDate` set. Files with surpassed expiry date are deleted (lazily on attempt to read). By default files expire 7 days after download. Here are the ways to control this:

Provide `expiryDate` in the constructor:

```swift
URLImage(url, expireAfter: Date(timeIntervalSinceNow: 31_556_926.0)) // Expire after a year
```

Change default `expiryDate`:

```swift
URLImageService.shared.setDefaultExpiryTime(3600.0) // Expire after an hour
```

Cached images can be removed by URL:

```swift
URLImageService.shared.removeCachedImage(with: url)
```

### Maintaining Local Cache

Because cached files are deleted lazily it is a good idea to clean caches time to time:

- Call `URLImageService.shared.cleanFileCache()` at some point on the app launch. This method will asynchronoously clean caches and won't block your launch sequence.

- Files cache can be reset by calling `URLImageService.shared.resetFileCache()`.


## Image Processing, Filters, and Resizing

`URLImage` supports image processing and Core Image filters. The `ImageProcessing` encapsulates data and logic to process an image. `URLImage` initializer accepts an array of `ImageProcessing` objects.

```swift
URLImage(url, processors: [ /* Array of image processors */ ])
```

Image processing is performed in-order on a background queue. `URLImage` limits maximum number of operations in order not to create thread explosion.

*Note: currently image processing is supported for non-incremental downloads*

### Custom Image Processor

There are two ways to implement custom image processor:

Implement `ImageProcessing` protocol. This is the most flexible and reusable approach.

```swift
protocol ImageProcessing {

    func process(_ input: CGImage) -> CGImage
}
```

Use `ImageProcessorClosure` and pass image processor as a closure.

```swift
URLImage(url, processors: [
    ImageProcessorClosure { input in
        // return result or input
    }
]
```

### Core Image Filters

[Core Image](https://developer.apple.com/documentation/coreimage) provides number of useful filters and `URLImage` has built-in support for it with `CoreImageFilterProcessor` processor.

```swift
// Apply sepia filter

URLImage(url, processors: [
    CoreImageFilterProcessor(name: "CISepiaTone", parameters: [ kCIInputIntensityKey: 0.9 ])
])
```

When applying multiple Core Image filters it is best to reuse `CIContext` object:

```swift
// Apply sepia and bloom filters

struct MyImageView : View {

    let url: URL

    let ciContext = CIContext()

    var body: some View {
        URLImage(url,
            processors: [
                 CoreImageFilterProcessor(name: "CISepiaTone", parameters: [ kCIInputIntensityKey: 0.9 ], context: self.ciContext),
                 CoreImageFilterProcessor(name: "CIBloom", parameters: [ kCIInputIntensityKey: 1, kCIInputRadiusKey: 10.0 ], context: self.ciContext)
            ])
    }
}
```

*Note: Core Image framework is not supported on watchOS*

### Resizing and Performance

For best performance it is important to keep main thread free and graphic operations executed by GPU. You can read more in my post here: [Rendering performance of iOS apps](https://medium.com/@dmytro.anokhin/rendering-performance-of-ios-apps-4d09a9228930).

We want to follow this criteria:
- Image point size must be the same as the view frame;
- Image scale must be the same as the screen scale;
- Image color format must be natively supported.

`URLImage` provides convenient way to resize images preserving color space. Use `Resize` processor the view frame is know in advance.

```swift
URLImage(url,
    processors: [ Resize(size: CGSize(width: 100.0, height: 100.0), scale: UIScreen.main.scale) ],
    content:  {
        $0.image
            .resizable()
            .aspectRatio(contentMode: .fill)
            .clipped()
    })
        .frame(width: 100.0, height: 100.0)
```

Use `UIScreen` `scale` on iOS and `NSScreen` `backingScaleFactor` on macOS. 

## Examples

### Using in a view

```swift
import SwiftUI
import URLImage

struct DetailView : View {

    let url: URL

    var body: some View {
        URLImage(url,
            placeholder: {
                ProgressView($0) { progress in
                    ZStack {
                        if progress > 0.0 {
                            CircleProgressView(progress).stroke(lineWidth: 8.0)
                        }
                        else {
                            CircleActivityView().stroke(lineWidth: 50.0)
                        }
                    }
                }
                    .frame(width: 50.0, height: 50.0)
            },
            content: {
                $0.image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                    .padding(.all, 40.0)
                    .shadow(radius: 10.0)
            })
    }
}
```

### Using in a list

```swift
import SwiftUI
import URLImage

struct ListView : View {

    let urls: [URL]

    var body: some View {
        NavigationView {
            List(urls, id: \.self) { url in
                NavigationLink(destination: DetailView(url: url)) {
                    HStack {
                        URLImage(url,
                            delay: 0.25,
                            processors: [ Resize(size: CGSize(width: 100.0, height: 100.0), scale: UIScreen.main.scale) ],
                            content:  {
                                $0.image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .clipped()
                            })
                                .frame(width: 100.0, height: 100.0)

                        Text("\(url)")
                    }
                }
            }
            .navigationBarTitle(Text("Images"))
        }
    }
}
```

### Using image processors and Core Image filters

This example demonstrates using filters from this documentation [Processing an Image Using Built-in Filters](https://developer.apple.com/documentation/coreimage/processing_an_image_using_built-in_filters).

```swift
import SwiftUI
import URLImage
import CoreImage

struct DetailView : View {

    let url: URL

    let ciContext = CIContext()

    var body: some View {
        URLImage(url,
            processors: [
                 // Core Image Sepia filter
                 CoreImageFilterProcessor(name: "CISepiaTone", parameters: [ kCIInputIntensityKey: 0.9 ], context: self.ciContext),
                 
                 // Core Image Bloom filter
                 CoreImageFilterProcessor(name: "CIBloom", parameters: [ kCIInputIntensityKey: 1, kCIInputRadiusKey: 10.0 ], context: self.ciContext),

                 // Core Image Lanczos scale in a closure
                 ImageProcessorClosure { input in
                     let scaleFilter = CIFilter(name:"CILanczosScaleTransform")

                     let ciImage = CIImage(cgImage: input)
                     scaleFilter?.setValue(ciImage, forKey: kCIInputImageKey)

                     let aspectRatio = Double(input.width) / Double(input.height)
                     scaleFilter?.setValue(aspectRatio, forKey: kCIInputAspectRatioKey)

                     scaleFilter?.setValue(0.5, forKey: kCIInputScaleKey)

                     guard let outputImage = scaleFilter?.outputImage else {
                         return input
                     }

                     var bounds = CGRect(x: 0, y: 0, width: input.width, height: input.height)
                     bounds.origin.x = bounds.width * -0.25
                     bounds.origin.y = bounds.height * -0.25

                     let resultImage = self.ciContext.createCGImage(outputImage, from: bounds, format: .RGBA8, colorSpace: input.colorSpace)

                     return resultImage ?? input
                 }
            ])
    }
}
```

## `URLImage`

`URLImage` allows you to configure its parameters using initializers:

```swift
init(_ url: URL, delay: TimeInterval, incremental: Bool, processors: [ImageProcessing]?, expiryDate: Date?)
init(_ urlRequest: URLRequest, delay: TimeInterval, incremental: Bool, processors: [ImageProcessing]?, expiryDate: Date?)
```

**`url`**

URL of the remote image.

**`urlRequest`**

`URLRequest` for the remote image. The package expects GET request with URL.

**`delay`**

Delay before `URLImage` fetches the image from cache or starts to download it. This is useful to optimize scrolling when displaying  `URLImage` in a `List` view.  Default is `0.0`.

**`incremental`**

Set to use incremental image downloading mode.

**`processors`**

Optional list of image processors to apply.

**`expiryDate`**

Date when image considered to be expired and needs to be redownloaded. 

## Misc

### Installation

`URLImage` is a Swift Package and you can install it with Xcode 11:
- HTTPS `https://github.com/dmytro-anokhin/url-image.git` URL from github;
- Open **File/Swift Packages/Add Package Dependency...** in Xcode 11;
- Paste the URL and follow steps.

### Reporting a Bug

Use GitHub issues to report a bug. Include this information when possible:
- Summary and/or background;
- OS and what device you are using;
- Version of URLImage library;
- What you expected would happen;
- What actually happens;
- Additional information:
    - Screenshots or video demonstrating a bug;
    - Crash log;
    - Sample code, try isolating it so it compiles without dependancies;
    - Test data: if you use public resource provide URLs of the images.

### Requesting a Feature

Use GitHub issues to request a feature.

### Contributing

Contributions are welcome. Please create a GitHub issue before submitting a pull request to plan and discuss implementation.

------
If you like the package please share it with your network. When you ship an app with URLImage I would love to know about it 🙌
