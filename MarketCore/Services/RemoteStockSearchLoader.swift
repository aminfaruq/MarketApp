//
//  RemoteStockSearchLoader.swift
//  MarketApp
//
//  Created by Amin faruq on 07/10/26.
//

import Foundation

public final class RemoteStockSearchLoader {
    
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
    
    private let client: HTTPClient
    private let url: URL
    private let token: String
    
    public init(url: URL, token: String, client: HTTPClient) {
        self.url = url
        self.token = token
        self.client = client
    }
    
    public func search(query: String) async throws -> [SearchResultModel] {
        let queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "token", value: token)
        ]
        
        let requestURL = url.appendingQueryItems(queryItems)
        
        let response: HTTPURLResponse
        let data: Data
        
        do {
            (data, response) = try await client.get(from: requestURL)
        } catch {
            throw Error.connectivity
        }
        
        guard response.statusCode == 200, let root = try? JSONDecoder().decode(RootDTO.self, from: data) else { throw Error.invalidData }
        
        return root.result.map { $0.toModel() }
    }
    
    private struct RootDTO: Decodable {
        let result: [RemoteResultDTO]
    }
    
    private struct RemoteResultDTO: Decodable {
        let description: String
        let displaySymbol: String
        let symbol: String
        let type: String
        
        func toModel() -> SearchResultModel {
            .init(
                symbol: symbol,
                description: description,
                displaySymbol: displaySymbol,
                type: type
            )
        }
    }
}
