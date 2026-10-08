//
//  StockQuoteDiffableModel.swift
//  MarketApp
//
//  Created by Amin faruq on 08/10/26.
//

import Foundation
import IGListKit
import MarketPresentation

public final class StockQuoteDiffableModel: NSObject, ListDiffable {
    public let viewModel: StockQuoteItemViewModel
    
    public init(viewModel: StockQuoteItemViewModel) {
        self.viewModel = viewModel
    }
    
    public func diffIdentifier() -> any NSObjectProtocol {
        return viewModel.symbol as NSString
    }
    
    public func isEqual(toDiffableObject object: (any ListDiffable)?) -> Bool {
        guard let other = object as? StockQuoteDiffableModel else { return false }
        return self.viewModel == other.viewModel
    }
}
