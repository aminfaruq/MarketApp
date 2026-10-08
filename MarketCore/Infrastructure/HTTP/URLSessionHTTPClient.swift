//
//  URLSessionHTTPClient.swift
//  MarketApp
//
//  Created by Amin faruq on 07/10/26.
//

import Foundation

public final class URLSessionHTTPClient: HTTPClient {
    
    public struct UnexpectedValueRepresentation: Error {}
    
    private let session: URLSession
    
    public init (session: URLSession = .shared) {
        self.session = session
    }
    
    public func get(from url: URL) async throws -> HTTPClient.Result {
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw UnexpectedValueRepresentation()
        }
        
        return (data, httpResponse)
    }
    
}
