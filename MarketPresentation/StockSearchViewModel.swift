//
//  StockSearchViewModel.swift
//  MarketApp
//
//  Created by Amin faruq on 07/10/26.
//

import RxSwift
import Foundation
import MarketCore
import RxRelay

public struct SearchResultItemViewModel: Equatable {
    public let symbol: String
    public let companyName: String
    public let type: String
    
    public init(symbol: String, companyName: String, type: String) {
        self.symbol = symbol
        self.companyName = companyName
        self.type = type
    }
}

public final class StockSearchViewModel: ViewModelType {
     
    public struct Input {
        public let searchTrigger: Observable<String>
        
        public init(searchTrigger: Observable<String>) {
            self.searchTrigger = searchTrigger
        }
    }
    
    public struct Output {
        public let items: Observable<[SearchResultItemViewModel]>
        public let isLoading: Observable<Bool>
        public let errorMessage: Observable<String>
        
        public init(
            items: Observable<[SearchResultItemViewModel]>,
            isLoading: Observable<Bool>,
            errorMessage: Observable<String>
        ) {
            self.items = items
            self.isLoading = isLoading
            self.errorMessage = errorMessage
        }
    }
    
    private let loader: StockSearchLoader
    
    public init(loader: StockSearchLoader) {
        self.loader = loader
    }
    
    public func transform(input: Input) -> Output {
        let isLoadingRelay = BehaviorRelay<Bool>(value: false)
        let errorRelay = PublishRelay<String>()
        
        let items = input.searchTrigger
            .flatMapLatest { [loader] query -> Observable<[SearchResultItemViewModel]> in
                
                let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
                
                guard !trimmed.isEmpty else {
                    return .just([])
                }
                
                isLoadingRelay.accept(true)
                
                return Observable.create { observer in
                    let task = Task {
                        do {
                            let models = try await loader.search(query: query)
                            let viewModels = models.map {
                                SearchResultItemViewModel(
                                    symbol: $0.symbol,
                                    companyName: $0.description,
                                    type: $0.type
                                )
                            }
                            
                            isLoadingRelay.accept(false)
                            observer.onNext(viewModels)
                            observer.onCompleted()
                        } catch {
                            errorRelay.accept("Failed to search. Try again later.")
                            isLoadingRelay.accept(false)
                            observer.onNext([])
                            observer.onCompleted()
                        }
                    }
                    
                    return Disposables.create {
                        task.cancel()
                    }
                }
            }
        
        return Output(
            items: items,
            isLoading: isLoadingRelay.asObservable(),
            errorMessage: errorRelay.asObservable()
        )
    }
    
}
