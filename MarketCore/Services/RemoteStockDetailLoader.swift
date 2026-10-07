//
//  RemoteStockDetailLoader.swift
//  MarketApp
//
//  Created by Amin faruq on 07/10/26.
//

import Foundation

public final class RemoteStockDetailLoader: StockDetailLoader, @unchecked Sendable {
    
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
    
    public func loadProfile(symbol: String) async throws -> CompanyProfileModel {
        let queryItems = [
            URLQueryItem(name: "symbol", value: symbol),
            URLQueryItem(name: "token", value: token)
        ]
        
        let requestURL = baseURL
            .appendingPathComponent("stock/profile2")
            .appendingQueryItems(queryItems)
        let response: HTTPURLResponse
        let data: Data
        
        do {
            (data, response) = try await client.get(from: requestURL)
        } catch {
            throw Error.connectivity
        }
        
        guard response.statusCode == 200, let root = try? JSONDecoder().decode(RemoteProfileDTO.self, from: data) else { throw Error.invalidData }
        
        return root.toModel()
    }
    
    public func loadQuote(symbol: String) async throws -> StockQuoteModel {
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
        
        guard response.statusCode == 200, let root = try? JSONDecoder().decode(RemoteStockQuoteDTO.self, from: data) else { throw Error.invalidData }
        
        
        return root.toModel(symbol: symbol)
    }
    
    private struct RemoteProfileDTO: Decodable {
        let ticker: String
        let name: String
        let currency: String
        let exchange: String
        let logo: String
        let finnhubIndustry: String
        
        func toModel() -> CompanyProfileModel {
            .init(
                symbol: ticker,
                name: name,
                logoURL: URL(string: logo),
                industry: finnhubIndustry,
                currency: currency,
                exchange: exchange
            )
        }
    }
    
    private struct RemoteStockQuoteDTO: Decodable {
        let c: Double
        let d: Double
        let dp: Double
        let h: Double
        let l: Double
        let o: Double
        let pc: Double
        let t: Double
        
        func toModel(symbol: String) -> StockQuoteModel{
            .init(
                symbol: symbol,
                currentPrice: c,
                change: d,
                percentChange: dp,
                highPrice: h,
                lowPrice: l,
                openPrice: o,
                previousClose: pc,
                timestamp: Date(timeIntervalSince1970: t)
            )
        }
    }
}
