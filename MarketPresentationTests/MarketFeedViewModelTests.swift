//
//  MarketFeedViewModelTests.swift
//  MarketApp
//
//  Created by Amin faruq on 08/10/26.
//

import XCTest
import RxTest
import RxSwift
import MarketCore
import MarketPresentation

final class MarketFeedViewModelTests: XCTestCase {
    
    func test_init_doesNotCallLoader() {
        let (_, loader) = makeSUT()
        
        XCTAssertEqual(loader.loadQuotesCallCount, 0)
        XCTAssertEqual(loader.loadNewsCallCount, 0)
    }
    
    func test_loadTrigger_requestsDataFromLoaderWithConfiguredSymbols() async {
        let symbols = ["AAPL", "GOOGL"]
        let (sut, loader) = makeSUT(symbols: symbols)
        let scheduler = TestScheduler(initialClock: 0)
        let disposeBag = DisposeBag()
        
        let quotesObserver = scheduler.createObserver([StockQuoteItemViewModel].self)
        
        let loadTrigger = PublishSubject<Void>()
        let output = sut.transform(input: .init(loadTrigger: loadTrigger.asObservable()))
        
        output.quotes.subscribe(quotesObserver).disposed(by: disposeBag)
        
        loadTrigger.onNext(())
        try? await Task.sleep(nanoseconds: 50_000_000)
        
        XCTAssertEqual(loader.receivedSymbols, [symbols])
        XCTAssertEqual(loader.loadNewsCallCount, 1)
    }
    
    func test_loadTrigger_deliversQuotesAndNewsOnSuccess() async {
        let (sut, loader) = makeSUT()
        let quote = makeQuote(symbol: "AAPL", currentPrice: 150.0, change: 2.5, percentChange: 1.69)
        let news = makeNews(id: 1, headline: "Tech stocks rally")
        
        loader.stubQuotes(with: .success([quote.model]))
        loader.stubNews(with: .success([news.model]))
        
        let scheduler = TestScheduler(initialClock: 0)
        let disposeBag = DisposeBag()
        
        let quotesObserver = scheduler.createObserver([StockQuoteItemViewModel].self)
        let newsObserver = scheduler.createObserver([MarketNewsItemViewModel].self)
        
        let loadTrigger = PublishSubject<Void>()
        let output = sut.transform(input: .init(loadTrigger: loadTrigger.asObservable()))
        
        output.quotes.subscribe(quotesObserver).disposed(by: disposeBag)
        output.news.subscribe(newsObserver).disposed(by: disposeBag)
        
        loadTrigger.onNext(())
        try? await Task.sleep(nanoseconds: 50_000_000)
        
        let receivedQuotes = quotesObserver.events.compactMap { $0.value.element }
        let receivedNews = newsObserver.events.compactMap { $0.value.element }
        
        XCTAssertEqual(receivedQuotes, [[quote.viewModel]])
        XCTAssertEqual(receivedNews, [[news.viewModel]])
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
    
    func test_loadTrigger_deliversErrorAndResetsLoadingOnLoaderFailure() async {
        let (sut, loader) = makeSUT()
        loader.stubQuotes(with: .failure(anyNSError()))
        
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
        
        XCTAssertEqual(errorMessages, ["Failed to load market feed. Pull to refresh."])
        XCTAssertEqual(loadingValues, [false, true, false])
    }
    
    func test_refreshTrigger_deliversErrorAndResetsRefreshingOnLoaderFailure() async {
        let (sut, loader) = makeSUT()
        loader.stubNews(with: .failure(anyNSError()))
        
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
        
        XCTAssertEqual(errorMessages, ["Failed to load market feed. Pull to refresh."])
        XCTAssertEqual(refreshingValues, [false, true, false])
    }
    
    func test_stockQuoteItemViewModel_formatsValuesCorrectly() {
        let positiveModel = StockQuoteModel(
            symbol: "AAPL",
            currentPrice: 150.25,
            change: 2.50,
            percentChange: 1.25,
            highPrice: 152.0,
            lowPrice: 149.0,
            openPrice: 149.5,
            previousClose: 147.75,
            timestamp: Date()
        )
        let positiveVM = StockQuoteItemViewModel(model: positiveModel)
        XCTAssertEqual(positiveVM.symbol, "AAPL")
        XCTAssertEqual(positiveVM.formattedPrice, "$150.25")
        XCTAssertEqual(positiveVM.formattedChange, "+2.50 (+1.25%)")
        XCTAssertTrue(positiveVM.isPositive)
        
        let negativeModel = StockQuoteModel(
            symbol: "TSLA",
            currentPrice: 180.50,
            change: -3.20,
            percentChange: -1.74,
            highPrice: 185.0,
            lowPrice: 179.0,
            openPrice: 184.0,
            previousClose: 183.70,
            timestamp: Date()
        )
        let negativeVM = StockQuoteItemViewModel(model: negativeModel)
        XCTAssertEqual(negativeVM.symbol, "TSLA")
        XCTAssertEqual(negativeVM.formattedPrice, "$180.50")
        XCTAssertEqual(negativeVM.formattedChange, "-3.20 (-1.74%)")
        XCTAssertFalse(negativeVM.isPositive)
    }
    
    func test_newsItemViewModel_mapsModelPropertiesCorrectly() {
        let now = Date()
        let imageURL = URL(string: "https://image.com/pic.png")
        let newsURL = URL(string: "https://news.com/article")
        
        let model = MarketNewsModel(
            id: 42,
            headline: "Market Update",
            summary: "Stocks were up today",
            source: "Bloomberg",
            imageURL: imageURL,
            newsURL: newsURL,
            publishedAt: now
        )
        
        let viewModel = MarketNewsItemViewModel(model: model)
        XCTAssertEqual(viewModel.id, 42)
        XCTAssertEqual(viewModel.headline, "Market Update")
        XCTAssertEqual(viewModel.summary, "Stocks were up today")
        XCTAssertEqual(viewModel.source, "Bloomberg")
        XCTAssertEqual(viewModel.imageURL, imageURL)
        XCTAssertEqual(viewModel.newsURL, newsURL)
        XCTAssertEqual(viewModel.publishedAt, now)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(
        symbols: [String] = ["AAPL", "TSLA"],
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: MarketFeedViewModel, loader: MarketFeedLoaderSpy) {
        let loader = MarketFeedLoaderSpy()
        let sut = MarketFeedViewModel(loader: loader, symbols: symbols)
        trackForMemoryLeaks(loader, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, loader)
    }
    
    private func makeQuote(
        symbol: String = "AAPL",
        currentPrice: Double = 150.0,
        change: Double = 2.5,
        percentChange: Double = 1.69
    ) -> (model: StockQuoteModel, viewModel: StockQuoteItemViewModel) {
        let model = StockQuoteModel(
            symbol: symbol,
            currentPrice: currentPrice,
            change: change,
            percentChange: percentChange,
            highPrice: currentPrice + 5,
            lowPrice: currentPrice - 5,
            openPrice: currentPrice - 1,
            previousClose: currentPrice - change,
            timestamp: Date()
        )
        let viewModel = StockQuoteItemViewModel(model: model)
        return (model, viewModel)
    }
    
    private func makeNews(
        id: Int = 1,
        headline: String = "Headline",
        summary: String = "Summary",
        source: String = "Reuters"
    ) -> (model: MarketNewsModel, viewModel: MarketNewsItemViewModel) {
        let model = MarketNewsModel(
            id: id,
            headline: headline,
            summary: summary,
            source: source,
            imageURL: nil,
            newsURL: nil,
            publishedAt: Date()
        )
        let viewModel = MarketNewsItemViewModel(model: model)
        return (model, viewModel)
    }
    
    private final class MarketFeedLoaderSpy: MarketFeedLoader, @unchecked Sendable {
        private(set) var loadQuotesCallCount = 0
        private(set) var receivedSymbols = [[String]]()
        private(set) var loadNewsCallCount = 0
        
        private var quotesResult: Result<[StockQuoteModel], Error> = .success([])
        private var newsResult: Result<[MarketNewsModel], Error> = .success([])
        
        func stubQuotes(with result: Result<[StockQuoteModel], Error>) {
            self.quotesResult = result
        }
        
        func stubNews(with result: Result<[MarketNewsModel], Error>) {
            self.newsResult = result
        }
        
        func loadQuotes(symbols: [String]) async throws -> [StockQuoteModel] {
            loadQuotesCallCount += 1
            receivedSymbols.append(symbols)
            return try quotesResult.get()
        }
        
        func loadMarketNews() async throws -> [MarketNewsModel] {
            loadNewsCallCount += 1
            return try newsResult.get()
        }
    }
}
