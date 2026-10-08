//
//  StockDetailViewModel.swift
//  MarketApp
//
//  Created by Amin faruq on 08/10/26.
//

import MarketCore
import Foundation
import RxSwift
import RxRelay

public struct StockDetailItemViewModel: Equatable, Sendable {
    public let symbol: String
    public let companyName: String
    public let logoURL: URL?
    public let industry: String
    public let exchange: String
    
    public let formattedPrice: String
    public let formattedChange: String
    public let isPositive: Bool
    
    public let formattedHigh: String
    public let formattedLow: String
    public let formattedOpen: String
    public let formattedPrevClose: String
    
    public init(
        symbol: String,
        companyName: String,
        logoURL: URL?,
        industry: String,
        exchange: String,
        formattedPrice: String,
        formattedChange: String,
        isPositive: Bool,
        formattedHigh: String,
        formattedLow: String,
        formattedOpen: String,
        formattedPrevClose: String
    ) {
        self.symbol = symbol
        self.companyName = companyName
        self.logoURL = logoURL
        self.industry = industry
        self.exchange = exchange
        self.formattedPrice = formattedPrice
        self.formattedChange = formattedChange
        self.isPositive = isPositive
        self.formattedHigh = formattedHigh
        self.formattedLow = formattedLow
        self.formattedOpen = formattedOpen
        self.formattedPrevClose = formattedPrevClose
    }
    
    public init(profile: CompanyProfileModel, quote: StockQuoteModel) {
        self.symbol = profile.symbol
        self.companyName = profile.name
        self.logoURL = profile.logoURL
        self.industry = profile.industry
        self.exchange = profile.exchange
        self.formattedPrice = String(format: "$%.2f", quote.currentPrice)
        
        let changeSign = quote.change >= 0 ? "+" : ""
        let percentSign = quote.percentChange >= 0 ? "+" : ""
        self.formattedChange = String(
            format: "%@%.2f (%@%.2f%%)",
            changeSign, quote.change,
            percentSign, quote.percentChange
        )
        self.isPositive = quote.change >= 0
        
        self.formattedHigh = String(format: "$%.2f", quote.highPrice)
        self.formattedLow = String(format: "$%.2f", quote.lowPrice)
        self.formattedOpen = String(format: "$%.2f", quote.openPrice)
        self.formattedPrevClose = String(format: "$%.2f", quote.previousClose)
    }
}

public final class StockDetailViewModel: ViewModelType {
    
    public struct Input {
        public let loadTrigger: Observable<Void>
        public let refreshTrigger: Observable<Void>
        
        public init(
            loadTrigger: Observable<Void>,
            refreshTrigger: Observable<Void> = .empty()
        ) {
            self.loadTrigger = loadTrigger
            self.refreshTrigger = refreshTrigger
        }
        
    }
    
    public struct Output {
        public let detail: Observable<StockDetailItemViewModel>
        public let isLoading: Observable<Bool>
        public let isRefreshing: Observable<Bool>
        public let errorMessage: Observable<String>
        
        public init(
            detail: Observable<StockDetailItemViewModel>,
            isLoading: Observable<Bool>,
            isRefreshing: Observable<Bool>,
            errorMessage: Observable<String>
        ) {
            self.detail = detail
            self.isLoading = isLoading
            self.isRefreshing = isRefreshing
            self.errorMessage = errorMessage
        }
    }
    
    private let symbol: String
    private let loader: StockDetailLoader
    private let disposeBag = DisposeBag()
    
    public init(symbol: String, loader: StockDetailLoader) {
        self.symbol = symbol
        self.loader = loader
    }
    
    public func transform(input: Input) -> Output {
        let detailRelay = PublishRelay<StockDetailItemViewModel>()
        let isLoadingRelay = BehaviorRelay<Bool>(value: false)
        let isRefreshingRelay = BehaviorRelay<Bool>(value: false)
        let errorRelay = PublishRelay<String>()
        
        Observable.merge(
            input.loadTrigger.map { false },
            input.refreshTrigger.map { true }
        )
        .flatMapLatest { [symbol, loader] isRefresh -> Observable<(CompanyProfileModel, StockQuoteModel)> in
            if isRefresh {
                isRefreshingRelay.accept(true)
            } else {
                isLoadingRelay.accept(true)
            }
            
            return Observable.create { observer in
                
                let task = Task {
                    do {
                        async let profileTask = loader.loadProfile(symbol: symbol)
                        async let qouteTask = loader.loadQuote(symbol: symbol)
                        
                        let result = try await (profileTask, qouteTask)
                        observer.onNext(result)
                        observer.onCompleted()
                    } catch {
                        observer.onError(error)
                    }
                }
                
                return Disposables.create {
                    task.cancel()
                }
            }
            .do(
                onNext: { _ in
                    if isRefresh { isRefreshingRelay.accept(false) }
                    else { isLoadingRelay.accept(false) }
                },
                onError: { _ in
                    errorRelay.accept("Failed to load stock details. Pull to refresh.")
                    if isRefresh { isRefreshingRelay.accept(false) }
                    else { isLoadingRelay.accept(false) }
                }
            )
            .catch { _ in .empty() }
        }
        .subscribe(onNext: { profile, quote in
            let item = StockDetailItemViewModel(profile: profile, quote: quote)
            detailRelay.accept(item)
        })
        .disposed(by: disposeBag)
        
        return Output(
            detail: detailRelay.asObservable(),
            isLoading: isLoadingRelay.asObservable(),
            isRefreshing: isRefreshingRelay.asObservable(),
            errorMessage: errorRelay.asObservable()
        )
    }
}
