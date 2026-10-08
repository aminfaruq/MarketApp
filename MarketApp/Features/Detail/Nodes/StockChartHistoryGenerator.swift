//
//  StockChartHistoryGenerator.swift
//  MarketApp
//
//  Created by Amin faruq on 08/10/26.
//

import Foundation

public struct StockChartHistoryGenerator {
    
    public static func generatePoints(
        symbol: String,
        currentPrice: Double,
        openPrice: Double,
        highPrice: Double,
        lowPrice: Double,
        previousClose: Double,
        timeframe: StockChartTimeframe
    ) -> [StockChartDataPoint] {
        let basePrice = currentPrice > 0 ? currentPrice : 150.0
        let open = openPrice > 0 ? openPrice : basePrice * 0.99
        let high = highPrice > 0 ? max(highPrice, basePrice) : basePrice * 1.02
        let low = lowPrice > 0 ? min(lowPrice, basePrice) : basePrice * 0.98
        
        // Seed from symbol to ensure consistent curve shape per ticker
        var seed = abs(symbol.hashValue)
        func nextNoise() -> Double {
            seed = (seed &* 1103515245 &+ 12345) & 0x7fffffff
            return Double(seed % 1000) / 1000.0 - 0.5 // -0.5 ... 0.5
        }
        
        let now = Date()
        var points: [StockChartDataPoint] = []
        
        switch timeframe {
        case .day:
            let count = 28
            let calendar = Calendar.current
            var startOfDay = calendar.date(bySettingHour: 9, minute: 30, second: 0, of: now) ?? now.addingTimeInterval(-6.5 * 3600)
            if startOfDay > now {
                startOfDay = startOfDay.addingTimeInterval(-86400)
            }
            let stepInterval = 6.5 * 3600.0 / Double(count - 1)
            
            for i in 0..<count {
                let progress = Double(i) / Double(count - 1)
                let date = startOfDay.addingTimeInterval(Double(i) * stepInterval)
                
                let linear = open + (basePrice - open) * progress
                let arc = sin(progress * .pi) * (high - max(open, basePrice)) * 0.7
                let dip = -sin(progress * .pi * 2.0) * (min(open, basePrice) - low) * 0.3
                let noise = nextNoise() * (high - low) * 0.15
                
                var price = linear + arc + dip + noise
                if i == 0 { price = open }
                if i == count - 1 { price = basePrice }
                price = max(low * 0.99, min(high * 1.01, price))
                points.append(StockChartDataPoint(date: date, price: price))
            }
            
        case .week:
            let count = 7
            let totalDelta = (basePrice - (previousClose > 0 ? previousClose : basePrice * 0.97)) * 2.5
            let startPrice = basePrice - totalDelta
            for i in 0..<count {
                let progress = Double(i) / Double(count - 1)
                let date = now.addingTimeInterval(-Double(count - 1 - i) * 86400)
                let noise = nextNoise() * abs(basePrice) * 0.02
                var price = startPrice + (basePrice - startPrice) * progress + noise
                if i == count - 1 { price = basePrice }
                points.append(StockChartDataPoint(date: date, price: max(1.0, price)))
            }
            
        case .month:
            let count = 30
            let startPrice = basePrice * (1.0 - (nextNoise() * 0.12))
            for i in 0..<count {
                let progress = Double(i) / Double(count - 1)
                let date = now.addingTimeInterval(-Double(count - 1 - i) * 86400)
                let curve = sin(progress * .pi * 1.5) * (basePrice * 0.03)
                let noise = nextNoise() * (basePrice * 0.02)
                var price = startPrice + (basePrice - startPrice) * progress + curve + noise
                if i == count - 1 { price = basePrice }
                points.append(StockChartDataPoint(date: date, price: max(1.0, price)))
            }
            
        case .year:
            let count = 52
            let startPrice = basePrice * (1.0 - (0.15 + nextNoise() * 0.20))
            for i in 0..<count {
                let progress = Double(i) / Double(count - 1)
                let date = now.addingTimeInterval(-Double(count - 1 - i) * 7 * 86400)
                let curve = sin(progress * .pi * 3.0) * (basePrice * 0.05)
                let noise = nextNoise() * (basePrice * 0.025)
                var price = startPrice + (basePrice - startPrice) * progress + curve + noise
                if i == count - 1 { price = basePrice }
                points.append(StockChartDataPoint(date: date, price: max(1.0, price)))
            }
            
        case .all:
            let count = 60
            let startPrice = basePrice * 0.35 // typical 5y tech return
            for i in 0..<count {
                let progress = Double(i) / Double(count - 1)
                let date = now.addingTimeInterval(-Double(count - 1 - i) * 30 * 86400)
                let curve = sin(progress * .pi * 4.0) * (basePrice * 0.08)
                let noise = nextNoise() * (basePrice * 0.03)
                var price = startPrice + (basePrice - startPrice) * pow(progress, 1.4) + curve + noise
                if i == count - 1 { price = basePrice }
                points.append(StockChartDataPoint(date: date, price: max(1.0, price)))
            }
        }
        
        return points
    }
}
