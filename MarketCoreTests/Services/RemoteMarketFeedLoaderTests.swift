//
//  RemoteMarketFeedLoaderTests.swift
//  MarketApp
//
//  Created by Amin faruq on 07/10/26.
//


import XCTest
import MarketCore

final class RemoteMarketFeedLoader {
    
    private let baseURL: URL
    private let client: HTTPClient
    private let token: String
    
    init (baseURL: URL, token: String, client: HTTPClient) {
        self.baseURL = baseURL
        self.token = token
        self.client = client
    }
    
    func loadMarketNews() async throws -> [MarketNewsModel] {
        
        let url = baseURL
            .appendingPathComponent("news")
            .appending(queryItems: [
                URLQueryItem(name: "category", value: "general"),
                URLQueryItem(name: "token", value: token),
            ])
        _ = try? await client.get(from: url)
        
        return []
    }
}

final class RemoteMarketFeedLoaderTests: XCTestCase {
    
    func test_init_doesNotRequestFromURL() {
        let (_, spy) = makeSUT()
        
        XCTAssertTrue(spy.requestedURLs.isEmpty)
    }
    
    func test_loadMarketNews_requestsDataFromURL() async {
        let token = anyToken()
        let url = anyURL()
        let expectedURL = url
            .appendingPathComponent("news")
            .appendingQueryItems([
                URLQueryItem(name: "category", value: "general"),
                URLQueryItem(name: "token", value: token)
            ])
        let (sut, client) = makeSUT(url: url, token: token)
        
        _ = try? await sut.loadMarketNews()
        
        XCTAssertEqual(client.requestedURLs, [expectedURL])
        XCTAssertEqual(client.requestedURLs.first?.query, "category=general&token=\(token)")
    }
    
    
    // MARK: - Helpers
    private func makeSUT(
        url: URL = anyURL(),
        token: String = anyToken(),
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (RemoteMarketFeedLoader, HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteMarketFeedLoader(baseURL: url, token: token, client: client)
        trackForMemoryLeaks(client, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, client)
    }
}
