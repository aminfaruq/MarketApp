//
//  MarketNewsDiffableModel.swift
//  MarketApp
//
//  Created by Amin faruq on 08/10/26.
//

import Foundation
import IGListKit
import MarketPresentation

public final class MarketNewsDiffableModel: NSObject, ListDiffable {
    public let viewModel: MarketNewsItemViewModel
    
    public init(viewModel: MarketNewsItemViewModel) {
        self.viewModel = viewModel
    }
    
    public func diffIdentifier() -> any NSObjectProtocol {
        return viewModel.id as NSNumber
    }
    
    public func isEqual(toDiffableObject object: (any ListDiffable)?) -> Bool {
        guard let other = object as? MarketNewsDiffableModel else { return false }
        return self.viewModel == other.viewModel
    }
}
