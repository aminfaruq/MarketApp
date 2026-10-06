//
//  RemoteLiveMarketStreamService.swift
//  MarketApp
//
//  Created by Amin faruq on 07/10/26.
//

import Foundation

public final class RemoteLiveMarketStreamService {
    
    private let url: URL
    private let client: WebSocketClient
    
    private let streamContinuation: AsyncStream<LiveTradeModel>.Continuation
    public let tradeStream: AsyncStream<LiveTradeModel>
    
    private var listeningTask: Task<Void, Never>?
    
    public init(url: URL, client: WebSocketClient) {
        self.url = url
        self.client = client
        
        var continuation: AsyncStream<LiveTradeModel>.Continuation!
        self.tradeStream = AsyncStream { continuation = $0 }
        self.streamContinuation = continuation
        
        listenToClientEvents()
    }
    
    public func connect() {
        client.connect(to: url)
    }
    
    public func disconnect() {
        client.disconnect()
    }
    
    public func subscribe(to symbol: String) async throws {
        let payload = #"{"symbol":"\#(symbol)","type":"subscribe"}"#

        try await client.send(text: payload)
    }
    
    public func unsubscribe(from symbol: String) async throws {
        let payload = #"{"symbol":"\#(symbol)","type":"unsubscribe"}"#
        
        try await client.send(text: payload)
    }
    
    private func listenToClientEvents() {
        listeningTask =  Task { [weak self] in
            guard let events = self?.client.events else { return }

            for await event in events {
                guard let self = self else { break }
                
                switch event {
                    case .message(let text):
                        self.parseAndEmitTrades(from: text)
                    default:
                        break
                }
            }
        }
    }
    
    deinit {
        listeningTask?.cancel()
        streamContinuation.finish()
    }
    
    private func parseAndEmitTrades(from text: String) {
        guard let data = text.data(using: .utf8), let response = try? JSONDecoder().decode(FinnhubWebSocketResponseDTO.self, from: data), response.type == "trade", let trades = response.data else { return }
        
        for tradeDTO in trades {
            streamContinuation.yield(tradeDTO.toModel())
        }
    }
    
    private struct FinnhubWebSocketResponseDTO: Decodable {
        let type: String
        let data: [FinnhubTradeDTO]?
    }
    
    private struct FinnhubTradeDTO: Decodable {
        let p: Double // price
        let s: String // symbol
        let t: Double // timestamp (milliseconds)
        let v: Double // volume
        
        func toModel() -> LiveTradeModel {
            LiveTradeModel(
                symbol: s,
                price: p,
                volume: v,
                timestamp: Date(timeIntervalSince1970: t / 1000.0)
            )
        }
    }
}
