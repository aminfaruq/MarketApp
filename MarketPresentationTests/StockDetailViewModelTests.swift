//
//  StockDetailViewModelTests.swift
//  MarketApp
//
//  Created by Amin faruq on 08/10/26.
//

import XCTest
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
        let loadTrigger = PublishSubject<Void>()
        let output = sut.transform(input: .init(loadTrigger: loadTrigger.asObservable()))
        
        let disposeBag = DisposeBag()
        let exp = expectation(description: "Wait for detail load")
        
        output.detail.subscribe(onNext: { _ in
            exp.fulfill()
        }).disposed(by: disposeBag)
        
        loadTrigger.onNext(())
        await fulfillment(of: [exp], timeout: 1.0)
        
        XCTAssertEqual(loader.receivedProfileSymbols, [symbol])
        XCTAssertEqual(loader.receivedQuoteSymbols, [symbol])
    }
    
    func test_loadTrigger_deliversStockDetailOnSuccess() async {
        let (sut, loader) = makeSUT(symbol: "AAPL")
        let profile = makeProfile(symbol: "AAPL", name: "Apple Inc.")
        let quote = makeQuote(symbol: "AAPL", price: 150.25, change: 2.50, percentChange: 1.25)
        
        loader.stubProfile(with: .success(profile))
        loader.stubQuote(with: .success(quote))
        
        let loadTrigger = PublishSubject<Void>()
        let output = sut.transform(input: .init(loadTrigger: loadTrigger.asObservable()))
        
        var receivedDetails = [StockDetailItemViewModel]()
        let disposeBag = DisposeBag()
        let exp = expectation(description: "Wait for detail output")
        
        output.detail
            .subscribe(onNext: { detail in
                receivedDetails.append(detail)
                exp.fulfill()
            })
            .disposed(by: disposeBag)
        
        loadTrigger.onNext(())
        await fulfillment(of: [exp], timeout: 1.0)
        
        let expectedDetail = StockDetailItemViewModel(profile: profile, quote: quote)
        XCTAssertEqual(receivedDetails, [expectedDetail])
    }
    
    func test_loadTrigger_managesLoadingStateCorrectly() async {
        let (sut, _) = makeSUT()
        let loadTrigger = PublishSubject<Void>()
        let output = sut.transform(input: .init(loadTrigger: loadTrigger.asObservable()))
        
        var loadingStates = [Bool]()
        var refreshingStates = [Bool]()
        let disposeBag = DisposeBag()
        
        let exp = expectation(description: "Wait for loading states")
        output.isLoading
            .subscribe(onNext: { isLoading in
                loadingStates.append(isLoading)
                if loadingStates.count == 3 {
                    exp.fulfill()
                }
            })
            .disposed(by: disposeBag)
        
        output.isRefreshing
            .subscribe(onNext: { isRefreshing in
                refreshingStates.append(isRefreshing)
            })
            .disposed(by: disposeBag)
        
        loadTrigger.onNext(())
        await fulfillment(of: [exp], timeout: 1.0)
        
        XCTAssertEqual(loadingStates, [false, true, false])
        XCTAssertEqual(refreshingStates, [false])
    }
    
    func test_refreshTrigger_managesRefreshingStateCorrectly() async {
        let (sut, _) = makeSUT()
        let refreshTrigger = PublishSubject<Void>()
        let output = sut.transform(input: .init(loadTrigger: .empty(), refreshTrigger: refreshTrigger.asObservable()))
        
        var refreshingStates = [Bool]()
        var loadingStates = [Bool]()
        let disposeBag = DisposeBag()
        
        let exp = expectation(description: "Wait for refreshing states")
        output.isRefreshing
            .subscribe(onNext: { isRefreshing in
                refreshingStates.append(isRefreshing)
                if refreshingStates.count == 3 {
                    exp.fulfill()
                }
            })
            .disposed(by: disposeBag)
        
        output.isLoading
            .subscribe(onNext: { isLoading in
                loadingStates.append(isLoading)
            })
            .disposed(by: disposeBag)
        
        refreshTrigger.onNext(())
        await fulfillment(of: [exp], timeout: 1.0)
        
        XCTAssertEqual(refreshingStates, [false, true, false])
        XCTAssertEqual(loadingStates, [false])
    }
    
    func test_loadTrigger_deliversErrorAndResetsLoadingOnProfileFailure() async {
        let (sut, loader) = makeSUT()
        loader.stubProfile(with: .failure(anyNSError()))
        
        let loadTrigger = PublishSubject<Void>()
        let output = sut.transform(input: .init(loadTrigger: loadTrigger.asObservable()))
        
        var errorMessages = [String]()
        var loadingStates = [Bool]()
        let exp = expectation(description: "Wait for error and loading reset")
        let disposeBag = DisposeBag()
        
        output.errorMessage
            .subscribe(onNext: { message in
                errorMessages.append(message)
            })
            .disposed(by: disposeBag)
        
        output.isLoading
            .subscribe(onNext: { isLoading in
                loadingStates.append(isLoading)
                if loadingStates.count == 3 {
                    exp.fulfill()
                }
            })
            .disposed(by: disposeBag)
        
        loadTrigger.onNext(())
        await fulfillment(of: [exp], timeout: 1.0)
        
        XCTAssertEqual(errorMessages, ["Failed to load stock details. Pull to refresh."])
        XCTAssertEqual(loadingStates, [false, true, false])
    }
    
    func test_refreshTrigger_deliversErrorAndResetsRefreshingOnQuoteFailure() async {
        let (sut, loader) = makeSUT()
        loader.stubQuote(with: .failure(anyNSError()))
        
        let refreshTrigger = PublishSubject<Void>()
        let output = sut.transform(input: .init(loadTrigger: .empty(), refreshTrigger: refreshTrigger.asObservable()))
        
        var errorMessages = [String]()
        var refreshingStates = [Bool]()
        let exp = expectation(description: "Wait for error and refreshing reset")
        let disposeBag = DisposeBag()
        
        output.errorMessage
            .subscribe(onNext: { message in
                errorMessages.append(message)
            })
            .disposed(by: disposeBag)
        
        output.isRefreshing
            .subscribe(onNext: { isRefreshing in
                refreshingStates.append(isRefreshing)
                if refreshingStates.count == 3 {
                    exp.fulfill()
                }
            })
            .disposed(by: disposeBag)
        
        refreshTrigger.onNext(())
        await fulfillment(of: [exp], timeout: 1.0)
        
        XCTAssertEqual(errorMessages, ["Failed to load stock details. Pull to refresh."])
        XCTAssertEqual(refreshingStates, [false, true, false])
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
