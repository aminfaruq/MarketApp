//
//  WebSocketClient.swift
//  MarketApp
//
//  Created by Amin faruq on 07/10/26.
//

import Foundation

public enum WebSocketEvent: Equatable, Sendable {
    case connected
    case disconnected
    case message(String)
    case error(String)
}

public protocol WebSocketClient: Sendable {
    func connect(to url: URL)
    func disconnect()
    func send(text: String) async throws
    
    var events: AsyncStream<WebSocketEvent> { get }
}
