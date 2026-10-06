//
//  RemoteStockDetailLoaderTests.swift
//  MarketApp
//
//  Created by Amin faruq on 07/10/26.
//

import XCTest
import MarketCore

final class RemoteStockDetailLoader {
    
    init (url: URL, client: HTTPClient) {
        
    }
}

final class RemoteStockDetailLoaderTests: XCTestCase {
    
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
