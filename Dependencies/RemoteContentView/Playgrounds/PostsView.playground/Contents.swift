import PlaygroundSupport
import SwiftUI
import RemoteContentView


struct Post : Codable {

    var id: Int

    var title: String

    var body: String
}

let url = URL(string: "https://jsonplaceholder.typicode.com/posts")!

let content = DecodableRemoteContent(url: url, type: [Post].self)

let view = RemoteContentView(remoteContent: content) { posts in
    List(posts, id: \Post.id) { post in
        VStack {
            Text(post.title)
            Text(post.body)
        }
    }
}

PlaygroundSupport.PlaygroundPage.current.setLiveView(view)
