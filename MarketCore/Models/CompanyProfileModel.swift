//
//  CompanyProfileModel.swift
//  MarketApp
//
//  Created by Amin faruq on 06/10/26.
//

import Foundation

public struct CompanyProfileModel: Equatable {
    public let symbol: String
    public let name: String
    public let logoURL: URL?
    public let industry: String
    public let currency: String
    public let exchange: String
    
    public init(symbol: String, name: String, logoURL: URL?, industry: String, currency: String, exchange: String) {
        self.symbol = symbol
        self.name = name
        self.logoURL = logoURL
        self.industry = industry
        self.currency = currency
        self.exchange = exchange
    }
}
