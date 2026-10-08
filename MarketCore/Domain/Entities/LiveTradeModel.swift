//
//  LiveTradeModel.swift
//  MarketApp
//
//  Created by Amin faruq on 06/10/26.
//

import Foundation

public struct LiveTradeModel: Equatable, Sendable {
    public let symbol: String
    public let price: Double
    public let volume: Double
    public let timestamp: Date
    
    public init(symbol: String, price: Double, volume: Double, timestamp: Date) {
        self.symbol = symbol
        self.price = price
        self.volume = volume
        self.timestamp = timestamp
    }
}
