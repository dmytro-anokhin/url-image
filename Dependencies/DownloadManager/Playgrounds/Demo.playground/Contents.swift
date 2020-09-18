import PlaygroundSupport
import Combine
import Foundation
import DownloadManager
import FileCache


PlaygroundSupport.PlaygroundPage.current.needsIndefiniteExecution = true

let downloadManager = DownloadManager(urlCache: FileCache())

// let url = URL(string: "http://optipng.sourceforge.net/pngtech/img/lena.png#\(UUID().uuidString)")!
let url = URL(string: "http://optipng.sourceforge.net/pngtech/img/lena.png")!
let download = Download(destination: .onDisk(NSTemporaryDirectory()), url: url)


let publisher = downloadManager.publisher(for: download)
    .map {
        print("Map \($0)")
    }
    .subscribe(on: DispatchQueue.main)
    .sink {
        print("completion: \($0)")

        switch $0 {
            case .finished:
                print("Finished")

            case .failure(let error):
                print(error)
        }
    }
    receiveValue: {
        print("value: \($0)")
    }

DispatchQueue.main.asyncAfter(deadline: .now() + 60.0) {
}

/*
let download = Download(destination: .inMemory, url: url)
let publisher = URLSessionCoordinator.shared.publisher(for: download)
    .map {
        print("Map \($0)")
    }
    .subscribe(on: DispatchQueue.main)
    .sink {
        print("completion: \($0)")

        switch $0 {
            case .finished:
                print("Finished")

            case .failure(let error):
                print(error)
        }
    }
    receiveValue: {
        print("value: \($0)")
    }
*/
////.map {
////    Just($0).setErrorType(Error.self)
////}
//.sink {
//    print("Completion: \($0)")
//}
//
//print(publisher)


//let download1 = Download(destination: .inMemory, url: url)
//
//let cancellable1_0 = DownloadService.shared.manager.publisher(for: download1).subscribe(on: DispatchQueue.main).sink {
//    print("1_0 completion: \($0)")
//}
//receiveValue: {
//    print("1_0 value: \($0)")
//}
//
//let cancellable1_1 = DownloadService.shared.manager.publisher(for: download1).subscribe(on: DispatchQueue.main).sink {
//    print("1_1 completion: \($0)")
//}
//receiveValue: {
//    print("1_1 value: \($0)")
//}
//
//DispatchQueue.main.asyncAfter(deadline: .now() + 60.0) {
//    print("Cancel 0")
//    cancellable1_0.cancel()
//    print("Cancel 1")
//    cancellable1_1.cancel()
//    // print(publisher)
//}

//URLSessionCoordinator.shared.register(download1) { controller in
//
//    print(controller)
//
//    let cancellable1 = controller.downloadPublisher().subscribe(on: DispatchQueue.main).sink {
//        print("sink: \($0)")
//    } receiveValue: {
//        print("sink, value: \($0)")
//    }
//
//    DispatchQueue.main.asyncAfter(deadline: .now() + 60.0) {
//        cancellable1.cancel()
//    }
//
////    DispatchQueue.main.async {
////        controller.start()
////    }
//}
//
//DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
//    let download2 = Download(url: url, inMemory: true)
//
//    URLSessionCoordinator.shared.register(download2) { controller in
//
//        print(controller)
//
//        DispatchQueue.main.async {
//            controller.start()
//        }
//    }
//}
//
//
