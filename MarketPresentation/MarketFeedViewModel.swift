//
//  MarketFeedViewModel.swift
//  MarketApp
//
//  Created by Amin faruq on 08/10/26.
//

import Foundation
import MarketCore
import RxSwift
import RxRelay

public struct StockQuoteItemViewModel: Equatable, Sendable {
    public let symbol: String
    public let currentPrice: Double
    public let formattedPrice: String
    public let change: Double
    public let percentChange: Double
    public let formattedChange: String
    public let isPositive: Bool
    
    public init(
        symbol: String,
        currentPrice: Double,
        formattedPrice: String,
        change: Double,
        percentChange: Double,
        formattedChange: String,
        isPositive: Bool
    ) {
        self.symbol = symbol
        self.currentPrice = currentPrice
        self.formattedPrice = formattedPrice
        self.change = change
        self.percentChange = percentChange
        self.formattedChange = formattedChange
        self.isPositive = isPositive
    }
    
    public init(model: StockQuoteModel) {
        self.symbol = model.symbol
        self.currentPrice = model.currentPrice
        self.formattedPrice = String(format: "$%.2f", model.currentPrice)
        self.change = model.change
        self.percentChange = model.percentChange
        
        let changeSign = model.change >= 0 ? "+" : ""
        let percentSign = model.percentChange >= 0 ? "+" : ""
        self.formattedChange = String(format: "%@%.2f (%@%.2f%%)", changeSign, model.change, percentSign, model.percentChange)
        self.isPositive = model.change >= 0
    }
}

public struct MarketNewsItemViewModel: Equatable, Sendable {
    public let id: Int
    public let headline: String
    public let summary: String
    public let source: String
    public let imageURL: URL?
    public let newsURL: URL?
    public let publishedAt: Date
    
    public init(
        id: Int,
        headline: String,
        summary: String,
        source: String,
        imageURL: URL?,
        newsURL: URL?,
        publishedAt: Date
    ) {
        self.id = id
        self.headline = headline
        self.summary = summary
        self.source = source
        self.imageURL = imageURL
        self.newsURL = newsURL
        self.publishedAt = publishedAt
    }
    
    public init(model: MarketNewsModel) {
        self.init(
            id: model.id,
            headline: model.headline,
            summary: model.summary,
            source: model.source,
            imageURL: model.imageURL,
            newsURL: model.newsURL,
            publishedAt: model.publishedAt
        )
    }
}

public final class MarketFeedViewModel: ViewModelType {
    
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
        public let quotes: Observable<[StockQuoteItemViewModel]>
        public let news: Observable<[MarketNewsItemViewModel]>
        public let feed: Observable<([StockQuoteItemViewModel], [MarketNewsItemViewModel])>
        public let isLoading: Observable<Bool>
        public let isRefreshing: Observable<Bool>
        public let errorMessage: Observable<String>
        
        public init(
            quotes: Observable<[StockQuoteItemViewModel]>,
            news: Observable<[MarketNewsItemViewModel]>,
            feed: Observable<([StockQuoteItemViewModel], [MarketNewsItemViewModel])>,
            isLoading: Observable<Bool>,
            isRefreshing: Observable<Bool>,
            errorMessage: Observable<String>
        ) {
            self.quotes = quotes
            self.news = news
            self.feed = feed
            self.isLoading = isLoading
            self.isRefreshing = isRefreshing
            self.errorMessage = errorMessage
        }
    }
    
    public static let defaultSymbols = ["AAPL", "GOOGL", "MSFT", "AMZN", "TSLA"]
    
    private let loader: MarketFeedLoader
    private let symbols: [String]
    private let disposeBag = DisposeBag()
    
    public init(loader: MarketFeedLoader, symbols: [String] = defaultSymbols) {
        self.loader = loader
        self.symbols = symbols
    }
    
    public func transform(input: Input) -> Output {
        let quotesRelay = PublishRelay<[StockQuoteItemViewModel]>()
        let newsRelay = PublishRelay<[MarketNewsItemViewModel]>()
        let feedRelay = PublishRelay<([StockQuoteItemViewModel], [MarketNewsItemViewModel])>()
        let isLoadingRelay = BehaviorRelay<Bool>(value: false)
        let isRefreshingRelay = BehaviorRelay<Bool>(value: false)
        let errorRelay = PublishRelay<String>()
        
        Observable.merge(
            input.loadTrigger.map { false },
            input.refreshTrigger.map { true }
        )
        .flatMapLatest { [loader, symbols] isRefresh -> Observable<([StockQuoteModel], [MarketNewsModel])> in
            if isRefresh {
                isRefreshingRelay.accept(true)
            } else {
                isLoadingRelay.accept(true)
            }
            
            return Observable.create { observer in
                let task = Task {
                    do {
                        async let quotesTask = (try? await loader.loadQuotes(symbols: symbols)) ?? []
                        async let newsTask = (try? await loader.loadMarketNews()) ?? []
                        
                        let quotes = await quotesTask
                        let news = await newsTask
                        
                        if quotes.isEmpty && news.isEmpty {
                            throw NSError(domain: "MarketFeed", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to load market feed. Pull to refresh."])
                        }
                        
                        guard !Task.isCancelled else { return }
                        observer.onNext((quotes, news))
                        observer.onCompleted()
                    } catch {
                        if !Task.isCancelled && !(error is CancellationError) {
                            observer.onError(error)
                        }
                    }
                }
                
                return Disposables.create {
                    task.cancel()
                }
            }
            .do(
                onNext: { _ in
                    if isRefresh {
                        isRefreshingRelay.accept(false)
                    } else {
                        isLoadingRelay.accept(false)
                    }
                },
                onError: { _ in
                    errorRelay.accept("Failed to load market feed. Pull to refresh.")
                    if isRefresh {
                        isRefreshingRelay.accept(false)
                    } else {
                        isLoadingRelay.accept(false)
                    }
                }
            )
            .catch { _ in .empty() }
        }
        .subscribe(onNext: { quotes, news in
            let quoteVMs = quotes.map(StockQuoteItemViewModel.init)
            let newsVMs = news.map(MarketNewsItemViewModel.init)
            quotesRelay.accept(quoteVMs)
            newsRelay.accept(newsVMs)
            feedRelay.accept((quoteVMs, newsVMs))
        })
        .disposed(by: disposeBag)
        
        return Output(
            quotes: quotesRelay.asObservable(),
            news: newsRelay.asObservable(),
            feed: feedRelay.asObservable(),
            isLoading: isLoadingRelay.asObservable(),
            isRefreshing: isRefreshingRelay.asObservable(),
            errorMessage: errorRelay.asObservable()
        )
    }
}
