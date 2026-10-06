//
//  SearchResultModel.swift
//  MarketApp
//
//  Created by Amin faruq on 07/10/26.
//

import Foundation

public struct SearchResultModel: Equatable, Identifiable, Sendable {
    public var id: String { symbol }
    
    public let symbol: String          // e.g. "AAPL"
    public let description: String     // e.g. "APPLE INC"
    public let displaySymbol: String   // e.g. "AAPL"
    public let type: String            // e.g. "Common Stock", "ETP"
    
    public init(
        symbol: String,
        description: String,
        displaySymbol: String,
        type: String
    ) {
        self.symbol = symbol
        self.description = description
        self.displaySymbol = displaySymbol
        self.type = type
    }
}
