//
//  LiveMarketStreamViewModel.swift
//  MarketApp
//
//  Created by Amin faruq on 08/10/26.
//

import Foundation
import MarketCore
import RxSwift
import RxRelay

public enum PriceChangeDirection: Equatable, Sendable {
    case up
    case down
    case same
}

public struct LiveTradeItemViewModel: Equatable, Sendable {
    public let symbol: String
    public let price: Double
    public let formattedPrice: String
    public let volume: Double
    public let timestamp: Date
    public let direction: PriceChangeDirection
    
    public init(
        symbol: String,
        price: Double,
        formattedPrice: String,
        volume: Double,
        timestamp: Date,
        direction: PriceChangeDirection
    ) {
        self.symbol = symbol
        self.price = price
        self.formattedPrice = formattedPrice
        self.volume = volume
        self.timestamp = timestamp
        self.direction = direction
    }
}

public final class LiveMarketStreamViewModel: ViewModelType {
    
    public struct Input {
        public let startStreaming: Observable<Void>
        public let stopStreaming: Observable<Void>
        
        public init(
            startStreaming: Observable<Void>,
            stopStreaming: Observable<Void> = .empty()
        ) {
            self.startStreaming = startStreaming
            self.stopStreaming = stopStreaming
        }
    }
    
    public struct Output {
        public let trade: Observable<LiveTradeItemViewModel>
        public let isConnected: Observable<Bool>
        
        public init(
            trade: Observable<LiveTradeItemViewModel>,
            isConnected: Observable<Bool>
        ) {
            self.trade = trade
            self.isConnected = isConnected
        }
    }
    
    private let service: LiveMarketStreamService
    private let symbol: String
    
    public init(service: LiveMarketStreamService, symbol: String) {
        self.service = service
        self.symbol = symbol
    }
    
    public func transform(input: Input) -> Output {
        let isConnected = Observable.merge(
            input.startStreaming.map { true },
            input.stopStreaming.map { false }
        ).startWith(false)
        
        let trade = input.startStreaming
               .flatMapLatest { [service, symbol] _ -> Observable<LiveTradeItemViewModel> in
                   Observable.create { observer in
                       service.connect()
                       
                       var lastPrice: Double?
                       let task = Task {
                           _ = try? await service.subscribe(to: symbol)
                           
                           for await trade in service.tradeStream {
                               guard !Task.isCancelled else { break }
                               guard trade.symbol == symbol else { continue }
                               
                               let direction: PriceChangeDirection
                               if let previous = lastPrice {
                                   if trade.price > previous {
                                       direction = .up
                                   } else if trade.price < previous {
                                       direction = .down
                                   } else {
                                       direction = .same
                                   }
                               } else {
                                   direction = .same
                               }
                               lastPrice = trade.price
                               
                               let item = LiveTradeItemViewModel(
                                   symbol: trade.symbol,
                                   price: trade.price,
                                   formattedPrice: String(format: "$%.2f", trade.price),
                                   volume: trade.volume,
                                   timestamp: trade.timestamp,
                                   direction: direction
                               )
                               observer.onNext(item)
                           }
                       }
                       
                       return Disposables.create {
                           task.cancel()
                           Task {
                               _ = try? await service.unsubscribe(from: symbol)
                               service.disconnect()
                           }
                       }
                   }
               }
               .take(until: input.stopStreaming)
               .share()
        
        return Output(
            trade: trade,
            isConnected: isConnected
        )
    }
}
