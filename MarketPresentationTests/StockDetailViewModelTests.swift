//
//  StockDetailViewModelTests.swift
//  MarketApp
//
//  Created by Amin faruq on 08/10/26.
//

import XCTest
import RxTest
import RxSwift
import MarketCore
import MarketPresentation

final class StockDetailViewModelTests: XCTestCase {
    
    func test_init_doesNotCallLoader() {
        let (_, loader) = makeSUT()
        
        XCTAssertEqual(loader.loadProfileCallCount, 0)
        XCTAssertEqual(loader.loadQuoteCallCount, 0)
    }
    
    func test_loadTrigger_requestsProfileAndQuoteWithCorrectSymbol() async {
        let symbol = "AAPL"
        let (sut, loader) = makeSUT(symbol: symbol)
        let scheduler = TestScheduler(initialClock: 0)
        let disposeBag = DisposeBag()
        
        let detailObserver = scheduler.createObserver(StockDetailItemViewModel.self)
        
        let loadTrigger = PublishSubject<Void>()
        let output = sut.transform(input: .init(loadTrigger: loadTrigger.asObservable()))
        
        output.detail.subscribe(detailObserver).disposed(by: disposeBag)
        
        loadTrigger.onNext(())
        try? await Task.sleep(nanoseconds: 50_000_000)
        
        XCTAssertEqual(loader.receivedProfileSymbols, [symbol])
        XCTAssertEqual(loader.receivedQuoteSymbols, [symbol])
    }
    
    func test_loadTrigger_deliversStockDetailOnSuccess() async {
        let (sut, loader) = makeSUT(symbol: "AAPL")
        let profile = makeProfile(symbol: "AAPL", name: "Apple Inc.")
        let quote = makeQuote(symbol: "AAPL", price: 150.25, change: 2.50, percentChange: 1.25)
        
        loader.stubProfile(with: .success(profile))
        loader.stubQuote(with: .success(quote))
        
        let scheduler = TestScheduler(initialClock: 0)
        let disposeBag = DisposeBag()
        let detaiObserver = scheduler.createObserver(StockDetailItemViewModel.self)
        
        let loadTrigger = PublishSubject<Void>()
        let output = sut.transform(input: .init(loadTrigger: loadTrigger.asObservable()))
        
        output.detail.subscribe(detaiObserver).disposed(by: disposeBag)
        
        loadTrigger.onNext(())
        try? await Task.sleep(nanoseconds: 50_000_000)
        
        let details = detaiObserver.events.compactMap { $0.value.element }
        let expectedDetail = StockDetailItemViewModel(profile: profile, quote: quote)
        
        XCTAssertEqual(details, [expectedDetail])
    }
    
    func test_loadTrigger_managesLoadingStateCorrectly() async {
        let (sut, _) = makeSUT()
        let scheduler = TestScheduler(initialClock: 0)
        let disposeBag = DisposeBag()
        
        let loadingObserver = scheduler.createObserver(Bool.self)
        let refreshingObserver = scheduler.createObserver(Bool.self)
        
        let loadTrigger = PublishSubject<Void>()
        let output = sut.transform(input: .init(loadTrigger: loadTrigger.asObservable()))
        
        output.isLoading.subscribe(loadingObserver).disposed(by: disposeBag)
        output.isRefreshing.subscribe(refreshingObserver).disposed(by: disposeBag)
        
        loadTrigger.onNext(())
        try? await Task.sleep(nanoseconds: 50_000_000)
        
        let loadingValues = loadingObserver.events.compactMap { $0.value.element }
        let refreshingValues = refreshingObserver.events.compactMap { $0.value.element }
        
        XCTAssertEqual(loadingValues, [false, true, false])
        XCTAssertEqual(refreshingValues, [false])
    }
    
    func test_refreshTrigger_managesRefreshingStateCorrectly() async {
        let (sut, _) = makeSUT()
        let scheduler = TestScheduler(initialClock: 0)
        let disposeBag = DisposeBag()
        
        let refreshingObserver = scheduler.createObserver(Bool.self)
        let loadingObserver = scheduler.createObserver(Bool.self)
        
        let refreshTrigger = PublishSubject<Void>()
        let output = sut.transform(input: .init(loadTrigger: .empty(), refreshTrigger: refreshTrigger.asObservable()))
        
        output.isRefreshing.subscribe(refreshingObserver).disposed(by: disposeBag)
        output.isLoading.subscribe(loadingObserver).disposed(by: disposeBag)
        
        refreshTrigger.onNext(())
        try? await Task.sleep(nanoseconds: 50_000_000)
        
        let refreshingValues = refreshingObserver.events.compactMap { $0.value.element }
        let loadingValues = loadingObserver.events.compactMap { $0.value.element }
        
        XCTAssertEqual(refreshingValues, [false, true, false])
        XCTAssertEqual(loadingValues, [false])
    }
    
    func test_loadTrigger_deliversErrorAndResetsLoadingOnProfileFailure() async {
        let (sut, loader) = makeSUT()
        loader.stubProfile(with: .failure(anyNSError()))
        
        let scheduler = TestScheduler(initialClock: 0)
        let disposeBag = DisposeBag()
        
        let errorObserver = scheduler.createObserver(String.self)
        let loadingObserver = scheduler.createObserver(Bool.self)
        
        let loadTrigger = PublishSubject<Void>()
        let output = sut.transform(input: .init(loadTrigger: loadTrigger.asObservable()))
        
        output.errorMessage.subscribe(errorObserver).disposed(by: disposeBag)
        output.isLoading.subscribe(loadingObserver).disposed(by: disposeBag)
        
        loadTrigger.onNext(())
        try? await Task.sleep(nanoseconds: 50_000_000)
        
        let errorMessages = errorObserver.events.compactMap { $0.value.element }
        let loadingValues = loadingObserver.events.compactMap { $0.value.element }
        
        XCTAssertEqual(errorMessages, ["Failed to load stock details. Pull to refresh."])
        XCTAssertEqual(loadingValues, [false, true, false])
    }
    
    func test_refreshTrigger_deliversErrorAndResetsRefreshingOnQuoteFailure() async {
        let (sut, loader) = makeSUT()
        loader.stubQuote(with: .failure(anyNSError()))
        
        let scheduler = TestScheduler(initialClock: 0)
        let disposeBag = DisposeBag()
        
        let errorObserver = scheduler.createObserver(String.self)
        let refreshingObserver = scheduler.createObserver(Bool.self)
        
        let refreshTrigger = PublishSubject<Void>()
        let output = sut.transform(input: .init(loadTrigger: .empty(), refreshTrigger: refreshTrigger.asObservable()))
        
        output.errorMessage.subscribe(errorObserver).disposed(by: disposeBag)
        output.isRefreshing.subscribe(refreshingObserver).disposed(by: disposeBag)
        
        refreshTrigger.onNext(())
        try? await Task.sleep(nanoseconds: 50_000_000)
        
        let errorMessages = errorObserver.events.compactMap { $0.value.element }
        let refreshingValues = refreshingObserver.events.compactMap { $0.value.element }
        
        XCTAssertEqual(errorMessages, ["Failed to load stock details. Pull to refresh."])
        XCTAssertEqual(refreshingValues, [false, true, false])
    }
    
    func test_stockDetailItemViewModel_formatsValuesCorrectly() {
        let profile = makeProfile(symbol: "AAPL", name: "Apple Inc.")
        let quote = StockQuoteModel(
            symbol: "AAPL",
            currentPrice: 150.25,
            change: 2.50,
            percentChange: 1.25,
            highPrice: 152.00,
            lowPrice: 149.00,
            openPrice: 149.50,
            previousClose: 147.75,
            timestamp: Date()
        )
        
        let vm = StockDetailItemViewModel(profile: profile, quote: quote)
        
        XCTAssertEqual(vm.formattedPrice, "$150.25")
        XCTAssertEqual(vm.formattedChange, "+2.50 (+1.25%)")
        XCTAssertTrue(vm.isPositive)
        XCTAssertEqual(vm.formattedHigh, "$152.00")
        XCTAssertEqual(vm.formattedLow, "$149.00")
        XCTAssertEqual(vm.formattedOpen, "$149.50")
        XCTAssertEqual(vm.formattedPrevClose, "$147.75")
    }
    
    // MARK: - Helpers & Fixtures
    
    private func makeSUT(
        symbol: String = "AAPL",
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: StockDetailViewModel, loader: StockDetailLoaderSpy) {
        let loader = StockDetailLoaderSpy()
        let sut = StockDetailViewModel(symbol: symbol, loader: loader)
        trackForMemoryLeaks(loader, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, loader)
    }
    
    private func makeProfile(
        symbol: String = "AAPL",
        name: String = "Apple Inc."
    ) -> CompanyProfileModel {
        CompanyProfileModel(
            symbol: symbol,
            name: name,
            logoURL: URL(string: "https://logo.com"),
            industry: "Technology",
            currency: "USD",
            exchange: "NASDAQ"
        )
    }
    
    private func makeQuote(
        symbol: String = "AAPL",
        price: Double = 150.0,
        change: Double = 2.5,
        percentChange: Double = 1.69
    ) -> StockQuoteModel {
        StockQuoteModel(
            symbol: symbol,
            currentPrice: price,
            change: change,
            percentChange: percentChange,
            highPrice: price + 5,
            lowPrice: price - 5,
            openPrice: price - 1,
            previousClose: price - change,
            timestamp: Date()
        )
    }
    
    // MARK: - Test Double (Spy)
    
    private final class StockDetailLoaderSpy: StockDetailLoader, @unchecked Sendable {
        private(set) var loadProfileCallCount = 0
        private(set) var receivedProfileSymbols = [String]()
        private(set) var loadQuoteCallCount = 0
        private(set) var receivedQuoteSymbols = [String]()
        
        private var profileResult: Result<CompanyProfileModel, Error> = .success(
            CompanyProfileModel(symbol: "AAPL", name: "Apple", logoURL: nil, industry: "Tech", currency: "USD", exchange: "NASDAQ")
        )
        private var quoteResult: Result<StockQuoteModel, Error> = .success(
            StockQuoteModel(symbol: "AAPL", currentPrice: 100, change: 0, percentChange: 0, highPrice: 100, lowPrice: 100, openPrice: 100, previousClose: 100, timestamp: Date())
        )
        
        func stubProfile(with result: Result<CompanyProfileModel, Error>) {
            self.profileResult = result
        }
        
        func stubQuote(with result: Result<StockQuoteModel, Error>) {
            self.quoteResult = result
        }
        
        func loadProfile(symbol: String) async throws -> CompanyProfileModel {
            loadProfileCallCount += 1
            receivedProfileSymbols.append(symbol)
            return try profileResult.get()
        }
        
        func loadQuote(symbol: String) async throws -> StockQuoteModel {
            loadQuoteCallCount += 1
            receivedQuoteSymbols.append(symbol)
            return try quoteResult.get()
        }
    }
}
