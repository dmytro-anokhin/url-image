import PlaygroundSupport
import SwiftUI
import Combine
import RemoteContentView


let url = URL(string: "http://optipng.sourceforge.net/pngtech/img/lena.png")!

let remoteImage = RemoteImage(url: url)

let view = RemoteContentView(remoteContent: remoteImage) {
    Image(uiImage: $0)
}

PlaygroundSupport.PlaygroundPage.current.setLiveView(view)
