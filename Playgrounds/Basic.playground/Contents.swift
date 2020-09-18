import PlaygroundSupport
import SwiftUI
import URLImage


struct PlaygroundView : View {

    let url = URL(string: "http://optipng.sourceforge.net/pngtech/img/lena.png")!

    var body: some View {
        URLImage(url: url,
                 empty: { EmptyView() },
                 inProgress: { _ in Text("Loading") },
                 failure: { error, _ in
                    Text(error.localizedDescription)
                 },
                 content: {
                    $0
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                 })
            .frame(width: 320.0, height: 320.0)
            .background(Color.white)
    }
}


PlaygroundSupport.PlaygroundPage.current.needsIndefiniteExecution = true
PlaygroundSupport.PlaygroundPage.current.setLiveView(PlaygroundView())
