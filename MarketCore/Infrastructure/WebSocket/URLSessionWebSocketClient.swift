//
//  URLSessionWebSocketClient.swift
//  MarketApp
//
//  Created by Amin faruq on 07/10/26.
//

import Foundation

public final class URLSessionWebSocketClient: WebSocketClient, @unchecked Sendable {
    
    public enum Error: Swift.Error, Equatable {
        case notConnected
    }
    
    private let session: WebSocketSession
    private var task: WebSocketTask?
    private var receiveTask: Task<Void, Never>?
    
    private let eventContinuation: AsyncStream<WebSocketEvent>.Continuation
    public let events: AsyncStream<WebSocketEvent>
    
    public init(session: WebSocketSession = URLSession.shared) {
        self.session = session
        
        var continuation: AsyncStream<WebSocketEvent>.Continuation!
        self.events = AsyncStream { continuation = $0 }
        self.eventContinuation = continuation
    }
    
    public func connect(to url: URL) {
        let task = session.makeWebSocketTask(with: url)
        self.task = task
        task.resume()
        eventContinuation.yield(.connected)
        
        startReceiving(from: task)
    }
    
    private func startReceiving(from task: WebSocketTask) {
        receiveTask = Task { [weak self] in
            while !Task.isCancelled {
                do {
                    let message = try await task.receive()
                    guard let self = self else { break }
                    
                    switch message {
                        case .string(let text):
                            self.eventContinuation.yield(.message(text))
                        case .data(let data):
                            if let text = String(data: data, encoding: .utf8) {
                                self.eventContinuation.yield(.message(text))
                            }
                        @unknown default:
                            break
                    }
                } catch {
                    guard let self = self else { break }
                    if !Task.isCancelled {
                        self.eventContinuation.yield(.error(error.localizedDescription))
                    }
                    break
                }
            }
        }
    }
    
    public func disconnect() {
        receiveTask?.cancel()
        receiveTask = nil
        task?.cancel(with: .normalClosure, reason: nil)
        task = nil
        eventContinuation.yield(.disconnected)
    }
    
    public func send(text: String) async throws {
        guard let task = task else {
            throw Error.notConnected
        }
        try await task.send(.string(text))
    }
    
    deinit {
        disconnect()
        eventContinuation.finish()
    }
}
