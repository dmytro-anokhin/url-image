# URLImage

![Supported platform: iOS, macOS, tvOS, watchOS](https://img.shields.io/badge/platform-iOS%2C%20macOS%2C%20tvOS%2C%20watchOS-lightgrey)
[![Follow me on Twitter](https://img.shields.io/twitter/follow/dmytroanokhin?style=social)](https://twitter.com/intent/follow?screen_name=dmytroanokhin)

`URLImage` is a SwiftUI view that displays an image downloaded from provided URL. `URLImage` manages downloading remote image and caching it locally, both in memory and on disk, for you.

## Features
- SwiftUI image view for remote images;
- Asynchronous image loading in the background with cancellation when view disappears;
- Local disk cache for downloaded images;
- Download progress indication;
- Incremental downloading with interlaced images support (interlaced PNG, interlaced GIF, and progressive JPEG);
- Fully customizable including placeholder, progress indication, and the image view;
- Control over download delay for better scroll performance in lists;
- Lower memory consumption when downloading image data directly to disk.

## Usage

`URLImage` must be initialized with `url`:
 
 ```swift
URLImage(url)
``` 

When using in lists `delay` can be provided to postpone loading and improve scrolling performance:

```
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

The placeholder can be customized with `(PartialImage) -> Placeholder` closure.

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

### Maintaining Local Cache

Because cached files are deleted lazily it is a good idea to clean caches time to time:

- Call `URLImageService.shared.cleanFileCache()` at some point on the app launch. This method will asynchronoously clean caches and won't block your launch sequence.

- Files cache can be reset by calling `URLImageService.shared.resetFileCache()`.

## Examples

Using in a view:

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

Using in a list:

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
                        URLImage(url, delay: 0.25) {
                                $0.image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .clipped()
                            }
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

## `URLImage`

`URLImage` allows you to configure its parameters using initializers:

```swift
init(_ url: URL, delay: TimeInterval, incremental: Bool)
```

**`url`**

URL of the remote image.

**`delay`**

Delay before `URLImage` fetches the image from cache or starts to download it. This is useful to optimize scrolling when displaying  `URLImage` in a `List` view.  Default is `0.0`.

**`incremental`**

Set to use incremental image downloading mode.

**`expiryDate`**

Date when image considered to be expired and needs to be redownloaded. 

## Installation

`URLImage` is a Swift Package and you can install it with Xcode 11:
- HTTPS `https://github.com/dmytro-anokhin/url-image.git` URL from github;
- Open **File/Swift Packages/Add Package Dependency...** in Xcode 11;
- Paste the URL and follow steps.
