//
//  LiveMarketStreamViewModel.swift
//  MarketApp
//
//  Created by Amin faruq on 08/10/26.
//

import Foundation
import MarketCore
import RxSwift

public final class LiveMarketStreamViewModel {
    private let service: LiveMarketStreamService
    private let symbol: String
    
    public init(service: LiveMarketStreamService, symbol: String) {
        self.service = service
        self.symbol = symbol
    }
}
