import PlaygroundSupport
import SwiftUI
import RemoteContentView


struct Post : Codable {

    var id: Int

    var title: String

    var body: String
}


final class PostsStore {

    enum PostsError : Error {

        case empty
    }

    func fetchPosts(_ completion: @escaping (_ result: Result<[Post], Error>) -> Void) -> AnyObject {
        let url = URL(string: "https://jsonplaceholder.typicode.com/posts")!
        let task = URLSession.shared.dataTask(with: url) { data, response, networkError in
            if let networkError = networkError {
                completion(.failure(networkError))
                return
            }

            if let data = data {
                let decoder = JSONDecoder()

                do {
                    let posts = try decoder.decode([Post].self, from: data)
                    completion(.success(posts))
                }
                catch {
                    completion(.failure(error))
                }

                return
            }

            completion(.failure(PostsError.empty))
        }

        task.resume()

        return task
    }
}


final class RemotePosts : RemoteContent {

    @Published private(set) var loadingState: RemoteContentLoadingState<[Post]> = .none

    private var token: AnyObject?

    private let store = PostsStore()

    func load() {
        guard token == nil else { return }

        loadingState = .inProgress
        token = store.fetchPosts { [weak self] result in
            guard let self = self else { return }

            switch result {
                case .success(let posts):
                    self.loadingState = .success(posts)
                case .failure(let error):
                    self.loadingState = .failure(error.localizedDescription)
            }
        }
    }

    func cancel() {
        loadingState = .none
        token = nil
    }
}


let content = RemotePosts()

let view = RemoteContentView(remoteContent: content) { posts in
    List(posts, id: \Post.id) { post in
        VStack {
            Text(post.title)
            Text(post.body)
        }
    }
}

PlaygroundSupport.PlaygroundPage.current.setLiveView(view)
