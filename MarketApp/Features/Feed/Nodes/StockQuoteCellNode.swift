//
//  StockQuoteCellNode.swift
//  MarketApp
//
//  Created by Amin faruq on 08/10/26.
//

import AsyncDisplayKit
import MarketPresentation

public final class StockQuoteCellNode: ASCellNode {
    private let symbolNode = ASTextNode()
    private let priceNode = ASTextNode()
    private let changeNode = ASTextNode()
    
    public init(viewModel: StockQuoteItemViewModel) {
        super.init()
        
        automaticallyManagesSubnodes = true
        backgroundColor = .systemBackground
        selectionStyle = .none
        
        configureText(with: viewModel)
    }
    
    private func configureText(with viewModel: StockQuoteItemViewModel) {
        symbolNode.attributedText = NSAttributedString(
            string: viewModel.symbol,
            attributes: [
                .font: UIFont.systemFont(ofSize: 16, weight: .semibold),
                .foregroundColor: UIColor.label
            ]
        )
        
        priceNode.attributedText = NSAttributedString(
            string: viewModel.formattedPrice,
            attributes: [
                .font: UIFont.systemFont(ofSize: 16, weight: .semibold),
                .foregroundColor: UIColor.label
            ]
        )
        
        let changeColor: UIColor = viewModel.isPositive ? .systemGreen : .systemRed
        changeNode.attributedText = NSAttributedString(
            string: viewModel.formattedChange,
            attributes: [
                .font: UIFont.systemFont(ofSize: 13, weight: .medium),
                .foregroundColor: changeColor
            ]
        )
    }
    
    public override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let rightStack = ASStackLayoutSpec(
            direction: .vertical,
            spacing: 4,
            justifyContent: .start,
            alignItems: .end,
            children: [priceNode, changeNode]
        )
        
        let spacer = ASLayoutSpec()
        spacer.style.flexGrow = 1.0
        
        let mainHorizontalStack = ASStackLayoutSpec(
            direction: .horizontal,
            spacing: 8,
            justifyContent: .start,
            alignItems: .center,
            children: [symbolNode, spacer, rightStack]
        )
        
        return ASInsetLayoutSpec(
            insets: UIEdgeInsets(
                top: 14,
                left: 16,
                bottom: 14,
                right: 16
            ),
            child: mainHorizontalStack
        )
    }
}
