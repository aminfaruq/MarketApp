//
//  StockSearchViewModelTests.swift
//  MarketApp
//
//  Created by Amin faruq on 07/10/26.
//

import XCTest
import MarketCore
import MarketPresentation

final class StockSearchViewModelTests: XCTestCase {
    
    func test_init_doesNotRequestSearchFromLoader() {
        let (_, loader) = makeSUT()
        
        XCTAssertTrue(loader.receivedQueries.isEmpty)
    }
    
    // MARK: - Helpers
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (sut: StockSearchViewModel, loader: StockSearchLoaderSpy) {
        let loader = StockSearchLoaderSpy()
        let sut = StockSearchViewModel(loader: loader)
        trackForMemoryLeaks(loader, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, loader)
    }
    
    private class StockSearchLoaderSpy: StockSearchLoader {
        private(set) var receivedQueries = [String]()
        
        func search(query: String) async throws -> [SearchResultModel] {
            receivedQueries.append(query)
            return []
        }
    }
}
