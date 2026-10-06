//
//  RemoteStockDetailLoaderTests.swift
//  MarketApp
//
//  Created by Amin faruq on 07/10/26.
//

import XCTest
import MarketCore

final class RemoteStockDetailLoader {
    
    private let url: URL
    private let client: HTTPClient
    
    init (url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }
    
    func loadProfile(symbol: String) async throws -> CompanyProfileModel {
        let queryItems = [
            URLQueryItem(name: "symbol", value: symbol)
        ]
        
        let requestURL = url.appendingQueryItems(queryItems)
        
        _ = try? await client.get(from: requestURL)
        
        // Dummy
        return CompanyProfileModel(
            symbol: "symbol",
            name: "name",
            logoURL: URL(string: ""),
            industry: "industry",
            currency: "currency",
            exchange: "exchange"
        )
    }
}

final class RemoteStockDetailLoaderTests: XCTestCase {
    
    func test_init_doesNotPerformNetworkRequest() {
        let (_, client) = makeSUT()
        
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
    
    // MARK: PROFILE
    func test_loadProfile_requestsDataFromURL() async {
        let query = "AAPL"
        let url = anyURL()
        let expectedURL = url.appendingQueryItems([
            URLQueryItem(name: "symbol", value: query)
        ])
        let (sut, client) = makeSUT(url: url)
        
        _ = try? await sut.loadProfile(symbol: query)
        
        XCTAssertEqual(client.requestedURLs, [expectedURL])
        XCTAssertEqual(client.requestedURLs.first?.query, "symbol=\(query)")
    }
    
    //MARK: - HELPERS
    private func makeSUT(
        url: URL = anyURL(),
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: RemoteStockDetailLoader, client: HTTPClientSpy){
        let client = HTTPClientSpy()
        let sut = RemoteStockDetailLoader(url: url, client: client)
        trackForMemoryLeaks(client, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        
        return (sut, client)
    }
}
