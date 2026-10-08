//
//  StockDetailScrollNode.swift
//  MarketApp
//
//  Created by Amin faruq on 08/10/26.
//

import AsyncDisplayKit
import MarketPresentation
import UIKit

public final class StockDetailScrollNode: ASScrollNode {
    public let headerNode = StockDetailHeaderNode()
    public let priceNode = StockDetailPriceNode()
    public let metricsNode = StockDetailMetricsNode()
    
    public override init() {
        super.init()
        automaticallyManagesSubnodes = true
        automaticallyManagesContentSize = true
        scrollableDirections = [.up, .down]
        backgroundColor = .systemBackground
    }
    
    public override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let mainStack = ASStackLayoutSpec(
            direction: .vertical,
            spacing: 24,
            justifyContent: .start,
            alignItems: .stretch,
            children: [headerNode, priceNode, metricsNode]
        )
        
        return ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 16, left: 16, bottom: 40, right: 16),
            child: mainStack
        )
    }
}
