//
//  StockDetailLoader.swift
//  MarketApp
//
//  Created by Amin faruq on 07/10/26.
//

public protocol StockDetailLoader {
    func loadProfile(symbol: String) async throws -> CompanyProfileModel
    func loadQuote(symbol: String) async throws -> StockQuoteModel
}
