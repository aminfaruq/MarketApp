//
//  MarketNewsSectionController.swift
//  MarketApp
//
//  Created by Amin faruq on 08/10/26.
//

import AsyncDisplayKit
import IGListKit
import MarketPresentation

public final class MarketNewsSectionController: ListSectionController, ASSectionController {
    
    private var item: MarketNewsDiffableModel?
    
    public override func didUpdate(to object: Any) {
        self.item = object as? MarketNewsDiffableModel
    }
    
    public override func numberOfItems() -> Int {
        return 1
    }
    
    public func nodeBlockForItem(at index: Int) -> ASCellNodeBlock {
        guard let viewModel = item?.viewModel else {
            return { ASCellNode() }
        }
        
        return {
            MarketNewsCellNode(viewModel: viewModel)
        }
    }
    
    public override func cellForItem(at index: Int) -> UICollectionViewCell {
        return ASIGListSectionControllerMethods.cellForItem(at: index, sectionController: self)
    }
    
    public override func sizeForItem(at index: Int) -> CGSize {
        return ASIGListSectionControllerMethods.sizeForItem(at: index)
    }
}
