//
//  StockQuoteSectionController.swift
//  MarketApp
//
//  Created by Amin faruq on 08/10/26.
//

import AsyncDisplayKit
import IGListKit
import MarketPresentation

public final class StockQuoteSectionController: ListSectionController, ASSectionController {
    
    private var item: StockQuoteDiffableModel?
    
    public override func didUpdate(to object: Any) {
        self.item = object as? StockQuoteDiffableModel
    }
    
    public override func numberOfItems() -> Int {
        return 1
    }
    
    public func nodeBlockForItem(at index: Int) -> ASCellNodeBlock {
        guard let viewModel = item?.viewModel else {
            return { ASCellNode() }
        }
        
        return {
            StockQuoteCellNode(viewModel: viewModel)
        }
    }
    
    public override func cellForItem(at index: Int) -> UICollectionViewCell {
        return collectionContext?.dequeueReusableCell(of: UICollectionViewCell.self, for: self, at: index) ?? UICollectionViewCell()
    }
    
    public override func sizeForItem(at index: Int) -> CGSize {
        return .zero
    }
}
