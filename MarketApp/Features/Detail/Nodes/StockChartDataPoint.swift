//
//  StockChartDataPoint.swift
//  MarketApp
//
//  Created by Amin faruq on 08/10/26.
//

import Foundation

public struct StockChartDataPoint: Equatable {
    public let date: Date
    public let price: Double
    
    public init(date: Date, price: Double) {
        self.date = date
        self.price = price
    }
}
