//
//  SearchStateDiffableModel.swift
//  MarketApp
//
//  Created by Amin faruq on 08/10/26.
//

import Foundation
import IGListKit

public enum SearchStateType: Equatable {
    case prompt(String)
    case empty(String)
    case error(String)
}

public final class SearchStateDiffableModel: NSObject, ListDiffable {
    public let state: SearchStateType
    
    public init(state: SearchStateType) {
        self.state = state
    }
    
    public func diffIdentifier() -> any NSObjectProtocol {
        return "SearchStateDiffableModel" as NSString
    }
    
    public func isEqual(toDiffableObject object: (any ListDiffable)?) -> Bool {
        guard let other = object as? SearchStateDiffableModel else { return false }
        return self.state == other.state
    }
}
