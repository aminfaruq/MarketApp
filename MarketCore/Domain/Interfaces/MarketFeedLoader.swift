//
//  MarketFeedLoader.swift
//  MarketApp
//
//  Created by Amin faruq on 07/10/26.
//

public protocol MarketFeedLoader {
    /// GET https://finnhub.io/api/v1/quote?symbol={symbol}&token={API_KEY}
    func loadQuotes(symbols: [String]) async throws -> [StockQuoteModel]
    
    /// GET https://finnhub.io/api/v1/news?category=general&token={API_KEY}
    func loadMarketNews() async throws -> [MarketNewsModel]
}
