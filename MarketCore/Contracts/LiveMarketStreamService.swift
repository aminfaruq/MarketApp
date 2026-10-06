//
//  LiveMarketStreamService.swift
//  MarketApp
//
//  Created by Amin faruq on 07/10/26.
//

// For Realtime Websockets
public protocol LiveMarketStreamService {
    func subscribe(to symbol: String)
    func unsubscribe(from symbol: String)
}
