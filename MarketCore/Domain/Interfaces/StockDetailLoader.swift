//
//  StockDetailLoader.swift
//  MarketApp
//
//  Created by Amin faruq on 07/10/26.
//

public protocol StockDetailLoader {
    /// GET https://finnhub.io/stock/profile2?symbol={symbol}
    func loadProfile(symbol: String) async throws -> CompanyProfileModel
    
    /// GET https://finnhub.io/quote?symbol={symbol}
    func loadQuote(symbol: String) async throws -> StockQuoteModel
}
