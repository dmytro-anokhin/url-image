# URLImage

![Supported platform: iOS, macOS, tvOS, watchOS](https://img.shields.io/badge/platform-iOS%2C%20macOS%2C%20tvOS%2C%20watchOS-lightgrey)
[![Follow me on Twitter](https://img.shields.io/twitter/follow/dmytroanokhin?style=social)](https://twitter.com/intent/follow?screen_name=dmytroanokhin)

`URLImage` is a SwiftUI view that displays an image downloaded from provided URL. `URLImage` manages downloading remote image and caching it locally, both in memory and on disk, for you.

Using `URLImage` is dead simple:

```swift
URLImage(url: url,                                // Provide URL for the image
         failure: { error, _ in
             Text(error.localizedDescription)     // Display an error
         },
         content: { image in                      // Provide a content view when the image is downloaded
             image
                 .resizable()
                 .aspectRatio(contentMode: .fit)
         })
```

Note: version 2.0 is in development and API is subject to change. If you open an issue please mark it with v2.0 label.

# Table of Contents
- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)

## Features
- SwiftUI image view for remote images;
- Asynchronous image loading in the background with cancellation when view disappears;
- Local disk cache for downloaded images;
- Download progress indication;
- Fully customizable including placeholder, progress indication, and the image view;
- Control over download delay for better scroll performance in lists.

## Installation

`URLImage` can be installed using Swift Package Manager or CocoaPods.

To install `URLImage` using Swift Package Manager look for https://github.com/dmytro-anokhin/url-image.git in Xcode (*File/Swift Packages/Add Package Dependency...*). See [Adding Package Dependencies to Your App](https://developer.apple.com/documentation/xcode/adding_package_dependencies_to_your_app) for details.

To install `URLImage` using CocoaPods add `pod 'URLImage'` to your Podfile.

## Usage

`URLImage` expects URL of the image and two views: the content view to display the image when downloaded, and the failure view to display an error if occurs:

```swift
URLImage(url: url,
         failure: { error, _ in
             Text(error.localizedDescription)
         },
         content: { image in
             image
                 .resizable()
                 .aspectRatio(contentMode: .fit)
         })
```

There is more to customize:

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
                        return Text(progress as NSNumber, formatter: formatter) 
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
