//
//  DownloadManager.swift
//  
//
//  Created by Dmytro Anokhin on 29/07/2020.
//

import Foundation
import Network

@globalActor
actor DownloadManagerActor {
    static let shared = DownloadManagerActor()
}

@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
public final class DownloadManager: Sendable {

    let coordinator: URLSessionCoordinator
    
    typealias Stream = AsyncStream<Result<DownloadInfo, Error>>
    
    @DownloadManagerActor
    private var subscribers = [UUID: Stream.Continuation]()
    @DownloadManagerActor
    private var relations = [URL: Set<UUID>]()

    public init() {
        let configuration = URLSessionConfiguration.default
        let options = NWProtocolTLS.Options()
        sec_protocol_options_set_min_tls_protocol_version(options.securityProtocolOptions, .TLSv12)
        sec_protocol_options_add_tls_application_protocol(options.securityProtocolOptions, "h2")
        sec_protocol_options_add_tls_application_protocol(options.securityProtocolOptions, "http/1.1")
        coordinator = URLSessionCoordinator(urlSessionConfiguration: configuration)
    }
    
    public func download(for download: Download) -> AsyncStream<Result<DownloadInfo, Error>> {
        let coordinator = self.coordinator
        let publishers = self.publishers
        
        let (stream, continuation) = AsyncStream<Result<DownloadInfo, Error>>.makeStream(bufferingPolicy: .bufferingNewest(1))
        let uuid = UUID()
        let task = Task { [weak self] in
            guard let self else { return }
            await self.cache(uuid, in: download.url, continuation: continuation)
            let _ = await publishers.store(download, coordinator: coordinator)
            await self.start(download)
        }
        continuation.onTermination = { [weak self] _ in
            task.cancel()
            Task { @DownloadManagerActor in
                self?.uncache(uuid)
            }
        }
        return stream
    }
    
    private let publishers = PublishersHolder()
    
    private func start(_ download: Download) async {
        let item = await publishers.store(download, coordinator: coordinator)
        do {
            for try await value in item {
                await self.broadcast(to: download, with: .success(value))
            }
        } catch {
            await self.broadcast(to: download, with: .failure(error))
        }
    }
    
    @DownloadManagerActor
    private func cache(_ uuid: UUID, in url: URL, continuation: Stream.Continuation) {
        subscribers[uuid] = continuation
        relations[url] = (relations[url] ?? Set<UUID>()).union([uuid])
    }
    
    @DownloadManagerActor
    private func uncache(_ uuid: UUID) {
        if let (url, sets) = relations.first(where: { $0.value.contains(uuid) }) {
            let next = sets.subtracting([uuid])
            relations[url] = next
        }
        subscribers.removeValue(forKey: uuid)
    }
    
    @DownloadManagerActor
    private func broadcast(to download: Download, with result: Result<DownloadInfo, DownloadError>) {
        guard let relation = relations[download.url] else {
            return
        }
        let downstreams = relation.compactMap({ ($0, subscribers[$0]) })
        for (_, continuation) in downstreams {
            switch result {
            case .success(let info):
                continuation?.yield(result)
            case .failure(_):
                continuation?.yield(result)
            }
        }
    }
}

enum DownloadEventError: Error {
    case cancelled
}

@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
actor PublishersHolder {
    typealias Stream = AsyncThrowingStream<DownloadInfo, DownloadError>
    
    private var publishers: [URL: DownloadAsyncTask] = [:]
    private var subscribers = [UUID: Stream.Continuation]()
    private var relations = [URL: Set<UUID>]()
    private var runnings = [URL: Task<Void, Never>]()
    
    deinit {
        let cache = subscribers.map(\.value)
        subscribers.removeAll()
        cache.forEach {
            $0.finish()
        }
    }
    
    private func cache(_ uuid: UUID, in url: URL, continuation: Stream.Continuation) {
        continuation.onTermination = { [weak self] _ in
            guard let self else { return }
            Task {
                await self.uncache(uuid)
            }
        }
        subscribers[uuid] = continuation
        relations[url] = (relations[url] ?? Set<UUID>()).union([uuid])
    }
    
    private func uncache(_ uuid: UUID) {
        if let (url, sets) = relations.first(where: { $0.value.contains(uuid) }) {
            let next = sets.subtracting([uuid])
            relations[url] = next
//            if next.isEmpty, let publisher = publishers[url] {
//                publisher.coordinator.cancelDownload(publisher.download)
//                publishers.removeValue(forKey: url)
//                runnings[url]?.cancel()
//                runnings.removeValue(forKey: url)
//            }
        }
        subscribers.removeValue(forKey: uuid)
    }
    
    private func broadcast(to download: Download, with result: Result<DownloadInfo, DownloadError>) {
        guard let downstreams = relations[download.url]?.compactMap({ subscribers[$0] }) else {
            return
        }
        for continuation in downstreams {
            switch result {
            case .success(let info):
                continuation.yield(info)
                if case .completion = info {
                    continuation.finish()
                }
            case .failure(let error):
                continuation.finish(throwing: error)
            }
        }
    }
    
    func store(_ download: Download, coordinator: URLSessionCoordinator) -> Stream {
        let publisher: DownloadAsyncTask
        let newTask: Bool
        if let current = publishers[download.url] {
            publisher = current
            newTask = false
//            print("use exists task for \(download.url)")
        } else {
            publisher = DownloadAsyncTask(download: download, coordinator: coordinator)
            publishers[download.url] = publisher
            newTask = true
//            print("create new publisher for \(download.url)")
        }
        let id = UUID()
        let (stream, continuation) = Stream.makeStream(bufferingPolicy: .bufferingNewest(1))
        continuation.onTermination = { [weak self] _ in
            Task {
                guard let self else { return }
                await self.uncache(id)
            }
        }
        cache(id, in: download.url, continuation: continuation)
        if runnings[download.url] == nil {
            let queue = publisher.start().compactMap({ $0 as? Result<DownloadInfo, DownloadError> })
            runnings[download.url] = Task { [weak self] in
                do {
                    for try await item in queue {
                        guard let self else { return }
                        await self.broadcast(to: download, with: item)
                    }
                    guard let self else { return }
                    await self.clearAll(download, coordinator: coordinator)
                } catch {
                    guard let self else { return }
                    await self.broadcast(to: download, with: .failure(error))
                }
            }
        }
        return stream
    }
    
    private func clearAll(_ download: Download, coordinator: URLSessionCoordinator) {
        coordinator.cancelDownload(download)
        self.runnings[download.url]?.cancel()
        self.runnings.removeValue(forKey: download.url)
    }
}
