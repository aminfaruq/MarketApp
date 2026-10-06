//
//  WebSocketSession.swift
//  MarketApp
//
//  Created by Amin faruq on 07/10/26.
//

import Foundation

public protocol WebSocketTask: AnyObject, Sendable {
    func resume()
    func cancel(with closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?)
    func send(_ message: URLSessionWebSocketTask.Message) async throws
    func receive() async throws -> URLSessionWebSocketTask.Message
}

public protocol WebSocketSession: Sendable {
    func makeWebSocketTask(with url: URL) -> WebSocketTask
}

extension URLSessionWebSocketTask: WebSocketTask {}

extension URLSession: WebSocketSession {
    public func makeWebSocketTask(with url: URL) -> WebSocketTask {
        return self.webSocketTask(with: url)
    }
}
