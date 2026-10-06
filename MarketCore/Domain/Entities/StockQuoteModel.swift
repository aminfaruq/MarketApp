//
//  StockQuoteModel.swift
//  MarketApp
//
//  Created by Amin faruq on 06/10/26.
//

import Foundation

public struct StockQuoteModel: Equatable, Sendable {
    public let symbol: String
    public let currentPrice: Double
    public let change: Double
    public let percentChange: Double
    public let highPrice: Double
    public let lowPrice: Double
    public let openPrice: Double
    public let previousClose: Double
    public let timestamp: Date
    
    public init(
        symbol: String,
        currentPrice: Double,
        change: Double,
        percentChange: Double,
        highPrice: Double,
        lowPrice: Double,
        openPrice: Double,
        previousClose: Double,
        timestamp: Date
    ) {
        self.symbol = symbol
        self.currentPrice = currentPrice
        self.change = change
        self.percentChange = percentChange
        self.highPrice = highPrice
        self.lowPrice = lowPrice
        self.openPrice = openPrice
        self.previousClose = previousClose
        self.timestamp = timestamp
    }
}
