# URLImage

`URLImage` is a SwiftUI view that displays an image downloaded from provided URL. `URLImage` manages downloading remote image and caching it locally, both in memory and on disk, for you.

Creating `URLImage` view is described in my blog post [URL Image view in SwiftUI](https://medium.com/@dmytro.anokhin/url-image-view-in-swiftui-f08f85d942d8).

There's also a demo app [URLImageApp](https://github.com/dmytro-anokhin/url-image-app).

## Installation

`URLImage` is a Swift Package and you can install it with Xcode 11:
- Copy SSH `git@github.com:dmytro-anokhin/url-image.git` or HTTPS `https://github.com/dmytro-anokhin/url-image.git` URL from github;
- Open **File/Swift Packages/Add Package Dependency...** in Xcode 11;
- Paste the URL and follow steps.

## Usage

 `URLImage` must be initialized with a URL and optional placeholder image.
 
 ```swift
let url: URL = // ...

URLImage(url)

URLImage(url, placeholder: Image(systemName: "photo"))
``` 

Using in a view:

```swift
import SwiftUI
import URLImage

struct MyView : View {

    let url: URL

    var body: some View {
        URLImage(url)
            .resizable()
            .aspectRatio(contentMode: .fit)
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
                URLImage(url, delay: 0.25)
                    .resizable()
                    .frame(width: 100.0, height: 100.0)
                    .clipped()
                Text("\(url)")
            }
        }
    }
}
```

## Parameters

`URLImage` allows you to configure its parameters using  initializer:

 ```swift
 init(_ url: URL, placeholder: Image, session: URLSession?, delay: Double, animated: Bool)`
```

**`placeholder`**

The view displayed while the remote image is downloading or if it failed to download. Default is `Image(systemName: "photo")`.

Placeholder is a closure that returns a `View` object. This allows you to customize it. For instance, this sample code replaces default placeholder with a circle in a 150x150 bounding box.

```swift
URLImage(url, placeholder: {
    Image(systemName: "circle")
        .resizable()
        .frame(width: 150.0, height: 150.0)
    })
```

**`session`**

Optional `URLSession` used to download the image. Default session is created with `URLSessionConfiguration.default` and `httpMaximumConnectionsPerHost = 1`.

**`delay`**

Delay before `URLImage` fetches the image from cache or starts to download it. This is useful to optimize scrolling when displaying  `URLImage` in a `List` view.  Default is `0.0`.


## Styling Images

**`resizable(capInsets:resizingMode:)`**

Returns resizable `URLImage` object. This function matches the `resizable(capInsets:resizingMode:)` function of the `Image` object.
Resizable is only applied to the remote image. The placeholder is not affected.

**`renderingMode(_:)`**

Returns `URLImage` object with applied rendering mode. This function matches the `renderingMode(_:)` function of the `Image` object.
Rendering mode is only applied to the remote image. The placeholder is not affected.
