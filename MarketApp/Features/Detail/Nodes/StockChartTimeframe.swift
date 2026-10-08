//
//  StockChartTimeframe.swift
//  MarketApp
//
//  Created by Amin faruq on 08/10/26.
//

import Foundation

public enum StockChartTimeframe: String, CaseIterable {
    case day = "1D"
    case week = "1W"
    case month = "1M"
    case year = "1Y"
    case all = "ALL"
}
