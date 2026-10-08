//
//  LiveMarketStreamViewModelTests.swift
//  MarketApp
//
//  Created by Amin faruq on 08/10/26.
//

import XCTest
import RxSwift
import MarketCore
import MarketPresentation

final class LiveMarketStreamViewModelTests: XCTestCase {
    
    func test_init_doesNotPerformSideEffects() {
        let (_, service) = makeSUT()
        
        XCTAssertEqual(service.connectCallCount, 0)
        XCTAssertTrue(service.subscribedSymbols.isEmpty)
    }
    
    // MARK: - Helpers
    private func makeSUT(
        symbol: String = "AAPL",
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: LiveMarketStreamViewModel, service: LiveMarketStreamServiceSpy) {
        let service = LiveMarketStreamServiceSpy()
        let sut = LiveMarketStreamViewModel(service: service, symbol: symbol)
        trackForMemoryLeaks(service, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, service)
    }
    
    private class LiveMarketStreamServiceSpy: LiveMarketStreamService {
        private(set) var connectCallCount = 0
        private(set) var disconnectCallCount = 0
        private(set) var subscribedSymbols = [String]()
        private(set) var unsubscribeSymbols = [String]()
        
        private var continuation: AsyncStream<LiveTradeModel>.Continuation?
        
        var tradeStream: AsyncStream<LiveTradeModel> {
            AsyncStream { continuation = $0  }
        }
        
        func connect() {
            connectCallCount += 1
        }
        
        func disconnect() {
            disconnectCallCount += 1
        }
        
        func subscribe(to symbol: String) async throws {
            subscribedSymbols.append(symbol)
        }
        
        func unsubscribe(from symbol: String) async throws {
            unsubscribeSymbols.append(symbol)
        }
        
        func emitTrade(_ trade: LiveTradeModel) {
            continuation?.yield(trade)
        }
    }
}
