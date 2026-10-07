//
//  StockSearchViewModel.swift
//  MarketApp
//
//  Created by Amin faruq on 07/10/26.
//

import RxSwift
import Foundation
import MarketCore

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
        
        public init(items: Observable<[SearchResultItemViewModel]>) {
            self.items = items
        }
    }
    
    private let loader: StockSearchLoader
    
    public init(loader: StockSearchLoader) {
        self.loader = loader
    }
    
    public func transform(input: Input) -> Output {
        let items = input.searchTrigger
            .flatMapLatest { [loader] query -> Observable<[SearchResultItemViewModel]> in
                Task {
                    _ = try? await loader.search(query: query)
                }
                return .just([])
            }
        
        return Output(items: items)
    }
    
}
