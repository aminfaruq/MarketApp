//
//  StockSearchViewModelTests.swift
//  MarketApp
//
//  Created by Amin faruq on 07/10/26.
//

import XCTest
import RxSwift
import MarketCore
import MarketPresentation

final class StockSearchViewModelTests: XCTestCase {
    
    func test_init_doesNotRequestSearchFromLoader() {
        let (_, loader) = makeSUT()
        
        XCTAssertTrue(loader.receivedQueries.isEmpty)
    }
    
    func test_search_requestSearchFromLoader() async {
        let (sut, loader) = makeSUT()
        let searchTrigger = PublishSubject<String>()
        let output = sut.transform(input: .init(searchTrigger: searchTrigger.asObservable()))
        
        let disposeBag = DisposeBag()
        let exp = expectation(description: "Wait from loader completion")
        output.items.subscribe(onNext: { _ in
            exp.fulfill()
        })
        .disposed(by: disposeBag)
        
        searchTrigger.onNext("AAPL")
        await fulfillment(of: [exp], timeout: 1.0)
        
        XCTAssertEqual(loader.receivedQueries, ["AAPL"])
    }
    
    func test_search_deliversSearchResultsOnLoaderSuccess() async {
        let (sut, loader) = makeSUT()
        let stock = makeStock(symbol: "AAPL", companyName: "Apple Inc")
        loader.stub(with: .success([stock.model]))
        
        let searchTrigger = PublishSubject<String>()
        let output = sut.transform(input: .init(searchTrigger: searchTrigger.asObservable()))
        
        var receivedItems = [[SearchResultItemViewModel]]()
        let disposeBag = DisposeBag()
        
        let exp = expectation(description: "Wait from output")
        output.items
            .subscribe(onNext: { items in
                receivedItems.append(items)
                exp.fulfill()
            })
            .disposed(by: disposeBag)
        
        searchTrigger.onNext("AAPL")
        await fulfillment(of: [exp], timeout: 1.0)
        
        XCTAssertEqual(receivedItems, [[stock.viewModel]])
    }
    
    func test_search_withEmptyOrWhitespaceQuery_doesNotCallLoaderAndClearsItems() async {
        let (sut, loader) = makeSUT()
        let searchTrigger = PublishSubject<String>()
        let output = sut.transform(input: .init(searchTrigger: searchTrigger.asObserver()))
        
        var receivedItems = [[SearchResultItemViewModel]]()
        let disposeBag = DisposeBag()
        let exp = expectation(description: "Wait output to remove list")
        
        output.items
            .subscribe(onNext: { items in
                receivedItems.append(items)
                exp.fulfill()
            })
            .disposed(by: disposeBag)
        
        searchTrigger.onNext("  ")
        await fulfillment(of: [exp], timeout: 1.0)
        
        XCTAssertTrue(loader.receivedQueries.isEmpty, "Loader Shouldn't called when query is empty or space")
          XCTAssertEqual(receivedItems, [[]], "Should returnd empty array")
    }
    
    func test_search_deliversLoadingState() async {
        let (sut, _) = makeSUT()
        let searchTrigger = PublishSubject<String>()
        let output = sut.transform(input: .init(searchTrigger: searchTrigger.asObservable()))
        
        var receivedLoadingStates = [Bool]()
        let disposeBag = DisposeBag()
        let exp = expectation(description: "Wait for loading")
        
        output.isLoading
            .subscribe(onNext: { isLoading in
                receivedLoadingStates.append(isLoading)
                
                if !isLoading && receivedLoadingStates.count == 3 {
                    exp.fulfill()
                }
            })
            .disposed(by: disposeBag)
        
        output.items.subscribe().disposed(by: disposeBag)
        
        searchTrigger.onNext("AAPL")
        await fulfillment(of: [exp], timeout: 1.0)
        
        XCTAssertEqual(receivedLoadingStates, [false, true, false])
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
