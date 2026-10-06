//
//  RemoteStockSearchLoaderTests.swift
//  MarketApp
//
//  Created by Amin faruq on 07/10/26.
//

import XCTest
import MarketCore

final class RemoteStockSearchLoader {
    
    init(url: URL, client: HTTPClient) {
        
    }
}

final class RemoteStockSearchLoaderTests: XCTestCase {
    
    
    //MARK: - HELPERS
    private func makeSUT(
        url: URL = anyURL(),
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: RemoteStockSearchLoader, client: HTTPClientSpy){
        let client = HTTPClientSpy()
        let sut = RemoteStockSearchLoader(url: url, client: client)
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
