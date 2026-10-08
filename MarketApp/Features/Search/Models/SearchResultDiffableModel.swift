//
//  SearchResultDiffableModel.swift
//  MarketApp
//
//  Created by Amin faruq on 08/10/26.
//

import Foundation
import IGListKit
import MarketPresentation

public final class SearchResultDiffableModel: NSObject, ListDiffable {
    public let viewModel: SearchResultItemViewModel
    
    public init(viewModel: SearchResultItemViewModel) {
        self.viewModel = viewModel
    }
    
    public func diffIdentifier() -> any NSObjectProtocol {
        return viewModel.symbol as NSString
    }
    
    public func isEqual(toDiffableObject object: (any ListDiffable)?) -> Bool {
        guard let other = object as? SearchResultDiffableModel else { return false }
        return self.viewModel == other.viewModel
    }
}
