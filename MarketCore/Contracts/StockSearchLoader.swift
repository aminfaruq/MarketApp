//
//  StockSearchLoader.swift
//  MarketApp
//
//  Created by Amin faruq on 07/10/26.
//

import Foundation

public protocol StockSearchLoader {
    func search(query: String) async throws -> [SearchResultModel]
}
