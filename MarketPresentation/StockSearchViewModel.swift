//
//  StockSearchViewModel.swift
//  MarketApp
//
//  Created by Amin faruq on 07/10/26.
//

import Foundation
import MarketCore

public final class StockSearchViewModel {
     
    private let loader: StockSearchLoader
    
    public init(loader: StockSearchLoader) {
        self.loader = loader
    }
    
}
