//
//  StockSearchViewModelTests.swift
//  MarketApp
//
//  Created by Amin faruq on 07/10/26.
//

import XCTest
import RxSwift
import RxTest
import MarketCore
import MarketPresentation

final class StockSearchViewModelTests: XCTestCase {
    
    func test_init_doesNotRequestSearchFromLoader() {
        let (_, loader) = makeSUT()
        
        XCTAssertTrue(loader.receivedQueries.isEmpty)
    }
    
    func test_search_requestSearchFromLoader() async {
        let (sut, loader) = makeSUT()
        let scheduler = TestScheduler(initialClock: 0)
        let disposeBag = DisposeBag()
        let itemsObserver = scheduler.createObserver([SearchResultItemViewModel].self)
        
        let searchTrigger = PublishSubject<String>()
        let output = sut.transform(input: .init(searchTrigger: searchTrigger.asObservable()))
        
        output.items.subscribe(itemsObserver).disposed(by: disposeBag)
        
        searchTrigger.onNext("AAPL")
        try? await Task.sleep(nanoseconds: 50_000_000)
        
        XCTAssertEqual(loader.receivedQueries, ["AAPL"])
    }
    
    func test_search_deliversSearchResultsOnLoaderSuccess() async {
        let (sut, loader) = makeSUT()
        let stock = makeStock(symbol: "AAPL", companyName: "Apple Inc")
        loader.stub(with: .success([stock.model]))
       
        let scheduler = TestScheduler(initialClock: 0)
        let disposeBag = DisposeBag()
        let itemsObserver = scheduler.createObserver([SearchResultItemViewModel].self)
        
        let searchTrigger = PublishSubject<String>()
        let output = sut.transform(input: .init(searchTrigger: searchTrigger.asObservable()))
        
        output.items.subscribe(itemsObserver).disposed(by: disposeBag)
        
        searchTrigger.onNext("AAPL")
        try? await Task.sleep(nanoseconds: 50_000_000)
        
        let items = itemsObserver.events.compactMap { $0.value.element }
        XCTAssertEqual(items, [[stock.viewModel]])
    }
    
    func test_search_withEmptyOrWhitespaceQuery_doesNotCallLoaderAndClearsItems() async {
        let (sut, loader) = makeSUT()
        let scheduler = TestScheduler(initialClock: 0)
        let disposeBag = DisposeBag()
        
        let itemsObserver = scheduler.createObserver([SearchResultItemViewModel].self)
        
        let searchTrigger = PublishSubject<String>()
        let output = sut.transform(input: .init(searchTrigger: searchTrigger.asObservable()))
        
        output.items.subscribe(itemsObserver).disposed(by: disposeBag)
        
        searchTrigger.onNext("  ")
        
        XCTAssertTrue(loader.receivedQueries.isEmpty, "Loader Shouldn't called when query is empty or space")
        XCTAssertEqual(itemsObserver.events, [
            .next(0, [])
        ])
    }
    
    func test_search_deliversLoadingState() async {
        let (sut, _) = makeSUT()
        let scheduler = TestScheduler(initialClock: 0)
        let disposeBag = DisposeBag()
        
        let loadingObserver = scheduler.createObserver(Bool.self)
        
        let searchTrigger = PublishSubject<String>()
        let output = sut.transform(input: .init(searchTrigger: searchTrigger.asObservable()))
        
        output.isLoading.subscribe(loadingObserver).disposed(by: disposeBag)
        output.items.subscribe().disposed(by: disposeBag)
        
        searchTrigger.onNext("AAPL")
        
        try? await Task.sleep(nanoseconds: 50_000_000)
        
        let values = loadingObserver.events.compactMap { $0.value.element }
        
        XCTAssertEqual(values, [false, true, false])
    }
    
    func test_search_deliversErrorMessageOnLoaderFailure() async {
        let (sut, loader) = makeSUT()
        loader.stub(with: .failure(anyNSError()))
        
        let scheduler = TestScheduler(initialClock: 0)
        let disposeBag = DisposeBag()
        
        let errorObserver = scheduler.createObserver(String.self)
        
        let searchTrigger = PublishSubject<String>()
        let output = sut.transform(input: .init(searchTrigger: searchTrigger.asObservable()))
        
        output.errorMessage.subscribe(errorObserver).disposed(by: disposeBag)
        output.items.subscribe().disposed(by: disposeBag)
        
        searchTrigger.onNext("AAPL")
        
        try? await Task.sleep(nanoseconds: 50_000_000)
        
        let errors = errorObserver.events.compactMap { $0.value.element }
        
        XCTAssertEqual(errors, ["Failed to search. Try again later."])
    }
    
    func test_search_doesNotRequestSearchOnDuplicateQuery() async {
        let (sut, loader) = makeSUT()
        let scheduler = TestScheduler(initialClock: 0)
        let disposeBag = DisposeBag()
        
        let itemsObserver = scheduler.createObserver([SearchResultItemViewModel].self)
        
        let searchTrigger = PublishSubject<String>()
        let output = sut.transform(input: .init(searchTrigger: searchTrigger.asObservable()))
        
        output.items.subscribe(itemsObserver).disposed(by: disposeBag)
        
        searchTrigger.onNext("AAPL")
        try? await Task.sleep(nanoseconds: 50_000_000)
        
        searchTrigger.onNext("AAPL")
        try? await Task.sleep(nanoseconds: 50_000_000)
        
        XCTAssertEqual(loader.receivedQueries, ["AAPL"])
    }
    
    // MARK: - Helpers
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (sut: StockSearchViewModel, loader: StockSearchLoaderSpy) {
        let loader = StockSearchLoaderSpy()
        let sut = StockSearchViewModel(loader: loader)
        trackForMemoryLeaks(loader, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, loader)
    }
    
    private func makeStock(
        symbol: String = "AAPL",
        companyName: String = "Apple Inc",
        type: String = "Common Stock"
    ) -> (model: SearchResultModel, viewModel: SearchResultItemViewModel) {
        let model = SearchResultModel(
            symbol: symbol,
            description: companyName,
            displaySymbol: symbol,
            type: type
        )
        let viewModel = SearchResultItemViewModel(
            symbol: symbol,
            companyName: companyName,
            type: type
        )
        return (model, viewModel)
    }
    
    private class StockSearchLoaderSpy: StockSearchLoader {
        private(set) var receivedQueries = [String]()
        private var result: Result<[SearchResultModel], Error> = .success([])
        
        func stub(with result: Result<[SearchResultModel], Error>) {
            self.result = result
        }
        
        func search(query: String) async throws -> [SearchResultModel] {
            receivedQueries.append(query)
            return try result.get()
        }
    }
}
