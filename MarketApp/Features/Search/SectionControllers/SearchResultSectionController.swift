//
//  SearchResultSectionController.swift
//  MarketApp
//
//  Created by Amin faruq on 08/10/26.
//

import UIKit
import AsyncDisplayKit
import IGListKit
import MarketPresentation

public final class SearchResultSectionController: ListSectionController, ASSectionController {
    public var onSelect: ((String) -> Void)?
    private var item: SearchResultDiffableModel?
    
    public override func didSelectItem(at index: Int) {
        guard let symbol = item?.viewModel.symbol else { return }
        onSelect?(symbol)
    }
    
    public override func didUpdate(to object: Any) {
        self.item = object as? SearchResultDiffableModel
    }
    
    public override func numberOfItems() -> Int {
        return 1
    }
    
    @objc(nodeBlockForItemAtIndex:)
    public func nodeBlockForItem(at index: Int) -> ASCellNodeBlock {
        guard let viewModel = item?.viewModel else {
            return { ASCellNode() }
        }
        return {
            SearchResultCellNode(viewModel: viewModel)
        }
    }
    
    @objc(sizeRangeForItemAtIndex:)
    public func sizeRangeForItem(at index: Int) -> ASSizeRange {
        let containerWidth = collectionContext?.containerSize.width ?? 0
        let width = containerWidth > 0 ? containerWidth : UIScreen.main.bounds.width
        return ASSizeRange(
            min: CGSize(width: width, height: 60),
            max: CGSize(width: width, height: .infinity)
        )
    }
    
    public override func cellForItem(at index: Int) -> UICollectionViewCell {
        return ASIGListSectionControllerMethods.cellForItem(at: index, sectionController: self)
    }
    
    public override func sizeForItem(at index: Int) -> CGSize {
        let containerWidth = collectionContext?.containerSize.width ?? 0
        let width = containerWidth > 0 ? containerWidth : UIScreen.main.bounds.width
        return CGSize(width: width, height: 60)
    }
}
