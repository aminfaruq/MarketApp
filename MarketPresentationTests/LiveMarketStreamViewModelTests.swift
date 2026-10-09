//
//  LiveMarketStreamViewModelTests.swift
//  MarketApp
//
//  Created by Amin faruq on 08/10/26.
//

import XCTest
import RxTest
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
        let scheduler = TestScheduler(initialClock: 0)
        let disposeBag = DisposeBag()
        
        let isConnectedObserver = scheduler.createObserver(Bool.self)
        
        let startTrigger = PublishSubject<Void>()
        let output = sut.transform(input: .init(startStreaming: startTrigger.asObservable()))
        
        output.isConnected.subscribe(isConnectedObserver).disposed(by: disposeBag)
        output.trade.subscribe().disposed(by: disposeBag)
        
        startTrigger.onNext(())
        try? await Task.sleep(nanoseconds: 50_000_000)
        
        XCTAssertEqual(service.connectCallCount, 1)
        XCTAssertEqual(service.subscribedSymbols, ["AAPL"])
        
        XCTAssertEqual(isConnectedObserver.events.compactMap { $0.value.element }, [false, true])
    }
    
    func test_tradeStream_deliversFormattedLiveTrade() async {
        let (sut, service) = makeSUT(symbol: "AAPL")
        let scheduler = TestScheduler(initialClock: 0)
        let disposeBag = DisposeBag()
        
        let tradeObserver = scheduler.createObserver(LiveTradeItemViewModel.self)
        
        let startTrigger = PublishSubject<Void>()
        let output = sut.transform(input: .init(startStreaming: startTrigger.asObservable()))
        
        output.trade.subscribe(tradeObserver).disposed(by: disposeBag)
        startTrigger.onNext(())
        try? await Task.sleep(nanoseconds: 50_000_000)
        
        let now = Date()
        service.emitTrade(LiveTradeModel(symbol: "AAPL", price: 180.5, volume: 100, timestamp: now))
        try? await Task.sleep(nanoseconds: 50_000_000)
        
        let expected = LiveTradeItemViewModel(
            symbol: "AAPL",
            price: 180.5,
            formattedPrice: "$180.50",
            volume: 100,
            timestamp: now,
            direction: .same
        )
        let trades = tradeObserver.events.compactMap { $0.value.element }
        XCTAssertEqual(trades, [expected])
    }
    
    func test_tradeStream_calculatesPriceDirectionCorrectly() async {
        let (sut, service) = makeSUT(symbol: "AAPL")
        let scheduler = TestScheduler(initialClock: 0)
        let disposeBag = DisposeBag()
        
        let tradeObserver = scheduler.createObserver(LiveTradeItemViewModel.self)
        
        let startTrigger = PublishSubject<Void>()
        let output = sut.transform(input: .init(startStreaming: startTrigger.asObservable()))
        
        output.trade.subscribe(tradeObserver).disposed(by: disposeBag)
        startTrigger.onNext(())
        try? await Task.sleep(nanoseconds: 50_000_000)
        
        let now = Date()
        service.emitTrade(LiveTradeModel(symbol: "AAPL", price: 100.0, volume: 10, timestamp: now))
        service.emitTrade(LiveTradeModel(symbol: "AAPL", price: 105.0, volume: 10, timestamp: now))
        service.emitTrade(LiveTradeModel(symbol: "AAPL", price: 102.0, volume: 10, timestamp: now))
        try? await Task.sleep(nanoseconds: 50_000_000)
        
        let directions = tradeObserver.events.compactMap { $0.value.element?.direction }
        XCTAssertEqual(directions, [.same, .up, .down])
    }
    
    func test_tradeStream_filtersOutTradesFromDifferentSymbols() async {
        let (sut, service) = makeSUT(symbol: "AAPL")
        let scheduler = TestScheduler(initialClock: 0)
        let disposeBag = DisposeBag()
        
        let tradeObserver = scheduler.createObserver(LiveTradeItemViewModel.self)
        
        let startTrigger = PublishSubject<Void>()
        let output = sut.transform(input: .init(startStreaming: startTrigger.asObservable()))
        
        output.trade.subscribe(tradeObserver).disposed(by: disposeBag)
        startTrigger.onNext(())
        try? await Task.sleep(nanoseconds: 50_000_000)
        
        let now = Date()
        service.emitTrade(LiveTradeModel(symbol: "TSLA", price: 250.0, volume: 50, timestamp: now))
        service.emitTrade(LiveTradeModel(symbol: "AAPL", price: 180.0, volume: 10, timestamp: now))
        try? await Task.sleep(nanoseconds: 50_000_000)
        
        let symbols = tradeObserver.events.compactMap { $0.value.element?.symbol }
        XCTAssertEqual(symbols, ["AAPL"])
    }
    
    func test_stopStreaming_unsubscribesAndDisconnects() async {
        let (sut, service) = makeSUT(symbol: "AAPL")
        let scheduler = TestScheduler(initialClock: 0)
        let disposeBag = DisposeBag()
        
        let isConnectedObserver = scheduler.createObserver(Bool.self)
        
        let startTrigger = PublishSubject<Void>()
        let stopTrigger = PublishSubject<Void>()
        let output = sut.transform(input: .init(
            startStreaming: startTrigger.asObservable(),
            stopStreaming: stopTrigger.asObservable()
        ))
        
        output.isConnected.subscribe(isConnectedObserver).disposed(by: disposeBag)
        output.trade.subscribe().disposed(by: disposeBag)
        
        startTrigger.onNext(())
        try? await Task.sleep(nanoseconds: 50_000_000)
        
        stopTrigger.onNext(())
        try? await Task.sleep(nanoseconds: 50_000_000)
        
        XCTAssertEqual(service.unsubscribeSymbols, ["AAPL"])
        XCTAssertEqual(service.disconnectCallCount, 1)
        XCTAssertEqual(isConnectedObserver.events.compactMap { $0.value.element }, [false, true, false])
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
