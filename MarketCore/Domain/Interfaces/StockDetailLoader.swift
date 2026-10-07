//
//  StockDetailLoader.swift
//  MarketApp
//
//  Created by Amin faruq on 07/10/26.
//

public protocol StockDetailLoader {
    /// GET https://finnhub.io/api/v1/stock/profile2?symbol={symbol}&token={token}
    func loadProfile(symbol: String) async throws -> CompanyProfileModel
    
    /// GET  https://finnhub.io/api/v1/quote?symbol={symbol}&token={token}
    func loadQuote(symbol: String) async throws -> StockQuoteModel
}
