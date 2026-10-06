//
//  MarketFeedLoader.swift
//  MarketApp
//
//  Created by Amin faruq on 07/10/26.
//

public protocol MarketFeedLoader {
    func loadQuotes(symbols: [String]) async throws -> [StockQuoteModel]
    func loadMarketNews() async throws -> [MarketNewsModel]
}
