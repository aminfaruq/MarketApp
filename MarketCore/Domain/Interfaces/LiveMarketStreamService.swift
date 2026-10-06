//
//  LiveMarketStreamService.swift
//  MarketApp
//
//  Created by Amin faruq on 07/10/26.
//

// For Realtime Websockets
public protocol LiveMarketStreamService {
    var tradeStream: AsyncStream<LiveTradeModel> { get }
    
    func connect()
    func disconnect()
    func subscribe(to symbol: String) async throws
    func unsubscribe(from symbol: String) async throws
}
