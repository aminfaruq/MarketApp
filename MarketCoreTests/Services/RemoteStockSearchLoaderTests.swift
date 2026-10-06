//
//  RemoteStockSearchLoaderTests.swift
//  MarketApp
//
//  Created by Amin faruq on 07/10/26.
//

import XCTest
import MarketCore

final class RemoteStockSearchLoader {
    
    private let client: HTTPClient
    private let url: URL
    private let token: String
    
    init(url: URL, token: String, client: HTTPClient) {
        self.url = url
        self.token = token
        self.client = client
    }
    
    func search(query: String) async throws -> [SearchResultModel] {
        let queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "token", value: token)
        ]
        
        let requestURL = url.appendingQueryItems(queryItems)
        
        _ = try? await client.get(from: requestURL)
        
        return []
    }
}

final class RemoteStockSearchLoaderTests: XCTestCase {
    
    func test_init_doesNotPerformNetworkRequest() {
        let (_, client) = makeSUT()
        
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
    
    func test_search_requestsDataFromURL() async {
        let query = "AAPL"
        let url = anyURL()
        let token = anyToken()
        let expectedURL = url.appendingQueryItems([
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "token", value: token)
        ])
        let (sut, client) = makeSUT(url: url)
        
        _ = try? await sut.search(query: query)
        
        XCTAssertEqual(client.requestedURLs, [expectedURL])
        XCTAssertEqual(client.requestedURLs.first?.query, "q=\(query)&token=\(token)")
    }
    
    
    //MARK: - HELPERS
    private func makeSUT(
        url: URL = anyURL(),
        token: String = anyToken(),
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: RemoteStockSearchLoader, client: HTTPClientSpy){
        let client = HTTPClientSpy()
        let sut = RemoteStockSearchLoader(url: url, token: token, client: client)
        trackForMemoryLeaks(client, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        
        return (sut, client)
    }
    
    private class HTTPClientSpy: HTTPClient {
        var requestedURLs = [URL]()
        private var stub: Result<HTTPClient.Result, Error>?
        
        func stub(with result: Result<HTTPClient.Result, Error>) {
            stub = result
        }
        
        func stub(statusCode: Int, data: Data) {
            let response = HTTPURLResponse(url: anyURL(), statusCode: statusCode, httpVersion: nil, headerFields: nil)!
            stub = .success((data, response))
        }
        
        func get(from url: URL) async throws -> HTTPClient.Result {
            requestedURLs.append(url)
            
            let response = HTTPURLResponse(
                url: anyURL(),
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return try stub?.get() ?? (anyData(), response)
        }
    }
}
