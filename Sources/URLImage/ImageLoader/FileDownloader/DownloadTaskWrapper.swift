//
//  DownloadTaskWrapper.swift
//  
//
//  Created by Dmytro Anokhin on 16/01/2020.
//

import Foundation


final class DownloadTaskWrapper {

    enum State {

        case idle

        case running(progress: Float?)

        case complete(result: Result<URL, Error>)

        func canTransition(to newState: State) -> Bool {
            true
//            switch self {
//                case .idle:
//                    switch newState {
//                        case .running(_), .complete(_):
//                            return true
//
//                        default:
//                            return false
//                    }
//
//                case .running(_):
//                    switch newState {
//                        case .running(_), .complete(_):
//                            return true
//
//                        default:
//                            return false
//                    }
//
//                case .complete(_):
//                    switch newState {
//                        case .complete(_):
//                            return true
//
//                        default:
//                            return false
//                    }
//            }
        }
    }

    struct Notification {

        static let didProgress = Foundation.Notification.Name(rawValue: "DownloadTaskWrapper.Notification.didProgress")

        static let didComplete = Foundation.Notification.Name(rawValue: "DownloadTaskWrapper.Notification.didComplete")

        static let progress = "progress"

        static let result = "result"
    }

    static func make(with request: URLRequest, urlSession: URLSession) -> DownloadTaskWrapper {
        let task = urlSession.downloadTask(with: request)
        return DownloadTaskWrapper(task: task, url: request.url!)
    }

    private let task: URLSessionTask

    let url: URL

    private init(task: URLSessionTask, url: URL) {
        self.task = task
        self.url = url
    }

    deinit {
        log_debug(self, "Deinit task wrapper for \(url)", detail: log_extreme)
    }

    private(set) var state: State = .idle

    func transition(to newState: State, closure: () -> Void) {
        guard state.canTransition(to: newState) else {
            log_debug(self, "Can not transition from: \(state) to \(newState)", detail: log_detailed)
            return
        }
        // assert(state.canTransition(to: newState), "Can not transition from: \(state) to \(newState)")
        state = newState

        closure()

        switch state {
            case .idle:
                break

            case .running(let progress):
                if let progress = progress {
                    let userInfo = [DownloadTaskWrapper.Notification.progress : progress]
                    NotificationCenter.default.post(name: DownloadTaskWrapper.Notification.didProgress, object: self, userInfo: userInfo)
                }

            case .complete(let result):
                // TODO: Investigate why this only works on the main queue

                DispatchQueue.main.async {
                    log_debug(self, "Task wrapper: \(Unmanaged.passUnretained(self).toOpaque()) will post notification for: \(self.url)", detail: log_extreme)
                    let userInfo = [DownloadTaskWrapper.Notification.result : result]
                    NotificationCenter.default.post(name: DownloadTaskWrapper.Notification.didComplete, object: self, userInfo: userInfo)
                }
        }
    }

    func run() {
        transition(to: .running(progress: nil)) {
            task.resume()
        }
    }

    func complete(with result: Result<URL, Error>) {
        transition(to: .complete(result: result)) {
        }
    }
}


extension DownloadTaskWrapper : Hashable {

    static func == (lhs: DownloadTaskWrapper, rhs: DownloadTaskWrapper) -> Bool {
        lhs.task == rhs.task
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(task)
    }
}
