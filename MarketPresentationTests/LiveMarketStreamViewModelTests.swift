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
    
    func test_startStreaming_connectAndSubscribesToSymbol() async {
        let (sut, service) = makeSUT(symbol: "AAPL")
        let startTrigger = PublishSubject<Void>()
        let output = sut.transform(input: .init(startStreaming: startTrigger.asObservable()))
        
        let disposeBag = DisposeBag()
        let exp = expectation(description: "Wait for subscription")
        
        output.trade.subscribe().disposed(by: disposeBag)
        
        startTrigger.onNext(())
        
        for _ in 0..<100 {
            if !service.subscribedSymbols.isEmpty {
                exp.fulfill()
                break
            }
            
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
        await fulfillment(of: [exp], timeout: 2.0)
        
        XCTAssertEqual(service.connectCallCount, 1)
        XCTAssertEqual(service.subscribedSymbols, ["AAPL"])
    }
    
    func test_tradeStream_deliversFormattedLiveTrade() async {
        let (sut, service) = makeSUT(symbol: "AAPL")
        let startTrigger = PublishSubject<Void>()
        let output = sut.transform(input: .init(startStreaming: startTrigger.asObservable()))
        
        var receivedTrades = [LiveTradeItemViewModel]()
        let disposeBag = DisposeBag()
        let exp = expectation(description: "Wait for trade emission")
        
        output.trade
            .subscribe(onNext: { item in
                receivedTrades.append(item)
                exp.fulfill()
            })
            .disposed(by: disposeBag)
        
        startTrigger.onNext(())
        
        for _ in 0..<100 {
            if !service.subscribedSymbols.isEmpty { break }
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
        
        let now = Date()
        service.emitTrade(LiveTradeModel(symbol: "AAPL", price: 180.5, volume: 100, timestamp: now))
        
        await fulfillment(of: [exp], timeout: 2.0)
        
        let expected = LiveTradeItemViewModel(
            symbol: "AAPL",
            price: 180.5,
            formattedPrice: "$180.50",
            volume: 100,
            timestamp: now,
            direction: .same
        )
        XCTAssertEqual(receivedTrades, [expected])
    }
    
    func test_tradeStream_calculatesPriceDirectionCorrectly() async {
        let (sut, service) = makeSUT(symbol: "AAPL")
        let startTrigger = PublishSubject<Void>()
        let output = sut.transform(input: .init(startStreaming: startTrigger.asObservable()))
        
        var receivedDirections = [PriceChangeDirection]()
        let disposeBag = DisposeBag()
        let exp = expectation(description: "Wait for 3 trades")
        
        output.trade
            .subscribe(onNext: { item in
                receivedDirections.append(item.direction)
                if receivedDirections.count == 3 {
                    exp.fulfill()
                }
            })
            .disposed(by: disposeBag)
        
        startTrigger.onNext(())
        
        for _ in 0..<100 {
            if !service.subscribedSymbols.isEmpty { break }
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
        
        let now = Date()
        // Trade 1: initial price 100 -> .same
        service.emitTrade(LiveTradeModel(symbol: "AAPL", price: 100.0, volume: 10, timestamp: now))
        // Trade 2: price up to 105 -> .up
        service.emitTrade(LiveTradeModel(symbol: "AAPL", price: 105.0, volume: 10, timestamp: now))
        // Trade 3: price down to 102 -> .down
        service.emitTrade(LiveTradeModel(symbol: "AAPL", price: 102.0, volume: 10, timestamp: now))
        
        await fulfillment(of: [exp], timeout: 2.0)
        
        XCTAssertEqual(receivedDirections, [.same, .up, .down])
    }
    
    func test_tradeStream_filtersOutTradesFromDifferentSymbols() async {
        let (sut, service) = makeSUT(symbol: "AAPL")
        let startTrigger = PublishSubject<Void>()
        let output = sut.transform(input: .init(startStreaming: startTrigger.asObservable()))
        
        var receivedSymbols = [String]()
        let disposeBag = DisposeBag()
        let exp = expectation(description: "Wait for AAPL trade only")
        
        output.trade
            .subscribe(onNext: { item in
                receivedSymbols.append(item.symbol)
                exp.fulfill()
            })
            .disposed(by: disposeBag)
        
        startTrigger.onNext(())
        
        for _ in 0..<100 {
            if !service.subscribedSymbols.isEmpty { break }
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
        
        let now = Date()
        // Other stock (TSLA) -> should ignore!
        service.emitTrade(LiveTradeModel(symbol: "TSLA", price: 250.0, volume: 50, timestamp: now))
        // AAPL -> should accept!
        service.emitTrade(LiveTradeModel(symbol: "AAPL", price: 180.0, volume: 10, timestamp: now))
        
        await fulfillment(of: [exp], timeout: 2.0)
        
        XCTAssertEqual(receivedSymbols, ["AAPL"])
    }
    
    func test_stopStreaming_unsubscribesAndDisconnects() async {
        let (sut, service) = makeSUT(symbol: "AAPL")
        let startTrigger = PublishSubject<Void>()
        let stopTrigger = PublishSubject<Void>()
        let output = sut.transform(input: .init(
            startStreaming: startTrigger.asObservable(),
            stopStreaming: stopTrigger.asObservable()
        ))
        
        let disposeBag = DisposeBag()
        output.trade.subscribe().disposed(by: disposeBag)
        
        startTrigger.onNext(())
        
        for _ in 0..<100 {
            if !service.subscribedSymbols.isEmpty { break }
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
        
        // call stopStreaming
        stopTrigger.onNext(())
        
        // wait for unsubscribe
        let exp = expectation(description: "Wait for unsubscribe and disconnect")
        for _ in 0..<100 {
            if !service.unsubscribeSymbols.isEmpty && service.disconnectCallCount > 0 {
                exp.fulfill()
                break
            }
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
        await fulfillment(of: [exp], timeout: 2.0)
        
        XCTAssertEqual(service.unsubscribeSymbols, ["AAPL"])
        XCTAssertEqual(service.disconnectCallCount, 1)
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
        
        let tradeStream: AsyncStream<LiveTradeModel>
        private var continuation: AsyncStream<LiveTradeModel>.Continuation?
        
        init() {
            var cont: AsyncStream<LiveTradeModel>.Continuation?
            self.tradeStream = AsyncStream { continuation in
                    cont = continuation
            }
            self.continuation = cont
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
