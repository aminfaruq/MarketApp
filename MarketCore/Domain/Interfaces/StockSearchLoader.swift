//
//  StockSearchLoader.swift
//  MarketApp
//
//  Created by Amin faruq on 07/10/26.
//

import Foundation

/// GET https://finnhub.io/search?q={query}&token={token}
public protocol StockSearchLoader {
    func search(query: String) async throws -> [SearchResultModel]
}
