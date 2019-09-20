# URLImage

![Supported platform: iOS, tvOS, watchOS](https://img.shields.io/badge/platform-iOS%2C%20tvOS%2C%20watchOS-lightgrey)
[![Follow me on Twitter](https://img.shields.io/twitter/follow/dmytroanokhin?style=social)](https://twitter.com/intent/follow?screen_name=dmytroanokhin)

`URLImage` is a SwiftUI view that displays an image downloaded from provided URL. `URLImage` manages downloading remote image and caching it locally, both in memory and on disk, for you.

## Features
- Follows SwiftUI declarative style;
- Supports local disk cache;
- Allows customization of the placeholder and the image views.

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

### Advanced Customization

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

The placeholder can be customized with `() -> Placeholder` closure.

```swift
URLImage(url, placeholder: {
    Image(systemName: "circle")             // Use different image for the placeholder
        .resizable()                        // Make it resizable
        .frame(width: 150.0, height: 150.0) // Set frame to 150x150
})
```

```swift
URLImage(url, placeholder: {
    // Replace placeholder image with text
    Text("Loading...")
})
```

### Examples

Using in a view:

```swift
import SwiftUI
import URLImage

struct MyView : View {

    let url: URL

    var body: some View {
        URLImage(url, placeholder: {
            Image(systemName: "circle")
                .resizable()
                .frame(width: 150.0, height: 150.0)
            }) { proxy in
                proxy.image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(.all, 0)
                }
    }
}
```

Using in a list:

```swift
import SwiftUI
import URLImage

struct MyListView : View {

    let urls: [URL]

    var body: some View {
        List(urls, id: \.self) { url in
            HStack {
                URLImage(url, delay: 0.25) { proxy in
                        proxy.image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .clipped()
                    }
                    .frame(width: 100.0, height: 100.0)

                Text("\(url)")
            }
        }
    }
}
```

### URLImage ###

`URLImage` allows you to configure its parameters using initializers:

```swift
init(_ url: URL, delay: TimeInterval)
```

**`url`**

URL of the remote image.

**`delay`**

Delay before `URLImage` fetches the image from cache or starts to download it. This is useful to optimize scrolling when displaying  `URLImage` in a `List` view.  Default is `0.0`.

## Installation

`URLImage` is a Swift Package and you can install it with Xcode 11:
- HTTPS `https://github.com/dmytro-anokhin/url-image.git` URL from github;
- Open **File/Swift Packages/Add Package Dependency...** in Xcode 11;
- Paste the URL and follow steps.
