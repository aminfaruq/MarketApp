//
//  RemoteMarketFeedLoader.swift
//  MarketApp
//
//  Created by Amin faruq on 07/10/26.
//

import Foundation

public final class RemoteMarketFeedLoader: MarketFeedLoader , @unchecked Sendable {
    
    public enum Error: Swift.Error, LocalizedError, Equatable {
        case connectivity
        case invalidData
        
        public var errorDescription: String? {
            switch self {
                case .connectivity:
                    return "Cannot connect to the server. Check your internet connection."
                case .invalidData:
                    return "The server returned an unexpected response."
            }
        }
    }
    
    private let baseURL: URL
    private let client: HTTPClient
    private let token: String
    
    public init (baseURL: URL, token: String, client: HTTPClient) {
        self.baseURL = baseURL
        self.token = token
        self.client = client
    }
    
    public func loadMarketNews() async throws -> [MarketNewsModel] {
        let url = baseURL
            .appendingPathComponent("news")
            .appending(queryItems: [
                URLQueryItem(name: "category", value: "general"),
                URLQueryItem(name: "token", value: token),
            ])
        
        let response: HTTPURLResponse
        let data: Data
        
        do {
            (data, response) = try await client.get(from: url)
        } catch {
            throw Error.connectivity
        }
        
        guard response.statusCode == 200 else {
            throw Error.invalidData
        }
        
        do {
            let root = try JSONDecoder().decode([RemoteMarketFeedDTO].self, from: data)
            return root.map({ $0.toModel() })
        } catch {
            throw Error.invalidData
        }
    }
    
    public func loadQuotes(symbols: [String]) async throws -> [StockQuoteModel] {
        guard !symbols.isEmpty else { return [] }
        
        return try await withThrowingTaskGroup(of: StockQuoteModel.self) { group in
            for symbol in symbols {
                group.addTask {
                    try await self.loadSingleQuote(symbol: symbol)
                }
            }
            
            var quotes = [StockQuoteModel]()
            for try await quote in group {
                quotes.append(quote)
            }
            
            let symbolOrder = Dictionary(uniqueKeysWithValues: symbols.enumerated().map { ($1 , $0) })
            return quotes.sorted {
                (symbolOrder[$0.symbol] ?? 0) < (symbolOrder[$1.symbol] ?? 0)
            }
        }
        
    }
    
    private func loadSingleQuote(symbol: String) async throws -> StockQuoteModel {
        let queryItems = [
            URLQueryItem(name: "symbol", value: symbol),
            URLQueryItem(name: "token", value: token)
        ]
        let requestURL = baseURL
            .appendingPathComponent("quote")
            .appendingQueryItems(queryItems)
        
        let response: HTTPURLResponse
        let data: Data
        
        do {
            (data, response) = try await client.get(from: requestURL)
        } catch {
            throw Error.connectivity
        }
        
        guard response.statusCode == 200,
              let root = try? JSONDecoder().decode(RemoteStockQuoteDTO.self, from: data) else {
            throw Error.invalidData
        }
        
        return root.toModel(symbol: symbol)
    }
    
    private struct RemoteMarketFeedDTO: Decodable {
        let datetime: Double?
        let headline: String?
        let id: Int?
        let image: String?
        let source: String?
        let summary: String?
        let url: String?
        
        func toModel() -> MarketNewsModel {
            .init(
                id: id ?? Int.random(in: 1...1000000),
                headline: headline ?? "",
                summary: summary ?? "",
                source: source ?? "Finnhub",
                imageURL: (image?.isEmpty == false) ? URL(string: image!) : nil,
                newsURL: (url?.isEmpty == false) ? URL(string: url!) : nil,
                publishedAt: Date(timeIntervalSince1970: datetime ?? Date().timeIntervalSince1970)
            )
        }
    }
    
    private struct RemoteStockQuoteDTO: Decodable {
        let c: Double?
        let d: Double?
        let dp: Double?
        let h: Double?
        let l: Double?
        let o: Double?
        let pc: Double?
        let t: Double?
        
        func toModel(symbol: String) -> StockQuoteModel {
            .init(
                symbol: symbol,
                currentPrice: c ?? 0,
                change: d ?? 0,
                percentChange: dp ?? 0,
                highPrice: h ?? 0,
                lowPrice: l ?? 0,
                openPrice: o ?? 0,
                previousClose: pc ?? 0,
                timestamp: Date(timeIntervalSince1970: t ?? Date().timeIntervalSince1970)
            )
        }
    }
    
}
