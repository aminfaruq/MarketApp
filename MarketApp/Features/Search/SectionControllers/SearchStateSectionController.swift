//
//  SearchStateSectionController.swift
//  MarketApp
//
//  Created by Amin faruq on 08/10/26.
//

import UIKit
import AsyncDisplayKit
import IGListKit

public final class SearchStateSectionController: ListSectionController, ASSectionController {
    private var item: SearchStateDiffableModel?
    
    public override func didUpdate(to object: Any) {
        self.item = object as? SearchStateDiffableModel
    }
    
    public override func numberOfItems() -> Int {
        return 1
    }
    
    @objc(nodeBlockForItemAtIndex:)
    public func nodeBlockForItem(at index: Int) -> ASCellNodeBlock {
        guard let state = item?.state else {
            return { ASCellNode() }
        }
        return {
            SearchStateCellNode(state: state)
        }
    }
    
    @objc(sizeRangeForItemAtIndex:)
    public func sizeRangeForItem(at index: Int) -> ASSizeRange {
        let containerWidth = collectionContext?.containerSize.width ?? 0
        let width = containerWidth > 0 ? containerWidth : UIScreen.main.bounds.width
        return ASSizeRange(
            min: CGSize(width: width, height: 200),
            max: CGSize(width: width, height: .infinity)
        )
    }
    
    public override func cellForItem(at index: Int) -> UICollectionViewCell {
        return ASIGListSectionControllerMethods.cellForItem(at: index, sectionController: self)
    }
    
    public override func sizeForItem(at index: Int) -> CGSize {
        let containerWidth = collectionContext?.containerSize.width ?? 0
        let width = containerWidth > 0 ? containerWidth : UIScreen.main.bounds.width
        return CGSize(width: width, height: 200)
    }
}
